arad_discovery_flag <- function(x, argument) {
  if (length(x) != 1L || is.na(x) || !is.logical(x)) {
    arad_abort(sprintf("`%s` must be TRUE or FALSE.", argument), "arad_input_error")
  }
  x
}

arad_match_text <- function(term, x, regex = FALSE, ignore_case = TRUE) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  if (regex) {
    return(grepl(term, x, ignore.case = ignore_case))
  }
  if (ignore_case) {
    return(grepl(tolower(term), tolower(x), fixed = TRUE))
  }
  grepl(term, x, fixed = TRUE)
}

arad_collapse_text <- function(x) {
  x <- trimws(as.character(x))
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x) == 0L) NA_character_ else paste(x, collapse = " | ")
}

arad_add_paths <- function(indicators, tree) {
  out <- tibble::as_tibble(indicators)
  out$path <- rep(NA_character_, nrow(out))
  if (nrow(out) == 0L || nrow(tree) == 0L) {
    return(out)
  }

  path_by_id <- vapply(
    split(tree$path, tree$indicator_id),
    arad_collapse_text,
    character(1)
  )
  out$path <- unname(path_by_id[out$indicator_id])
  out
}

arad_add_availability <- function(indicators, updates) {
  out <- tibble::as_tibble(indicators)
  n <- nrow(out)
  out$data_from <- rep(as.Date(NA), n)
  out$data_to <- rep(as.Date(NA), n)
  out$last_update <- rep(as.POSIXct(NA, tz = "UTC"), n)
  out$snapshot_contexts <- integer(n)

  if (n == 0L || nrow(updates) == 0L) {
    return(out)
  }

  for (i in seq_len(n)) {
    rows <- which(updates$indicator_id == out$indicator_id[[i]])
    if (length(rows) == 0L) {
      next
    }

    from_values <- updates$data_from[rows]
    from_values <- from_values[!is.na(from_values)]
    if (length(from_values) > 0L) {
      out$data_from[[i]] <- min(from_values)
    }

    to_values <- updates$data_to[rows]
    to_values <- to_values[!is.na(to_values)]
    if (length(to_values) > 0L) {
      out$data_to[[i]] <- max(to_values)
    }

    update_values <- updates$update_date[rows]
    update_values <- update_values[!is.na(update_values)]
    if (length(update_values) > 0L) {
      out$last_update[[i]] <- max(update_values)
    }

    snapshots <- trimws(as.character(updates$snapshot_id[rows]))
    snapshots[is.na(snapshots) | !nzchar(snapshots)] <- "current"
    out$snapshot_contexts[[i]] <- length(unique(snapshots))
  }

  out
}

arad_validate_frequency <- function(frequency) {
  if (is.null(frequency)) {
    return(NULL)
  }
  frequency <- unique(trimws(as.character(frequency)))
  if (anyNA(frequency) || any(!nzchar(frequency))) {
    arad_abort("`frequency` must contain non-empty frequency codes.", "arad_input_error")
  }
  frequency
}

#' Build an enriched catalogue of indicators within an ARAD scope
#'
#' Combines basic indicator metadata with ARAD hierarchy paths and, optionally,
#' available data boundaries. This is intended as a human-facing browsing layer
#' above the lower-level metadata endpoints.
#'
#' @inheritParams arad_indicators
#' @param include_path Include the ARAD hierarchy path for each indicator.
#' @param include_availability Include earliest/latest available dates, last
#'   update timestamp and the number of snapshot contexts reported by `/updates`.
#'
#' @return One row per indicator in the selected scope.
#' @export
arad_catalog <- function(indicator_ids = NULL,
                         set_id = NULL,
                         base_id = NULL,
                         selection_id = NULL,
                         lang = c("cs", "en"),
                         include_path = TRUE,
                         include_availability = TRUE,
                         api_key = NULL,
                         base_url = NULL,
                         encoding = "windows-1250",
                         cache = NULL,
                         cache_dir = NULL,
                         cache_max_age = NULL) {
  include_path <- arad_discovery_flag(include_path, "include_path")
  include_availability <- arad_discovery_flag(include_availability, "include_availability")
  lang <- arad_language(lang)

  indicators <- arad_indicators(
    indicator_ids = indicator_ids, set_id = set_id, base_id = base_id,
    selection_id = selection_id, lang = lang, api_key = api_key,
    base_url = base_url, encoding = encoding, cache = cache,
    cache_dir = cache_dir, cache_max_age = cache_max_age
  )
  out <- indicators

  if (include_path) {
    tree <- arad_tree(
      indicator_ids = indicator_ids, set_id = set_id, base_id = base_id,
      selection_id = selection_id, lang = lang, api_key = api_key,
      base_url = base_url, encoding = encoding, cache = cache,
      cache_dir = cache_dir, cache_max_age = cache_max_age
    )
    out <- arad_add_paths(out, tree)
  }

  if (include_availability) {
    updates <- arad_updates(
      indicator_ids = indicator_ids, set_id = set_id, base_id = base_id,
      selection_id = selection_id, api_key = api_key, base_url = base_url,
      encoding = encoding, cache = cache, cache_dir = cache_dir,
      cache_max_age = cache_max_age
    )
    out <- arad_add_availability(out, updates)
  }

  out
}

