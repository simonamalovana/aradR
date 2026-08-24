arad_read_character_table <- function(raw,
                                      endpoint,
                                      expected_columns,
                                      encoding = "windows-1250") {
  if (!is.raw(raw)) {
    arad_abort("Internal ARAD response must be raw bytes.", "arad_parse_error")
  }

  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)
  writeBin(raw, file)

  table <- tryCatch(
    suppressWarnings(
      readr::read_delim(
        file,
        delim = ";",
        locale = readr::locale(encoding = encoding),
        col_types = readr::cols(.default = readr::col_character()),
        na = c("", "NA", "NULL"),
        trim_ws = TRUE,
        progress = FALSE,
        show_col_types = FALSE
      )
    ),
    error = function(e) {
      arad_abort(
        sprintf("Could not read the ARAD `/%s` response as a semicolon-delimited table.", endpoint),
        "arad_parse_error"
      )
    }
  )

  problems <- readr::problems(table)
  if (nrow(problems) > 0L) {
    arad_abort(
      sprintf("ARAD `/%s` response contains structural parsing problems.", endpoint),
      "arad_parse_error"
    )
  }

  missing_columns <- setdiff(expected_columns, names(table))
  if (length(missing_columns) > 0L) {
    arad_abort(
      sprintf(
        "ARAD `/%s` response is missing required column(s): %s.",
        endpoint,
        paste(missing_columns, collapse = ", ")
      ),
      "arad_parse_error"
    )
  }

  table
}

arad_parse_date_column <- function(x, column, allow_missing = FALSE) {
  parsed <- as.Date(x, format = "%Y%m%d")
  invalid <- !is.na(x) & is.na(parsed)
  if (any(invalid)) {
    arad_abort(
      sprintf("ARAD returned invalid YYYYMMDD values in `%s`.", column),
      "arad_parse_error"
    )
  }
  if (!allow_missing && anyNA(parsed)) {
    arad_abort(sprintf("ARAD returned missing values in required `%s`.", column), "arad_parse_error")
  }
  parsed
}

arad_parse_datetime_column <- function(x, column, allow_missing = TRUE) {
  parsed <- as.POSIXct(x, format = "%Y%m%d%H%M%S", tz = "UTC")
  invalid <- !is.na(x) & is.na(parsed)
  if (any(invalid)) {
    arad_abort(
      sprintf("ARAD returned invalid YYYYMMDDHHMISS values in `%s`.", column),
      "arad_parse_error"
    )
  }
  if (!allow_missing && anyNA(parsed)) {
    arad_abort(sprintf("ARAD returned missing values in required `%s`.", column), "arad_parse_error")
  }
  parsed
}

arad_validate_data_keys <- function(data) {
  snapshot_key <- ifelse(is.na(data$snapshot_id), "<NA>", data$snapshot_id)
  key <- paste(data$indicator_id, snapshot_key, format(data$period, "%Y%m%d"), sep = "\r")
  if (anyDuplicated(key)) {
    arad_abort(
      "ARAD response contains duplicate indicator/snapshot/period observations.",
      "arad_integrity_error"
    )
  }
  invisible(data)
}

arad_sort_data <- function(data) {
  if (nrow(data) == 0L) {
    return(data)
  }
  order_index <- order(data$indicator_id, data$snapshot_id, data$period, na.last = TRUE)
  data[order_index, , drop = FALSE]
}

arad_parse_data_response <- function(raw, encoding = "windows-1250") {
  table <- arad_read_character_table(
    raw,
    endpoint = "data",
    expected_columns = c("indicator_id", "snapshot_id", "period", "value"),
    encoding = encoding
  )

  if (nrow(table) == 0L) {
    return(arad_empty_data())
  }

  if (anyNA(table$indicator_id) || any(!nzchar(trimws(table$indicator_id)))) {
    arad_abort("ARAD returned a missing or empty `indicator_id`.", "arad_integrity_error")
  }

  period <- arad_parse_date_column(table$period, "period", allow_missing = FALSE)

  value <- suppressWarnings(
    readr::parse_double(
      table$value,
      locale = readr::locale(decimal_mark = "."),
      na = c("", "NA", "NULL")
    )
  )
  bad_numeric <- !is.na(table$value) & is.na(value)
  if (any(bad_numeric)) {
    arad_abort(
      "ARAD returned non-missing `value` fields that could not be parsed as numbers.",
      "arad_parse_error"
    )
  }

  data <- tibble::tibble(
    indicator_id = trimws(table$indicator_id),
    snapshot_id = table$snapshot_id,
    period = period,
    value = value
  )

  arad_validate_data_keys(data)
  arad_sort_data(data)
}

arad_parse_updates_response <- function(raw, encoding = "windows-1250") {
  table <- arad_read_character_table(
    raw,
    endpoint = "updates",
    expected_columns = c("indicator_id", "snapshot_id", "update_date", "data_from", "data_to"),
    encoding = encoding
  )

  if (nrow(table) == 0L) {
    return(tibble::tibble(
      indicator_id = character(),
      snapshot_id = character(),
      update_date = as.POSIXct(character(), tz = "UTC"),
      data_from = as.Date(character()),
      data_to = as.Date(character())
    ))
  }

  if (anyNA(table$indicator_id) || any(!nzchar(trimws(table$indicator_id)))) {
    arad_abort("ARAD returned a missing or empty `indicator_id` in `/updates`.", "arad_integrity_error")
  }

  tibble::tibble(
    indicator_id = trimws(table$indicator_id),
    snapshot_id = table$snapshot_id,
    update_date = arad_parse_datetime_column(table$update_date, "update_date", allow_missing = TRUE),
    data_from = arad_parse_date_column(table$data_from, "data_from", allow_missing = TRUE),
    data_to = arad_parse_date_column(table$data_to, "data_to", allow_missing = TRUE)
  )
}

arad_empty_data <- function() {
  tibble::tibble(
    indicator_id = character(),
    snapshot_id = character(),
    period = as.Date(character()),
    value = double()
  )
}
