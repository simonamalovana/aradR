#' Reshape ARAD data to wide format
#'
#' Converts the long-format output of [arad_get()] into one row per period and
#' one column per series. Snapshot identifiers are incorporated into column
#' names automatically when they are needed to distinguish multiple snapshot
#' contexts for the same indicator.
#'
#' @param data A data frame with `indicator_id`, `period`, and `value` columns,
#'   typically returned by [arad_get()].
#' @param snapshot How snapshot identifiers should affect column names:
#'   `"auto"` adds them only when an indicator has multiple snapshot contexts,
#'   `"include"` always adds them, and `"ignore"` never adds them.
#' @param names_sep Separator used between indicator and snapshot identifiers.
#'
#' @return A tibble with one `period` column and one numeric column per series.
#'   The `arad_diagnostics` attribute is preserved when present on `data`.
#' @export
arad_wide <- function(data,
                      snapshot = c("auto", "include", "ignore"),
                      names_sep = "__") {
  snapshot <- match.arg(snapshot)

  if (!is.data.frame(data)) {
    arad_abort("`data` must be a data frame.", "arad_input_error")
  }

  required <- c("indicator_id", "period", "value")
  missing_columns <- setdiff(required, names(data))
  if (length(missing_columns) > 0L) {
    arad_abort(
      sprintf(
        "`data` is missing required column(s): %s.",
        paste(missing_columns, collapse = ", ")
      ),
      "arad_input_error"
    )
  }

  if (!inherits(data$period, "Date") || anyNA(data$period)) {
    arad_abort("`data$period` must contain non-missing Date values.", "arad_input_error")
  }
  if (!is.numeric(data$value)) {
    arad_abort("`data$value` must be numeric.", "arad_input_error")
  }
  if (length(names_sep) != 1L || is.na(names_sep) || !nzchar(names_sep)) {
    arad_abort("`names_sep` must be a non-empty scalar string.", "arad_input_error")
  }

  indicator_id <- trimws(as.character(data$indicator_id))
  if (anyNA(indicator_id) || any(!nzchar(indicator_id))) {
    arad_abort("`data$indicator_id` must contain non-empty values.", "arad_input_error")
  }

  diagnostics <- attr(data, "arad_diagnostics", exact = TRUE)

  if (nrow(data) == 0L) {
    out <- tibble::tibble(period = data$period)
    if (!is.null(diagnostics)) attr(out, "arad_diagnostics") <- diagnostics
    return(out)
  }

  has_snapshot <- "snapshot_id" %in% names(data)
  if (identical(snapshot, "include") && !has_snapshot) {
    arad_abort(
      "`snapshot = \"include\"` requires a `snapshot_id` column.",
      "arad_input_error"
    )
  }

  snapshot_id <- if (has_snapshot) {
    raw_snapshot <- trimws(as.character(data$snapshot_id))
    ifelse(is.na(raw_snapshot) | !nzchar(raw_snapshot), "current", raw_snapshot)
  } else {
    rep("current", nrow(data))
  }

  use_snapshot <- identical(snapshot, "include")
  if (identical(snapshot, "auto") && has_snapshot) {
    contexts <- split(snapshot_id, indicator_id)
    use_snapshot <- any(vapply(
      contexts,
      function(x) length(unique(x)) > 1L,
      logical(1)
    ))
  }

  series_id <- if (use_snapshot) {
    paste(indicator_id, snapshot_id, sep = names_sep)
  } else {
    indicator_id
  }

  observation_key <- paste(format(data$period, "%Y-%m-%d"), series_id, sep = "\r")
  if (anyDuplicated(observation_key)) {
    arad_abort(
      paste0(
        "Cannot reshape to wide format because more than one observation maps ",
        "to the same period/series cell. Use snapshot-aware names or inspect ",
        "the input for duplicate observations."
      ),
      "arad_integrity_error"
    )
  }

  periods <- sort(unique(data$period))
  if (use_snapshot) {
    keep <- !duplicated(series_id)
    series_order <- order(
      indicator_id[keep],
      snapshot_id[keep] != "current",
      snapshot_id[keep]
    )
    series_names <- series_id[keep][series_order]
  } else {
    series_names <- sort(unique(series_id))
  }
  out <- tibble::tibble(period = periods)

  for (series_name in series_names) {
    rows <- which(series_id == series_name)
    positions <- match(periods, data$period[rows])
    values <- rep(NA_real_, length(periods))
    matched <- !is.na(positions)
    values[matched] <- data$value[rows][positions[matched]]
    out[[series_name]] <- values
  }

  if (!is.null(diagnostics)) attr(out, "arad_diagnostics") <- diagnostics
  out
}
