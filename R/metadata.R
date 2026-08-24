arad_language <- function(lang = c("cs", "en")) {
  match.arg(lang)
}

arad_metadata_query <- function(selector = NULL, lang = "cs") {
  query <- list(
    lang = arad_language(lang),
    delimiter = "semicolon"
  )
  if (!is.null(selector)) {
    query <- c(arad_selector_query(selector), query)
  }
  query
}

arad_validate_required_text <- function(table, columns, endpoint) {
  for (column in columns) {
    if (anyNA(table[[column]]) || any(!nzchar(trimws(table[[column]])))) {
      arad_abort(
        sprintf("ARAD `/%s` returned a missing or empty `%s`.", endpoint, column),
        "arad_integrity_error"
      )
    }
  }
  invisible(table)
}

arad_parse_integer_metadata <- function(x, column, endpoint, allow_missing = TRUE) {
  out <- suppressWarnings(as.integer(x))
  invalid <- !is.na(x) & is.na(out)
  if (any(invalid)) {
    arad_abort(
      sprintf("ARAD `/%s` returned non-integer values in `%s`.", endpoint, column),
      "arad_parse_error"
    )
  }
  if (!allow_missing && anyNA(out)) {
    arad_abort(
      sprintf("ARAD `/%s` returned missing values in required `%s`.", endpoint, column),
      "arad_parse_error"
    )
  }
  out
}

arad_parse_indicators_response <- function(raw, encoding = "windows-1250") {
  endpoint <- "indicators"
  expected <- c(
    "indicator_id", "indicator_name", "frequency_code", "frequency_name",
    "unit_mult_code", "unit_mult_name", "unit"
  )
  table <- arad_read_character_table(raw, endpoint, expected, encoding)
  if (nrow(table) == 0L) {
    return(tibble::tibble(
      indicator_id = character(), indicator_name = character(),
      frequency_code = character(), frequency_name = character(),
      unit_mult_code = integer(), unit_mult_name = character(), unit = character()
    ))
  }
  arad_validate_required_text(table, "indicator_id", endpoint)
  tibble::tibble(
    indicator_id = trimws(table$indicator_id),
    indicator_name = table$indicator_name,
    frequency_code = table$frequency_code,
    frequency_name = table$frequency_name,
    unit_mult_code = arad_parse_integer_metadata(table$unit_mult_code, "unit_mult_code", endpoint),
    unit_mult_name = table$unit_mult_name,
    unit = table$unit
  )
}

arad_parse_dimensions_response <- function(raw, encoding = "windows-1250") {
  endpoint <- "indicators-dims"
  expected <- c(
    "indicator_id", "base_name", "dim_code", "dim_name",
    "dim_value_code", "dim_value_name", "dim_rank"
  )
  table <- arad_read_character_table(raw, endpoint, expected, encoding)

  base_column <- if ("base_id" %in% names(table)) {
    "base_id"
  } else if ("base_code" %in% names(table)) {
    "base_code"
  } else {
    arad_abort(
      "ARAD `/indicators-dims` response is missing required column `base_id` or `base_code`.",
      "arad_parse_error"
    )
  }

  if (nrow(table) == 0L) {
    return(tibble::tibble(
      indicator_id = character(), base_id = character(), base_name = character(),
      dim_code = character(), dim_name = character(), dim_value_code = character(),
      dim_value_name = character(), dim_rank = integer()
    ))
  }
  arad_validate_required_text(table, "indicator_id", endpoint)
  base_values <- table[[base_column]]
  if (anyNA(base_values) || any(!nzchar(trimws(base_values)))) {
    arad_abort(
      sprintf("ARAD `/%s` returned a missing or empty `%s`.", endpoint, base_column),
      "arad_integrity_error"
    )
  }
  tibble::tibble(
    indicator_id = trimws(table$indicator_id),
    base_id = trimws(base_values),
    base_name = table$base_name,
    dim_code = table$dim_code,
    dim_name = table$dim_name,
    dim_value_code = table$dim_value_code,
    dim_value_name = table$dim_value_name,
    dim_rank = arad_parse_integer_metadata(table$dim_rank, "dim_rank", endpoint, allow_missing = FALSE)
  )
}

