#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(aradR))

parse_csv_env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = default)
  out <- trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
  unique(out[nzchar(out)])
}

parse_int_env <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) return(as.integer(default))
  out <- suppressWarnings(as.integer(value))
  if (length(out) != 1L || is.na(out) || out < 1L) {
    stop(name, " must be a positive integer")
  }
  out
}

parse_num_env <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) return(as.numeric(default))
  out <- suppressWarnings(as.numeric(value))
  if (length(out) != 1L || is.na(out) || out < 0) {
    stop(name, " must be a non-negative number")
  }
  out
}

api_key <- Sys.getenv("ARAD_API_KEY", unset = "")
if (!nzchar(api_key)) stop("ARAD_API_KEY is required for the final coverage audit")

target_ids <- parse_csv_env(
  "ARADR_FINAL_TARGET_INDICATORS",
  "MIRFMDF12ERATPECD"
)
if (length(target_ids) == 0L) stop("At least one target indicator is required")

standard_chunk_days <- parse_int_env("ARADR_AUDIT_STANDARD_CHUNK_DAYS", 3650L)
reference_chunk_days <- parse_int_env("ARADR_FINAL_REFERENCE_CHUNK_DAYS", 365L)
short_window_days <- parse_int_env("ARADR_FINAL_SHORT_WINDOW_DAYS", 365L * 3L)
medium_window_days <- parse_int_env("ARADR_FINAL_MEDIUM_WINDOW_DAYS", 365L * 10L)
sleep_seconds <- parse_num_env("ARADR_AUDIT_SLEEP_SECONDS", 0.75)
output_dir <- Sys.getenv("ARADR_AUDIT_OUTPUT_DIR", unset = "audit-results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

higher_frequency <- function(code) {
  !is.na(code) && nzchar(code) && !(toupper(code) %in% c("M", "Q", "Y", "A"))
}

source_history_band <- function(from, to) {
  days <- as.numeric(to - from)
  if (days < 365 * 5) return("short")
  if (days < 365 * 15) return("medium")
  "long"
}

window_from <- function(full_from, full_to, width_days) {
  max(full_from, full_to - as.integer(width_days - 1L))
}

result_rows <- list()
metadata_rows <- list()

add_result <- function(indicator_id, frequency_code, source_band, request_band,
                       request_from, request_to, method, ok, reason,
                       n_reference = NA_integer_, n_candidate = NA_integer_,
                       na_mismatches = NA_integer_, value_mismatches = NA_integer_,
                       max_abs_diff = NA_real_, error = NA_character_) {
  result_rows[[length(result_rows) + 1L]] <<- data.frame(
    indicator_id = indicator_id,
    frequency_code = frequency_code,
    source_history_band = source_band,
    request_band = request_band,
    request_from = as.character(request_from),
    request_to = as.character(request_to),
    method = method,
    ok = ok,
    reason = reason,
    n_reference = n_reference,
    n_candidate = n_candidate,
    na_mismatches = na_mismatches,
    value_mismatches = value_mismatches,
    max_abs_diff = max_abs_diff,
    error = error,
    stringsAsFactors = FALSE
  )
}

compare_candidate <- function(id, frequency, source_band, request_band,
                              from, to, method, reference, candidate_fn) {
  candidate <- tryCatch(candidate_fn(), error = identity)
  if (inherits(candidate, "error")) {
    add_result(
      id, frequency, source_band, request_band, from, to,
      method, FALSE, "error", error = conditionMessage(candidate)
    )
  } else {
    comparison <- aradR:::arad_compare_data(reference, candidate)
    add_result(
      id, frequency, source_band, request_band, from, to,
      method, comparison$ok, comparison$reason,
      comparison$n_reference, comparison$n_candidate,
      comparison$na_mismatches, comparison$value_mismatches,
      comparison$max_abs_diff
    )
  }
  Sys.sleep(sleep_seconds)
}

cat("aradR final coverage audit\n")
cat("target indicators:", paste(target_ids, collapse = ", "), "\n")
cat("standard chunk days:", standard_chunk_days, "\n")
cat("higher-frequency reference chunk days:", reference_chunk_days, "\n\n")

for (id in target_ids) {
  cat("[target]", id, "\n")
  metadata <- tryCatch(
    arad_indicators(indicator_ids = id, lang = "en", api_key = api_key, cache = "none"),
    error = identity
  )
  updates <- tryCatch(
    arad_updates(indicator_ids = id, api_key = api_key, cache = "none"),
    error = identity
  )

  if (inherits(metadata, "error") || inherits(updates, "error") ||
      nrow(metadata) == 0L || nrow(updates) == 0L) {
    message <- paste(
      c(
        if (inherits(metadata, "error")) paste0("metadata: ", conditionMessage(metadata)),
        if (!inherits(metadata, "error") && nrow(metadata) == 0L) "metadata: no rows",
        if (inherits(updates, "error")) paste0("updates: ", conditionMessage(updates)),
        if (!inherits(updates, "error") && nrow(updates) == 0L) "updates: no rows"
      ),
      collapse = " | "
    )
    add_result(id, NA_character_, NA_character_, "setup", NA, NA,
               "reference", FALSE, "error", error = message)
    next
  }

  frequency <- metadata$frequency_code[[1L]]
  if (!higher_frequency(frequency)) {
    add_result(
      id, frequency, NA_character_, "setup", NA, NA,
      "reference", FALSE, "error",
      error = paste0("Target is not higher-frequency; frequency_code=", frequency)
    )
    next
  }

  current_updates <- updates[is.na(updates$snapshot_id), , drop = FALSE]
  if (nrow(current_updates) == 0L) current_updates <- updates
  from_candidates <- current_updates$data_from[!is.na(current_updates$data_from)]
  to_candidates <- current_updates$data_to[!is.na(current_updates$data_to)]
  if (length(from_candidates) == 0L || length(to_candidates) == 0L) {
    add_result(
      id, frequency, NA_character_, "setup", NA, NA,
      "reference", FALSE, "error", error = "No usable current data boundaries"
    )
    next
  }

  full_from <- min(from_candidates)
  full_to <- max(to_candidates)
  source_band <- source_history_band(full_from, full_to)
  metadata_rows[[length(metadata_rows) + 1L]] <- data.frame(
    indicator_id = id,
    indicator_name = metadata$indicator_name[[1L]],
    frequency_code = frequency,
    frequency_name = metadata$frequency_name[[1L]],
    data_from = as.character(full_from),
    data_to = as.character(full_to),
    source_history_band = source_band,
    stringsAsFactors = FALSE
  )

  windows <- list(
    full = c(full_from, full_to),
    short = c(window_from(full_from, full_to, short_window_days), full_to),
    medium = c(window_from(full_from, full_to, medium_window_days), full_to)
  )

  for (request_band in names(windows)) {
    from <- as.Date(windows[[request_band]][[1L]], origin = "1970-01-01")
    to <- as.Date(windows[[request_band]][[2L]], origin = "1970-01-01")
    cat(sprintf("  [%s] %s to %s\n", request_band, from, to))

    reference <- tryCatch(
      arad_get(
        indicator_ids = id,
        from = from,
        to = to,
        strategy = "auto",
        chunk_days = reference_chunk_days,
        api_key = api_key,
        cache = "none"
      ),
      error = identity
    )

    if (inherits(reference, "error")) {
      add_result(
        id, frequency, source_band, request_band, from, to,
        "reference", FALSE, "error", error = conditionMessage(reference)
      )
      Sys.sleep(sleep_seconds)
      next
    }

    compare_candidate(
      id, frequency, source_band, request_band, from, to,
      "standard_chunk", reference,
      function() arad_get(
        indicator_ids = id,
        from = from,
        to = to,
        strategy = "auto",
        chunk_days = standard_chunk_days,
        api_key = api_key,
        cache = "none"
      )
    )
    compare_candidate(
      id, frequency, source_band, request_band, from, to,
      "direct", reference,
      function() arad_get(
        indicator_ids = id,
        from = from,
        to = to,
        strategy = "direct",
        api_key = api_key,
        cache = "none"
      )
    )
  }
}

results <- if (length(result_rows)) do.call(rbind, result_rows) else data.frame()
metadata_out <- if (length(metadata_rows)) do.call(rbind, metadata_rows) else data.frame()
write.csv(results, file.path(output_dir, "final-coverage-results.csv"), row.names = FALSE, na = "")
write.csv(metadata_out, file.path(output_dir, "final-coverage-targets.csv"), row.names = FALSE, na = "")

if (nrow(results) == 0L) stop("No final coverage comparisons were produced")
reference_errors <- results[results$method == "reference" & !results$ok, , drop = FALSE]
standard <- results[results$method == "standard_chunk", , drop = FALSE]
direct <- results[results$method == "direct", , drop = FALSE]

cat("\nFinal coverage summary\n")
cat("higher-frequency targets validated:", nrow(metadata_out), "\n")
cat("standard chunk mismatches/errors:", sum(!standard$ok), "of", nrow(standard), "\n")
cat("direct mismatches/errors:", sum(!direct$ok), "of", nrow(direct), "\n")
cat("reference/setup errors:", nrow(reference_errors), "\n")

required_bands <- c("full", "short", "medium")
covered_bands <- unique(standard$request_band[standard$ok])
if (nrow(metadata_out) == 0L) {
  stop("No higher-frequency target was validated")
}
if (nrow(reference_errors) > 0L) {
  stop("Final coverage reference/setup errors occurred; inspect final-coverage-results.csv")
}
if (!all(required_bands %in% covered_bands)) {
  stop("Final coverage did not successfully test full, short and medium request windows")
}
if (nrow(standard) == 0L || any(!standard$ok)) {
  stop("Default aradR chunking differed from the fine reference in final coverage audit")
}

# Direct-request failures remain diagnostic. They may reproduce the historical
# server-side long-range issue that motivated reliability-first chunking.
