arad_base_url <- function(base_url = NULL) {
  if (is.null(base_url)) {
    base_url <- getOption("aradR.base_url", "https://www.cnb.cz/aradb/api/v1")
  }
  if (length(base_url) != 1L || is.na(base_url) || !nzchar(base_url)) {
    arad_abort("`base_url` must be a non-empty scalar string.", "arad_input_error")
  }
  sub("/+$", "", base_url)
}

arad_api_key <- function(api_key = NULL) {
  if (is.null(api_key)) {
    api_key <- Sys.getenv("ARAD_API_KEY", unset = "")
  }
  if (length(api_key) != 1L || is.na(api_key) || !nzchar(trimws(api_key))) {
    arad_abort(
      "ARAD API key is missing. Set `ARAD_API_KEY` or supply `api_key` explicitly.",
      "arad_auth_error"
    )
  }
  trimws(api_key)
}

arad_clean_scalar_id <- function(x, argument) {
  if (is.null(x) || length(x) == 0L) {
    return(NULL)
  }
  if (length(x) != 1L || is.na(x)) {
    arad_abort(sprintf("`%s` must be a single non-missing value.", argument), "arad_input_error")
  }
  x <- trimws(as.character(x))
  if (!nzchar(x)) {
    arad_abort(sprintf("`%s` must not be empty.", argument), "arad_input_error")
  }
  x
}

arad_clean_indicator_ids <- function(indicator_ids) {
  if (is.null(indicator_ids) || length(indicator_ids) == 0L) {
    return(NULL)
  }
  ids <- trimws(as.character(indicator_ids))
  if (anyNA(ids) || any(!nzchar(ids))) {
    arad_abort("`indicator_ids` must contain only non-empty, non-missing IDs.", "arad_input_error")
  }
  unique(ids)
}

arad_selector <- function(indicator_ids = NULL,
                          set_id = NULL,
                          base_id = NULL,
                          selection_id = NULL) {
  indicator_ids <- arad_clean_indicator_ids(indicator_ids)
  set_id <- arad_clean_scalar_id(set_id, "set_id")
  base_id <- arad_clean_scalar_id(base_id, "base_id")
  selection_id <- arad_clean_scalar_id(selection_id, "selection_id")

  supplied <- c(
    indicator_ids = !is.null(indicator_ids),
    set_id = !is.null(set_id),
    base_id = !is.null(base_id),
    selection_id = !is.null(selection_id)
  )

  if (sum(supplied) != 1L) {
    arad_abort(
      "Supply exactly one selector: `indicator_ids`, `set_id`, `base_id`, or `selection_id`.",
      "arad_selector_error"
    )
  }

  if (supplied[["indicator_ids"]]) {
    value <- paste(indicator_ids, collapse = ",")
    return(list(param = "indicator_id_list", value = value, indicator_ids = indicator_ids))
  }
  if (supplied[["set_id"]]) {
    return(list(param = "set_id", value = set_id, indicator_ids = NULL))
  }
  if (supplied[["base_id"]]) {
    return(list(param = "base_id", value = base_id, indicator_ids = NULL))
  }
  list(param = "selection_id", value = selection_id, indicator_ids = NULL)
}

arad_selector_query <- function(selector) {
  stats::setNames(list(selector$value), selector$param)
}

arad_snapshot_value <- function(snapshot_ids) {
  if (is.null(snapshot_ids) || length(snapshot_ids) == 0L) {
    return(NULL)
  }
  ids <- trimws(as.character(snapshot_ids))
  if (anyNA(ids) || any(!nzchar(ids))) {
    arad_abort("`snapshot_ids` must contain only non-empty, non-missing values.", "arad_input_error")
  }
  paste(unique(ids), collapse = ",")
}

arad_date <- function(x, argument) {
  if (is.null(x)) {
    return(NULL)
  }
  if (length(x) != 1L || is.na(x)) {
    arad_abort(sprintf("`%s` must be a single non-missing date.", argument), "arad_input_error")
  }

  if (inherits(x, "Date")) {
    return(x)
  }
  if (inherits(x, "POSIXt")) {
    return(as.Date(x))
  }

  x <- trimws(as.character(x))
  if (grepl("^[0-9]{8}$", x)) {
    out <- as.Date(x, format = "%Y%m%d")
  } else if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)) {
    out <- as.Date(x, format = "%Y-%m-%d")
  } else {
    out <- as.Date(NA)
  }

  if (is.na(out)) {
    arad_abort(
      sprintf("`%s` must be a Date or a string in YYYY-MM-DD / YYYYMMDD format.", argument),
      "arad_input_error"
    )
  }
  out
}

arad_date_param <- function(x) {
  if (is.null(x)) NULL else format(x, "%Y%m%d")
}

arad_months_before <- function(months_before) {
  if (is.null(months_before)) {
    return(NULL)
  }
  value <- suppressWarnings(as.integer(months_before))
  if (length(value) != 1L || is.na(value) || value < 1L || value != months_before) {
    arad_abort("`months_before` must be a positive integer.", "arad_input_error")
  }
  value
}

arad_make_chunks <- function(from, to, chunk_days) {
  if (is.null(from) || is.null(to) || is.na(from) || is.na(to)) {
    arad_abort("Chunking requires non-missing `from` and `to` dates.", "arad_input_error")
  }
  if (from > to) {
    arad_abort("`from` must not be later than `to`.", "arad_input_error")
  }

  chunk_days <- suppressWarnings(as.integer(chunk_days))
  if (length(chunk_days) != 1L || is.na(chunk_days) || chunk_days < 1L) {
    arad_abort("`chunk_days` must be a positive integer.", "arad_input_error")
  }

  chunks <- list()
  start <- from
  i <- 1L
  while (start <= to) {
    end <- min(start + (chunk_days - 1L), to)
    chunks[[i]] <- list(from = start, to = end)
    start <- end + 1L
    i <- i + 1L
  }
  chunks
}