arad_parse_tree_response <- function(raw, encoding = "windows-1250") {
  endpoint <- "indicators-tree"
  table <- arad_read_character_table(raw, endpoint, c("indicator_id", "path"), encoding)
  if (nrow(table) == 0L) {
    return(tibble::tibble(indicator_id = character(), path = character()))
  }
  arad_validate_required_text(table, c("indicator_id", "path"), endpoint)
  tibble::tibble(indicator_id = trimws(table$indicator_id), path = table$path)
}

arad_parse_snapshots_response <- function(raw, encoding = "windows-1250") {
  endpoint <- "snapshots"
  table <- arad_read_character_table(raw, endpoint, c("snapshot_id", "snapshot_name"), encoding)
  if (nrow(table) == 0L) {
    return(tibble::tibble(snapshot_id = character(), snapshot_name = character()))
  }
  arad_validate_required_text(table, c("snapshot_id", "snapshot_name"), endpoint)
  tibble::tibble(snapshot_id = trimws(table$snapshot_id), snapshot_name = table$snapshot_name)
}

arad_metadata_request <- function(endpoint,
                                  parser,
                                  selector = NULL,
                                  lang = "cs",
                                  api_key = NULL,
                                  base_url = NULL,
                                  encoding = "windows-1250",
                                  cache = NULL,
                                  cache_dir = NULL,
                                  cache_max_age = NULL) {
  api_key <- arad_api_key(api_key)
  raw <- arad_request(
    endpoint,
    query = arad_metadata_query(selector, lang),
    api_key = api_key,
    base_url = base_url,
    cache = cache,
    cache_dir = cache_dir,
    cache_max_age = cache_max_age
  )
  out <- parser(raw, encoding = encoding)
  attr(out, "arad_cache_hit") <- isTRUE(attr(raw, "arad_cache_hit"))
  out
}

#' List ARAD indicators and basic metadata
#'
#' @inheritParams arad_get
#' @param lang Metadata language, `"cs"` or `"en"`.
#' @param cache Response cache: `"none"`, `"session"`, or `"disk"`.
#' @param cache_dir Optional disk cache directory.
#' @param cache_max_age Maximum cache age in seconds; defaults to `Inf`.
#'
#' @return A tibble with indicator name, frequency, scaling and units.
#' @export
arad_indicators <- function(indicator_ids = NULL,
                            set_id = NULL,
                            base_id = NULL,
                            selection_id = NULL,
                            lang = c("cs", "en"),
                            api_key = NULL,
                            base_url = NULL,
                            encoding = "windows-1250",
                            cache = NULL,
                            cache_dir = NULL,
                            cache_max_age = NULL) {
  selector <- arad_selector(indicator_ids, set_id, base_id, selection_id)
  arad_metadata_request(
    "indicators", arad_parse_indicators_response, selector,
    arad_language(lang), api_key, base_url, encoding,
    cache, cache_dir, cache_max_age
  )
}

#' List ARAD indicator dimensions
#'
#' @inheritParams arad_indicators
#'
#' @return A tibble describing each indicator's base and dimensions.
#' @export
arad_dimensions <- function(indicator_ids = NULL,
                            set_id = NULL,
                            base_id = NULL,
                            selection_id = NULL,
                            lang = c("cs", "en"),
                            api_key = NULL,
                            base_url = NULL,
                            encoding = "windows-1250",
                            cache = NULL,
                            cache_dir = NULL,
                            cache_max_age = NULL) {
  selector <- arad_selector(indicator_ids, set_id, base_id, selection_id)
  arad_metadata_request(
    "indicators-dims", arad_parse_dimensions_response, selector,
    arad_language(lang), api_key, base_url, encoding,
    cache, cache_dir, cache_max_age
  )
}

