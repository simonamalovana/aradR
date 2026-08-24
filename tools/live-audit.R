#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(aradR))

parse_int_env <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) return(as.integer(default))
  out <- suppressWarnings(as.integer(value))
  if (length(out) != 1L || is.na(out) || out < 1L) stop(name, " must be a positive integer")
  out
}

parse_num_env <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) return(as.numeric(default))
  out <- suppressWarnings(as.numeric(value))
  if (length(out) != 1L || is.na(out) || out < 0) stop(name, " must be a non-negative number")
  out
}

parse_csv_env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = default)
  out <- trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
  unique(out[nzchar(out)])
}

api_key <- Sys.getenv("ARAD_API_KEY", unset = "")
if (!nzchar(api_key)) stop("ARAD_API_KEY is required for the live audit")

set_ids <- parse_csv_env("ARADR_AUDIT_SET_IDS", "1058,1032,1115")
base_ids <- parse_csv_env("ARADR_AUDIT_BASE_IDS", "MBOP,SHDPZDR")
if (length(set_ids) + length(base_ids) == 0L) stop("At least one ARAD set or base must be supplied")

snapshot_indicator_ids <- parse_csv_env(
  "ARADR_AUDIT_SNAPSHOT_INDICATOR_IDS",
  "MBOPCAHDPPECY,MBOPCCHDPPECY"
)

