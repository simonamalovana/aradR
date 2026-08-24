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
  if (is.na(out) || out < 1L) stop(name, " must be a positive integer")
  out
}

api_key <- Sys.getenv("ARAD_API_KEY", unset = "")
if (!nzchar(api_key)) stop("ARAD_API_KEY is required")

ids <- parse_csv_env("ARADR_DIAG_IDS", "SMV5M602,SMV5M104")
chunk_days <- parse_int_env("ARADR_DIAG_CHUNK_DAYS", 730L)
output_dir <- Sys.getenv("ARADR_AUDIT_OUTPUT_DIR", unset = "audit-results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_raw_table <- function(raw) {
  payload <- raw
  attributes(payload) <- NULL
  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)
  writeBin(payload, file)
  suppressWarnings(
    readr::read_delim(
      file,
      delim = ";",
      locale = readr::locale(encoding = "windows-1250"),
      col_types = readr::cols(.default = readr::col_character()),
      na = c("", "NA", "NULL"),
      trim_ws = TRUE,
      progress = FALSE,
      show_col_types = FALSE
    )
  )
}

all_rows <- list()
request_errors <- list()

for (id in ids) {
  updates <- tryCatch(
    arad_updates(indicator_ids = id, api_key = api_key, cache = "none"),
    error = identity
  )
  if (inherits(updates, "error") || nrow(updates) == 0L) {
    request_errors[[length(request_errors) + 1L]] <- data.frame(
      requested_id = id,
      chunk_from = NA_character_,
      chunk_to = NA_character_,
      error = if (inherits(updates, "error")) conditionMessage(updates) else "No update metadata",
      stringsAsFactors = FALSE
    )
    next
  }

  from_candidates <- updates$data_from[!is.na(updates$data_from)]
  to_candidates <- updates$data_to[!is.na(updates$data_to)]
  if (!length(from_candidates) || !length(to_candidates)) next

  chunks <- aradR:::arad_make_chunks(min(from_candidates), max(to_candidates), chunk_days)
  selector <- aradR:::arad_selector(indicator_ids = id)
  base_query <- c(
    aradR:::arad_selector_query(selector),
    list(delimiter = "semicolon", decimal_separator = "point", period_sort = "asc")
  )

  for (chunk in chunks) {
    query <- base_query
    query$period_from <- aradR:::arad_date_param(chunk$from)
    query$period_to <- aradR:::arad_date_param(chunk$to)

    raw <- tryCatch(
      aradR:::arad_request("data", query = query, api_key = api_key, cache = "none"),
      error = identity
    )
    if (inherits(raw, "error")) {
      request_errors[[length(request_errors) + 1L]] <- data.frame(
        requested_id = id,
        chunk_from = format(chunk$from),
        chunk_to = format(chunk$to),
        error = conditionMessage(raw),
        stringsAsFactors = FALSE
      )
      next
    }

    tab <- read_raw_table(raw)
    required <- c("indicator_id", "snapshot_id", "period", "value")
    if (!all(required %in% names(tab))) next

    tab <- as.data.frame(tab[, required, drop = FALSE], stringsAsFactors = FALSE)
    tab$requested_id <- id
    tab$chunk_from <- format(chunk$from)
    tab$chunk_to <- format(chunk$to)
    all_rows[[length(all_rows) + 1L]] <- tab
  }
}

if (length(all_rows)) {
  raw_rows <- do.call(rbind, all_rows)
  snapshot_key <- ifelse(is.na(raw_rows$snapshot_id), "<NA>", raw_rows$snapshot_id)
  key <- paste(raw_rows$requested_id, raw_rows$indicator_id, snapshot_key, raw_rows$period, sep = "\r")
  dup <- duplicated(key) | duplicated(key, fromLast = TRUE)

  diagnostics <- list()
  if (any(dup)) {
    dup_rows <- raw_rows[dup, , drop = FALSE]
    dup_snapshot <- ifelse(is.na(dup_rows$snapshot_id), "<NA>", dup_rows$snapshot_id)
    dup_key <- paste(dup_rows$requested_id, dup_rows$indicator_id, dup_snapshot, dup_rows$period, sep = "\r")

    for (k in unique(dup_key)) {
      group <- dup_rows[dup_key == k, , drop = FALSE]
      values <- ifelse(is.na(group$value), "<NA>", group$value)
      chunk_labels <- paste(group$chunk_from, group$chunk_to, sep = "..")
      diagnostics[[length(diagnostics) + 1L]] <- data.frame(
        requested_id = group$requested_id[[1L]],
        indicator_id = group$indicator_id[[1L]],
        snapshot_id = ifelse(is.na(group$snapshot_id[[1L]]), "<NA>", group$snapshot_id[[1L]]),
        period = group$period[[1L]],
        n_rows = nrow(group),
        n_chunks = length(unique(chunk_labels)),
        n_distinct_values = length(unique(values)),
        values = paste(unique(values), collapse = " | "),
        chunks = paste(unique(chunk_labels), collapse = " | "),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(diagnostics)) {
    duplicates <- do.call(rbind, diagnostics)
  } else {
    duplicates <- data.frame(
      requested_id = character(), indicator_id = character(), snapshot_id = character(),
      period = character(), n_rows = integer(), n_chunks = integer(),
      n_distinct_values = integer(), values = character(), chunks = character(),
      stringsAsFactors = FALSE
    )
  }
} else {
  duplicates <- data.frame(
    requested_id = character(), indicator_id = character(), snapshot_id = character(),
    period = character(), n_rows = integer(), n_chunks = integer(),
    n_distinct_values = integer(), values = character(), chunks = character(),
    stringsAsFactors = FALSE
  )
}

write.csv(duplicates, file.path(output_dir, "duplicate-diagnostics.csv"), row.names = FALSE, na = "")

if (length(request_errors)) {
  errors <- do.call(rbind, request_errors)
} else {
  errors <- data.frame(requested_id = character(), chunk_from = character(), chunk_to = character(), error = character())
}
write.csv(errors, file.path(output_dir, "duplicate-diagnostic-errors.csv"), row.names = FALSE, na = "")

cat("Cross-chunk duplicate diagnostic groups:", nrow(duplicates), "\n")
if (nrow(duplicates)) {
  cat("Groups spanning multiple chunks:", sum(duplicates$n_chunks > 1L), "\n")
  cat("Groups with differing values:", sum(duplicates$n_distinct_values > 1L), "\n")
}
cat("Diagnostic request errors:", nrow(errors), "\n")
