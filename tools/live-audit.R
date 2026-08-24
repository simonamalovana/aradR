#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(aradR))

parse_int_env <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) return(as.integer(default))
  out <- suppressWarnings(as.integer(value))
  if (is.na(out) || out < 1L) stop(name, " must be a positive integer")
  out
}

parse_num_env <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) return(as.numeric(default))
  out <- suppressWarnings(as.numeric(value))
  if (is.na(out) || out < 0) stop(name, " must be a non-negative number")
  out
}

api_key <- Sys.getenv("ARAD_API_KEY", unset = "")
if (!nzchar(api_key)) {
  stop("ARAD_API_KEY is required for the live audit")
}

set_ids <- trimws(strsplit(Sys.getenv("ARADR_AUDIT_SET_IDS", unset = "1058"), ",", fixed = TRUE)[[1]])
set_ids <- set_ids[nzchar(set_ids)]
if (length(set_ids) == 0L) stop("No ARAD set IDs supplied")

sample_per_stratum <- parse_int_env("ARADR_AUDIT_SAMPLE_PER_STRATUM", 2L)
max_series <- parse_int_env("ARADR_AUDIT_MAX_SERIES", 12L)
reference_chunk_days <- parse_int_env("ARADR_AUDIT_REFERENCE_CHUNK_DAYS", 730L)
standard_chunk_days <- parse_int_env("ARADR_AUDIT_STANDARD_CHUNK_DAYS", 3650L)
sleep_seconds <- parse_num_env("ARADR_AUDIT_SLEEP_SECONDS", 0.75)
seed <- parse_int_env("ARADR_AUDIT_SEED", 1L)
output_dir <- Sys.getenv("ARADR_AUDIT_OUTPUT_DIR", unset = "audit-results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

cat("aradR live audit\n")
cat("sets:", paste(set_ids, collapse = ", "), "\n")
cat("max series:", max_series, "\n")
cat("standard chunk days:", standard_chunk_days, "\n")
cat("reference chunk days:", reference_chunk_days, "\n\n")

plans <- list()
for (set_id in set_ids) {
  cat("Discovering set", set_id, "...\n")
  metadata <- arad_indicators(set_id = set_id, api_key = api_key, lang = "en", cache = "none")
  updates <- arad_updates(set_id = set_id, api_key = api_key, cache = "none")
  plan <- aradR:::arad_audit_sample(
    metadata,
    updates,
    sample_per_stratum = sample_per_stratum,
    max_series = max_series,
    seed = seed
  )
  if (nrow(plan) > 0L) {
    plan$set_id <- as.character(set_id)
    plans[[length(plans) + 1L]] <- plan
  }
  Sys.sleep(sleep_seconds)
}

if (length(plans) == 0L) stop("No auditable series were discovered")
plan <- tibble::as_tibble(do.call(rbind, plans))
if (nrow(plan) > max_series) {
  set.seed(seed)
  plan <- plan[sample(seq_len(nrow(plan)), max_series), , drop = FALSE]
}
write.csv(plan, file.path(output_dir, "audit-plan.csv"), row.names = FALSE, na = "")

result_rows <- list()
add_result <- function(indicator_id, set_id, frequency_code, history_band,
                       method, ok, reason, n_reference = NA_integer_,
                       n_candidate = NA_integer_, na_mismatches = NA_integer_,
                       value_mismatches = NA_integer_, max_abs_diff = NA_real_,
                       error = NA_character_) {
  result_rows[[length(result_rows) + 1L]] <<- data.frame(
    indicator_id = indicator_id,
    set_id = set_id,
    frequency_code = frequency_code,
    history_band = history_band,
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

for (i in seq_len(nrow(plan))) {
  row <- plan[i, , drop = FALSE]
  id <- row$indicator_id[[1L]]
  from <- row$data_from[[1L]]
  to <- row$data_to[[1L]]
  set_id <- row$set_id[[1L]]
  frequency <- row$frequency_code[[1L]]
  band <- row$history_band[[1L]]

  cat(sprintf("[%d/%d] %s (%s, %s)\n", i, nrow(plan), id, frequency, band))

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
    add_result(id, set_id, frequency, band, "reference", FALSE, "error", error = conditionMessage(reference))
    Sys.sleep(sleep_seconds)
    next
  }

  candidates <- list(
    standard_chunk = function() arad_get(
      indicator_ids = id, from = from, to = to, strategy = "auto",
      chunk_days = standard_chunk_days, api_key = api_key, cache = "none"
    ),
    direct = function() arad_get(
      indicator_ids = id, from = from, to = to, strategy = "direct",
      api_key = api_key, cache = "none"
    )
  )

  for (method in names(candidates)) {
    candidate <- tryCatch(candidates[[method]](), error = identity)
    if (inherits(candidate, "error")) {
      add_result(id, set_id, frequency, band, method, FALSE, "error", error = conditionMessage(candidate))
    } else {
      comparison <- aradR:::arad_compare_data(reference, candidate)
      add_result(
        id, set_id, frequency, band, method,
        comparison$ok, comparison$reason,
        comparison$n_reference, comparison$n_candidate,
        comparison$na_mismatches, comparison$value_mismatches,
        comparison$max_abs_diff
      )
    }
    Sys.sleep(sleep_seconds)
  }
}

results <- do.call(rbind, result_rows)
write.csv(results, file.path(output_dir, "audit-results.csv"), row.names = FALSE, na = "")
saveRDS(results, file.path(output_dir, "audit-results.rds"))

standard <- results[results$method == "standard_chunk", , drop = FALSE]
direct <- results[results$method == "direct", , drop = FALSE]

cat("\nAudit summary\n")
cat("standard chunk mismatches/errors:", sum(!standard$ok), "of", nrow(standard), "\n")
cat("direct mismatches/errors:", sum(!direct$ok), "of", nrow(direct), "\n")
cat("Results written to", output_dir, "\n")

# The reliability strategy itself is considered unsafe if the standard bounded
# retrieval differs from the finer reference. Direct failures are reported but
# do not make the audit fail because they may be exactly the server-side issue
# this audit is designed to discover.
if (nrow(standard) > 0L && any(!standard$ok)) {
  stop("Standard aradR chunking differed from the fine-chunk reference; inspect audit artifacts")
}