sample_per_stratum <- parse_int_env("ARADR_AUDIT_SAMPLE_PER_STRATUM", 1L)
max_per_scope <- parse_int_env("ARADR_AUDIT_MAX_PER_SCOPE", 2L)
max_series <- parse_int_env("ARADR_AUDIT_MAX_SERIES", 10L)
multi_size <- parse_int_env("ARADR_AUDIT_MULTI_SIZE", 3L)
reference_chunk_days <- parse_int_env("ARADR_AUDIT_REFERENCE_CHUNK_DAYS", 730L)
standard_chunk_days <- parse_int_env("ARADR_AUDIT_STANDARD_CHUNK_DAYS", 3650L)
sleep_seconds <- parse_num_env("ARADR_AUDIT_SLEEP_SECONDS", 0.75)
seed <- parse_int_env("ARADR_AUDIT_SEED", 1L)
output_dir <- Sys.getenv("ARADR_AUDIT_OUTPUT_DIR", unset = "audit-results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

cat("aradR live audit\n")
cat("sets:", if (length(set_ids)) paste(set_ids, collapse = ", ") else "none", "\n")
cat("bases:", if (length(base_ids)) paste(base_ids, collapse = ", ") else "none", "\n")
cat("max sampled series per scope:", max_per_scope, "\n")
cat("max sampled single series overall:", max_series, "\n")
cat("standard chunk days:", standard_chunk_days, "\n")
cat("reference chunk days:", reference_chunk_days, "\n")
cat("snapshot smoke indicators:", if (length(snapshot_indicator_ids)) paste(snapshot_indicator_ids, collapse = ", ") else "none", "\n\n")

scope_specs <- rbind(
  if (length(set_ids)) data.frame(scope_type = "set", scope_id = set_ids, stringsAsFactors = FALSE),
  if (length(base_ids)) data.frame(scope_type = "base", scope_id = base_ids, stringsAsFactors = FALSE)
)

scope_call <- function(fun, scope_type, scope_id, ...) {
  args <- list(...)
  if (identical(scope_type, "set")) {
    args$set_id <- scope_id
  } else if (identical(scope_type, "base")) {
    args$base_id <- scope_id
  } else {
    stop("Unsupported audit scope type: ", scope_type)
  }
  do.call(fun, args)
}

plans <- list()
scope_errors <- list()
for (scope_index in seq_len(nrow(scope_specs))) {
  scope_type <- scope_specs$scope_type[[scope_index]]
  scope_id <- scope_specs$scope_id[[scope_index]]
  cat("Discovering", scope_type, scope_id, "...\n")

  metadata <- tryCatch(
    scope_call(
      arad_indicators, scope_type, scope_id,
      api_key = api_key, lang = "en", cache = "none"
    ),
    error = identity
  )
  updates <- tryCatch(
    scope_call(
      arad_updates, scope_type, scope_id,
      api_key = api_key, cache = "none"
    ),
    error = identity
  )

  if (inherits(metadata, "error") || inherits(updates, "error")) {
    scope_errors[[length(scope_errors) + 1L]] <- data.frame(
      scope_type = scope_type,
      scope_id = scope_id,
      error = paste(
        c(
          if (inherits(metadata, "error")) paste0("metadata: ", conditionMessage(metadata)),
          if (inherits(updates, "error")) paste0("updates: ", conditionMessage(updates))
        ),
        collapse = " | "
      ),
      stringsAsFactors = FALSE
    )
    Sys.sleep(sleep_seconds)
    next
  }

  plan_part <- aradR:::arad_audit_sample(
    metadata,
    updates,
    sample_per_stratum = sample_per_stratum,
    max_series = max_per_scope,
    seed = seed + scope_index - 1L
  )
  if (nrow(plan_part) > 0L) {
    plan_part$scope_type <- scope_type
    plan_part$scope_id <- scope_id
    plans[[length(plans) + 1L]] <- plan_part
  } else {
    scope_errors[[length(scope_errors) + 1L]] <- data.frame(
      scope_type = scope_type,
      scope_id = scope_id,
      error = "No auditable series discovered",
      stringsAsFactors = FALSE
    )
  }
  Sys.sleep(sleep_seconds)
}

scope_error_table <- if (length(scope_errors)) {
  do.call(rbind, scope_errors)
} else {
  data.frame(scope_type = character(), scope_id = character(), error = character(), stringsAsFactors = FALSE)
}
write.csv(scope_error_table, file.path(output_dir, "audit-scope-errors.csv"), row.names = FALSE, na = "")

if (length(plans) == 0L) stop("No auditable series were discovered")
plan <- tibble::as_tibble(do.call(rbind, plans))

# If a custom configuration exceeds the global cap, retain scopes in a
# round-robin order rather than allowing a large scope to crowd out the rest.
if (nrow(plan) > max_series) {
  scope_key <- paste(plan$scope_type, plan$scope_id, sep = "::")
  scope_order <- unique(scope_key)
  row_groups <- lapply(scope_order, function(key) which(scope_key == key))
  selected <- integer()
  level <- 1L
  while (length(selected) < max_series) {
    added <- FALSE
    for (rows in row_groups) {
      if (length(rows) >= level && length(selected) < max_series) {
        selected <- c(selected, rows[[level]])
        added <- TRUE
      }
    }
    if (!added) break
    level <- level + 1L
  }
  plan <- plan[selected, , drop = FALSE]
}

write.csv(plan, file.path(output_dir, "audit-plan.csv"), row.names = FALSE, na = "")
coverage <- stats::aggregate(
  plan$indicator_id,
  by = list(
    scope_type = plan$scope_type,
    scope_id = plan$scope_id,
    frequency_code = plan$frequency_code,
    history_band = plan$history_band
  ),
  FUN = length
)
names(coverage)[[ncol(coverage)]] <- "n_series"
write.csv(coverage, file.path(output_dir, "audit-coverage.csv"), row.names = FALSE, na = "")

result_rows <- list()
add_result <- function(test_type, indicator_id, scope_type, scope_id, frequency_code, history_band,
                       method, ok, reason, n_reference = NA_integer_,
                       n_candidate = NA_integer_, na_mismatches = NA_integer_,
                       value_mismatches = NA_integer_, max_abs_diff = NA_real_,
                       error = NA_character_) {
  result_rows[[length(result_rows) + 1L]] <<- data.frame(
    test_type = test_type,
    indicator_id = indicator_id,
    scope_type = scope_type,
    scope_id = scope_id,
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

compare_candidate <- function(test_type, label, scope_type, scope_id, frequency, band, method,
                              reference, candidate_fn) {
  candidate <- tryCatch(candidate_fn(), error = identity)
  if (inherits(candidate, "error")) {
    add_result(
      test_type, label, scope_type, scope_id, frequency, band,
      method, FALSE, "error", error = conditionMessage(candidate)
    )
  } else {
    comparison <- aradR:::arad_compare_data(reference, candidate)
    add_result(
      test_type, label, scope_type, scope_id, frequency, band, method,
      comparison$ok, comparison$reason,
      comparison$n_reference, comparison$n_candidate,
      comparison$na_mismatches, comparison$value_mismatches,
      comparison$max_abs_diff
    )
  }
  Sys.sleep(sleep_seconds)
}

# 1. Stratified single-series tests.
for (i in seq_len(nrow(plan))) {
  row <- plan[i, , drop = FALSE]
  id <- row$indicator_id[[1L]]
  from <- row$data_from[[1L]]
  to <- row$data_to[[1L]]
  scope_type <- row$scope_type[[1L]]
  scope_id <- row$scope_id[[1L]]
  frequency <- row$frequency_code[[1L]]
  band <- row$history_band[[1L]]

  cat(sprintf("[single %d/%d] %s (%s %s; %s, %s)\n", i, nrow(plan), id, scope_type, scope_id, frequency, band))
  reference <- tryCatch(
    arad_get(
      indicator_ids = id, from = from, to = to, strategy = "auto",
      chunk_days = reference_chunk_days, api_key = api_key, cache = "none"
    ),
    error = identity
  )
  if (inherits(reference, "error")) {
    add_result(
      "single", id, scope_type, scope_id, frequency, band,
      "reference", FALSE, "error", error = conditionMessage(reference)
    )
    Sys.sleep(sleep_seconds)
    next
  }

  compare_candidate(
    "single", id, scope_type, scope_id, frequency, band, "standard_chunk", reference,
    function() arad_get(
      indicator_ids = id, from = from, to = to, strategy = "auto",
      chunk_days = standard_chunk_days, api_key = api_key, cache = "none"
    )
  )
  compare_candidate(
    "single", id, scope_type, scope_id, frequency, band, "direct", reference,
    function() arad_get(
      indicator_ids = id, from = from, to = to, strategy = "direct",
      api_key = api_key, cache = "none"
    )
  )
}

# 2. One multi-indicator request, deliberately mixing sampled scopes when their
# available histories overlap.
if (nrow(plan) >= 2L) {
  multi_rows <- plan[seq_len(min(multi_size, nrow(plan))), , drop = FALSE]
  multi_ids <- multi_rows$indicator_id
  multi_from <- max(multi_rows$data_from)
  multi_to <- min(multi_rows$data_to)
  label <- paste(multi_ids, collapse = ",")

  if (multi_from <= multi_to) {
    cat("[multi]", label, "\n")
    reference <- tryCatch(
      arad_get(
        indicator_ids = multi_ids, from = multi_from, to = multi_to, strategy = "auto",
        chunk_days = reference_chunk_days, api_key = api_key, cache = "none"
      ),
      error = identity
    )
    if (inherits(reference, "error")) {
      add_result(
        "multi", label, "multiple", "multiple", "mixed", "overlap",
        "reference", FALSE, "error", error = conditionMessage(reference)
      )
    } else {
      compare_candidate(
        "multi", label, "multiple", "multiple", "mixed", "overlap", "standard_chunk", reference,
        function() arad_get(
          indicator_ids = multi_ids, from = multi_from, to = multi_to, strategy = "auto",
          chunk_days = standard_chunk_days, api_key = api_key, cache = "none"
        )
      )
      compare_candidate(
        "multi", label, "multiple", "multiple", "mixed", "overlap", "direct", reference,
        function() arad_get(
          indicator_ids = multi_ids, from = multi_from, to = multi_to, strategy = "direct",
          api_key = api_key, cache = "none"
        )
      )
    }
  }
}

# 3. Snapshot-backed tests. Defaults are annual MBOP indicators that have been
# observed with monetary-policy-report snapshots; users can override the list.
for (id in snapshot_indicator_ids) {
  cat("[snapshot]", id, "\n")
  updates <- tryCatch(
    arad_updates(indicator_ids = id, snapshot_ids = "ALL", api_key = api_key, cache = "none"),
    error = identity
  )
  if (inherits(updates, "error") || nrow(updates) == 0L) {
    message <- if (inherits(updates, "error")) conditionMessage(updates) else "No snapshot update metadata returned"
    add_result(
      "snapshot", id, "indicator", id, "unknown", "all",
      "reference", FALSE, "error", error = message
    )
    next
  }

  from_candidates <- updates$data_from[!is.na(updates$data_from)]
  to_candidates <- updates$data_to[!is.na(updates$data_to)]
  if (length(from_candidates) == 0L || length(to_candidates) == 0L) {
    add_result(
      "snapshot", id, "indicator", id, "unknown", "all",
      "reference", FALSE, "error", error = "No usable snapshot boundaries"
    )
    next
  }

  from <- min(from_candidates)
  to <- max(to_candidates)
  reference <- tryCatch(
    arad_get(
      indicator_ids = id, from = from, to = to, snapshot_ids = "ALL", strategy = "auto",
      chunk_days = reference_chunk_days, api_key = api_key, cache = "none"
    ),
    error = identity
  )
  if (inherits(reference, "error")) {
    add_result(
      "snapshot", id, "indicator", id, "unknown", "all",
      "reference", FALSE, "error", error = conditionMessage(reference)
    )
    next
  }

  compare_candidate(
    "snapshot", id, "indicator", id, "unknown", "all", "standard_chunk", reference,
    function() arad_get(
      indicator_ids = id, from = from, to = to, snapshot_ids = "ALL", strategy = "auto",
      chunk_days = standard_chunk_days, api_key = api_key, cache = "none"
    )
  )
  compare_candidate(
    "snapshot", id, "indicator", id, "unknown", "all", "direct", reference,
    function() arad_get(
      indicator_ids = id, from = from, to = to, snapshot_ids = "ALL", strategy = "direct",
      api_key = api_key, cache = "none"
    )
  )
}

if (length(result_rows) == 0L) stop("Live audit produced no comparison results")
results <- do.call(rbind, result_rows)
write.csv(results, file.path(output_dir, "audit-results.csv"), row.names = FALSE, na = "")
saveRDS(results, file.path(output_dir, "audit-results.rds"))

standard <- results[results$method == "standard_chunk", , drop = FALSE]
direct <- results[results$method == "direct", , drop = FALSE]
reference_errors <- results[results$method == "reference" & !results$ok, , drop = FALSE]
snapshot_standard <- standard[standard$test_type == "snapshot", , drop = FALSE]

cat("\nAudit summary\n")
cat("sampled single series:", nrow(plan), "\n")
cat("covered scopes:", length(unique(paste(plan$scope_type, plan$scope_id))), "\n")
cat("covered frequencies:", paste(sort(unique(plan$frequency_code)), collapse = ", "), "\n")
cat("covered history bands:", paste(sort(unique(plan$history_band)), collapse = ", "), "\n")
cat("standard chunk mismatches/errors:", sum(!standard$ok), "of", nrow(standard), "\n")
cat("direct mismatches/errors:", sum(!direct$ok), "of", nrow(direct), "\n")
cat("reference/setup errors:", nrow(reference_errors), "\n")
cat("snapshot standard comparisons:", nrow(snapshot_standard), "\n")
cat("scope discovery errors:", nrow(scope_error_table), "\n")
cat("Results written to", output_dir, "\n")

# A green audit means the reference itself was valid and the bounded strategy
# matched it. Direct failures remain diagnostic because they may be the exact
# server-side long-range problem under investigation.
if (nrow(scope_error_table) > 0L) {
  stop("One or more configured audit scopes could not be discovered; inspect audit-scope-errors.csv")
}
if (nrow(reference_errors) > 0L) {
  stop("One or more fine-reference/setup runs failed; inspect audit-results.csv")
}
if (nrow(standard) == 0L) {
  stop("Live audit completed no standard-chunk comparisons")
}
if (any(!standard$ok)) {
  stop("Standard aradR chunking differed from the fine-chunk reference; inspect audit-results.csv")
}
if (length(snapshot_indicator_ids) > 0L && nrow(snapshot_standard) == 0L) {
  stop("Configured snapshot coverage produced no valid standard-chunk comparison")
}