#' Find indicators using human-readable metadata
#'
#' Searches indicator names and IDs plus ARAD hierarchy paths. By default it
#' also searches base/dimension names and values, so users do not need to know
#' an indicator ID in advance. ARAD metadata endpoints are scoped, therefore
#' exactly one normal selector still has to be supplied.
#'
#' @param term Non-empty text or regular expression to search for.
#' @inheritParams arad_indicators
#' @param frequency Optional frequency code(s) to retain.
#' @param search_dimensions Search base and dimension labels/codes in addition
#'   to indicator names, IDs and hierarchy paths.
#' @param details Add availability/update columns to the returned matches.
#' @param regex Interpret `term` as a regular expression.
#' @param ignore_case Ignore case while matching.
#'
#' @return A filtered, path-aware indicator catalogue. With `details = TRUE`,
#'   availability columns are included for the matched indicators only.
#' @export
arad_find <- function(term,
                      indicator_ids = NULL,
                      set_id = NULL,
                      base_id = NULL,
                      selection_id = NULL,
                      frequency = NULL,
                      search_dimensions = TRUE,
                      details = TRUE,
                      regex = FALSE,
                      ignore_case = TRUE,
                      lang = c("cs", "en"),
                      api_key = NULL,
                      base_url = NULL,
                      encoding = "windows-1250",
                      cache = NULL,
                      cache_dir = NULL,
                      cache_max_age = NULL) {
  if (length(term) != 1L || is.na(term) || !nzchar(trimws(term))) {
    arad_abort("`term` must be a non-empty scalar string.", "arad_input_error")
  }
  search_dimensions <- arad_discovery_flag(search_dimensions, "search_dimensions")
  details <- arad_discovery_flag(details, "details")
  regex <- arad_discovery_flag(regex, "regex")
  ignore_case <- arad_discovery_flag(ignore_case, "ignore_case")
  frequency <- arad_validate_frequency(frequency)
  lang <- arad_language(lang)

  indicators <- arad_indicators(
    indicator_ids = indicator_ids, set_id = set_id, base_id = base_id,
    selection_id = selection_id, lang = lang, api_key = api_key,
    base_url = base_url, encoding = encoding, cache = cache,
    cache_dir = cache_dir, cache_max_age = cache_max_age
  )
  tree <- arad_tree(
    indicator_ids = indicator_ids, set_id = set_id, base_id = base_id,
    selection_id = selection_id, lang = lang, api_key = api_key,
    base_url = base_url, encoding = encoding, cache = cache,
    cache_dir = cache_dir, cache_max_age = cache_max_age
  )

  keep <- arad_match_text(term, indicators$indicator_id, regex, ignore_case) |
    arad_match_text(term, indicators$indicator_name, regex, ignore_case)

  if (nrow(tree) > 0L) {
    path_ids <- unique(tree$indicator_id[
      arad_match_text(term, tree$path, regex, ignore_case)
    ])
    keep <- keep | indicators$indicator_id %in% path_ids
  }

  if (search_dimensions) {
    dimensions <- arad_dimensions(
      indicator_ids = indicator_ids, set_id = set_id, base_id = base_id,
      selection_id = selection_id, lang = lang, api_key = api_key,
      base_url = base_url, encoding = encoding, cache = cache,
      cache_dir = cache_dir, cache_max_age = cache_max_age
    )
    if (nrow(dimensions) > 0L) {
      dimension_columns <- c(
        "base_id", "base_name", "dim_code", "dim_name",
        "dim_value_code", "dim_value_name"
      )
      dimension_match <- rep(FALSE, nrow(dimensions))
      for (column in dimension_columns) {
        dimension_match <- dimension_match |
          arad_match_text(term, dimensions[[column]], regex, ignore_case)
      }
      dimension_ids <- unique(dimensions$indicator_id[dimension_match])
      keep <- keep | indicators$indicator_id %in% dimension_ids
    }
  }

  if (!is.null(frequency)) {
    keep <- keep & indicators$frequency_code %in% frequency
  }

  out <- indicators[keep, , drop = FALSE]
  out <- arad_add_paths(out, tree)

  if (details) {
    if (nrow(out) > 0L) {
      updates <- arad_updates(
        indicator_ids = out$indicator_id, api_key = api_key,
        base_url = base_url, encoding = encoding, cache = cache,
        cache_dir = cache_dir, cache_max_age = cache_max_age
      )
    } else {
      updates <- tibble::tibble(
        indicator_id = character(), snapshot_id = character(),
        update_date = as.POSIXct(character(), tz = "UTC"),
        data_from = as.Date(character()), data_to = as.Date(character())
      )
    }
    out <- arad_add_availability(out, updates)
  }

  out
}