#' List ARAD indicator tree paths
#'
#' @inheritParams arad_indicators
#'
#' @return A tibble with `indicator_id` and its ARAD tree `path`.
#' @export
arad_tree <- function(indicator_ids = NULL,
                      set_id = NULL,
                      base_id = NULL,
                      selection_id = NULL,
                      lang = c("cs", "en"),
                      api_key = NULL,
                      base_url = NULL,
                      encoding = "windows-1250",
                      cache = NULL,
                      cache_dir = NULL,
                      cache_max_age = NULL) {
  selector <- arad_selector(indicator_ids, set_id, base_id, selection_id)
  arad_metadata_request(
    "indicators-tree", arad_parse_tree_response, selector,
    arad_language(lang), api_key, base_url, encoding,
    cache, cache_dir, cache_max_age
  )
}

#' List available ARAD snapshots
#'
#' @param lang Metadata language, `"cs"` or `"en"`.
#' @param api_key ARAD API key. If `NULL`, `ARAD_API_KEY` is used.
#' @param base_url ARAD API base URL. Primarily intended for testing.
#' @param encoding Response encoding.
#' @param cache Response cache: `"none"`, `"session"`, or `"disk"`.
#' @param cache_dir Optional disk cache directory.
#' @param cache_max_age Maximum cache age in seconds.
#'
#' @return A tibble with `snapshot_id` and `snapshot_name`.
#' @export
arad_snapshots <- function(lang = c("cs", "en"),
                           api_key = NULL,
                           base_url = NULL,
                           encoding = "windows-1250",
                           cache = NULL,
                           cache_dir = NULL,
                           cache_max_age = NULL) {
  arad_metadata_request(
    "snapshots", arad_parse_snapshots_response, selector = NULL,
    lang = arad_language(lang), api_key = api_key, base_url = base_url,
    encoding = encoding, cache = cache, cache_dir = cache_dir,
    cache_max_age = cache_max_age
  )
}

#' Search indicators within an ARAD scope
#'
#' Searches indicator IDs and names returned by `/indicators`. ARAD does not
#' expose a global list through this endpoint, so exactly one normal ARAD scope
#' selector must be supplied.
#'
#' @param term Non-empty search text or regular expression.
#' @inheritParams arad_indicators
#' @param frequency Optional frequency code(s) to retain after text matching.
#' @param regex Interpret `term` as a regular expression. Defaults to `FALSE`.
#' @param ignore_case Ignore case while matching.
#'
#' @return A filtered indicator metadata tibble.
#' @export
arad_search <- function(term,
                        indicator_ids = NULL,
                        set_id = NULL,
                        base_id = NULL,
                        selection_id = NULL,
                        frequency = NULL,
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
  if (length(regex) != 1L || is.na(regex) || !is.logical(regex)) {
    arad_abort("`regex` must be TRUE or FALSE.", "arad_input_error")
  }
  if (length(ignore_case) != 1L || is.na(ignore_case) || !is.logical(ignore_case)) {
    arad_abort("`ignore_case` must be TRUE or FALSE.", "arad_input_error")
  }

  indicators <- arad_indicators(
    indicator_ids, set_id, base_id, selection_id,
    lang = arad_language(lang), api_key = api_key, base_url = base_url,
    encoding = encoding, cache = cache, cache_dir = cache_dir,
    cache_max_age = cache_max_age
  )

  matcher <- function(x) {
    if (regex) {
      return(grepl(term, x, ignore.case = ignore_case))
    }
    if (ignore_case) {
      return(grepl(tolower(term), tolower(x), fixed = TRUE))
    }
    grepl(term, x, fixed = TRUE)
  }
  keep <- matcher(indicators$indicator_id) | matcher(indicators$indicator_name)

  if (!is.null(frequency)) {
    frequency <- unique(trimws(as.character(frequency)))
    if (anyNA(frequency) || any(!nzchar(frequency))) {
      arad_abort("`frequency` must contain non-empty frequency codes.", "arad_input_error")
    }
    keep <- keep & indicators$frequency_code %in% frequency
  }

  out <- indicators[keep, , drop = FALSE]
  attr(out, "arad_cache_hit") <- attr(indicators, "arad_cache_hit")
  out
}