#' Inspect selected ARAD indicators in detail
#'
#' Retrieves the high-level summary, dimensional metadata and raw update rows
#' for one or more known indicator IDs. This is designed to follow
#' `arad_find()` or `arad_catalog()` when a user wants to inspect a candidate
#' series before downloading observations.
#'
#' @param indicator_ids Character vector of indicator IDs to inspect.
#' @param lang Metadata language, `"cs"` or `"en"`.
#' @param api_key ARAD API key. If `NULL`, `ARAD_API_KEY` is used.
#' @param base_url ARAD API base URL. Primarily intended for testing.
#' @param encoding Response encoding.
#' @param cache Response cache: `"none"`, `"session"`, or `"disk"`.
#' @param cache_dir Optional disk cache directory.
#' @param cache_max_age Maximum cache age in seconds.
#'
#' @return A named list with `summary`, `dimensions`, and `updates` tibbles.
#' @export
arad_info <- function(indicator_ids,
                      lang = c("cs", "en"),
                      api_key = NULL,
                      base_url = NULL,
                      encoding = "windows-1250",
                      cache = NULL,
                      cache_dir = NULL,
                      cache_max_age = NULL) {
  indicator_ids <- arad_clean_indicator_ids(indicator_ids)
  if (is.null(indicator_ids)) {
    arad_abort("`indicator_ids` must contain at least one indicator ID.", "arad_input_error")
  }
  lang <- arad_language(lang)

  indicators <- arad_indicators(
    indicator_ids = indicator_ids, lang = lang, api_key = api_key,
    base_url = base_url, encoding = encoding, cache = cache,
    cache_dir = cache_dir, cache_max_age = cache_max_age
  )
  tree <- arad_tree(
    indicator_ids = indicator_ids, lang = lang, api_key = api_key,
    base_url = base_url, encoding = encoding, cache = cache,
    cache_dir = cache_dir, cache_max_age = cache_max_age
  )
  dimensions <- arad_dimensions(
    indicator_ids = indicator_ids, lang = lang, api_key = api_key,
    base_url = base_url, encoding = encoding, cache = cache,
    cache_dir = cache_dir, cache_max_age = cache_max_age
  )
  updates <- arad_updates(
    indicator_ids = indicator_ids, api_key = api_key, base_url = base_url,
    encoding = encoding, cache = cache, cache_dir = cache_dir,
    cache_max_age = cache_max_age
  )

  summary <- arad_add_availability(arad_add_paths(indicators, tree), updates)
  list(summary = summary, dimensions = dimensions, updates = updates)
}
