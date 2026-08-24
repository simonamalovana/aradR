arad_updates_selector <- function(selector,
                                  snapshot_value = NULL,
                                  api_key,
                                  base_url = NULL,
                                  encoding = "windows-1250",
                                  cache = NULL,
                                  cache_dir = NULL,
                                  cache_max_age = NULL) {
  query <- c(
    arad_selector_query(selector),
    list(delimiter = "semicolon")
  )
  if (!is.null(snapshot_value)) {
    query$snapshot_id_list <- snapshot_value
  }

  raw <- arad_request(
    "updates",
    query = query,
    api_key = api_key,
    base_url = base_url,
    cache = cache,
    cache_dir = cache_dir,
    cache_max_age = cache_max_age
  )
  out <- arad_parse_updates_response(raw, encoding = encoding)
  attr(out, "arad_cache_hit") <- isTRUE(attr(raw, "arad_cache_hit"))
  out
}

#' Retrieve ARAD update metadata
#'
#' Retrieves the last update timestamp and available data boundaries for ARAD
#' time series. Exactly one selector must be supplied.
#'
#' @param indicator_ids Character vector of indicator IDs.
#' @param set_id ARAD set ID.
#' @param base_id ARAD base ID.
#' @param selection_id ARAD user selection ID.
#' @param snapshot_ids Optional snapshot IDs, or `"ALL"` / `"LAST"`.
#' @param api_key ARAD API key. If `NULL`, `ARAD_API_KEY` is used.
#' @param base_url ARAD API base URL. Primarily intended for testing.
#' @param encoding Response encoding. Defaults to Windows-1250 as documented by ARAD.
#' @param cache Response cache: `"none"`, `"session"`, or `"disk"`.
#' @param cache_dir Optional disk cache directory.
#' @param cache_max_age Maximum cache age in seconds; defaults to `Inf`.
#'
#' @return A tibble with `indicator_id`, `snapshot_id`, `update_date`,
#'   `data_from`, and `data_to`.
#' @export
arad_updates <- function(indicator_ids = NULL,
                         set_id = NULL,
                         base_id = NULL,
                         selection_id = NULL,
                         snapshot_ids = NULL,
                         api_key = NULL,
                         base_url = NULL,
                         encoding = "windows-1250",
                         cache = NULL,
                         cache_dir = NULL,
                         cache_max_age = NULL) {
  selector <- arad_selector(
    indicator_ids = indicator_ids,
    set_id = set_id,
    base_id = base_id,
    selection_id = selection_id
  )
  snapshot_value <- arad_snapshot_value(snapshot_ids)
  api_key <- arad_api_key(api_key)

  arad_updates_selector(
    selector = selector,
    snapshot_value = snapshot_value,
    api_key = api_key,
    base_url = base_url,
    encoding = encoding,
    cache = cache,
    cache_dir = cache_dir,
    cache_max_age = cache_max_age
  )
}

arad_validate_expected_indicators <- function(data, selector) {
  requested <- selector$indicator_ids
  if (is.null(requested) || (length(requested) == 1L && identical(requested, "ALL"))) {
    return(invisible(data))
  }
  unexpected <- setdiff(unique(data$indicator_id), requested)
  if (length(unexpected) > 0L) {
    arad_abort(
      sprintf("ARAD returned unexpected indicator ID(s): %s.", paste(unexpected, collapse = ", ")),
      "arad_integrity_error"
    )
  }
  invisible(data)
}

arad_attach_diagnostics <- function(data,
                                    strategy,
                                    data_requests,
                                    updates_requests,
                                    resolved_from = NULL,
                                    resolved_to = NULL,
                                    chunk_days = NULL) {
  attr(data, "arad_diagnostics") <- list(
    strategy = strategy,
    data_requests = data_requests,
    updates_requests = updates_requests,
    resolved_from = resolved_from,
    resolved_to = resolved_to,
    chunk_days = chunk_days
  )
  data
}

#' Retrieve time series from ARAD
#'
#' Reliability-first retrieval of ARAD time series. Exactly one selector must be
#' supplied: indicator IDs, set ID, base ID, or selection ID.
#'
#' With `strategy = "auto"`, date ranges are split into deterministic,
#' non-overlapping chunks. If one or both range boundaries are omitted, the
#' package obtains them from `/updates`. This avoids relying on a single large
#' API response for long histories and limits per-request volume.
#'
#' @param indicator_ids Character vector of indicator IDs.
#' @param set_id ARAD set ID.
#' @param base_id ARAD base ID.
#' @param selection_id ARAD user selection ID.
#' @param from Start date as `Date`, `YYYY-MM-DD`, or `YYYYMMDD`.
#' @param to End date as `Date`, `YYYY-MM-DD`, or `YYYYMMDD`.
#' @param months_before Optional positive integer. This is an ARAD-native
#'   alternative to `from`/`to` and is retrieved directly.
#' @param snapshot_ids Optional snapshot IDs, or `"ALL"` / `"LAST"`.
#' @param strategy Retrieval strategy. `"auto"` uses bounded requests;
#'   `"direct"` makes one `/data` request.
#' @param chunk_days Maximum inclusive date span of each automatic chunk.
#'   The current default is provisional pending the live regression benchmark.
#' @param api_key ARAD API key. If `NULL`, `ARAD_API_KEY` is used.
#' @param base_url ARAD API base URL. Primarily intended for testing.
#' @param encoding Response encoding. Defaults to Windows-1250 as documented by ARAD.
#' @param cache Response cache: `"none"`, `"session"`, or `"disk"`.
#' @param cache_dir Optional disk cache directory.
#' @param cache_max_age Maximum cache age in seconds; defaults to `Inf`.
#'
#' @return A tibble with `indicator_id`, `snapshot_id`, `period`, and `value`.
#'   Retrieval diagnostics are stored in the `arad_diagnostics` attribute.
#' @export
arad_get <- function(indicator_ids = NULL,
                     set_id = NULL,
                     base_id = NULL,
                     selection_id = NULL,
                     from = NULL,
                     to = NULL,
                     months_before = NULL,
                     snapshot_ids = NULL,
                     strategy = c("auto", "direct"),
                     chunk_days = getOption("aradR.chunk_days", 3650L),
                     api_key = NULL,
                     base_url = NULL,
                     encoding = "windows-1250",
                     cache = NULL,
                     cache_dir = NULL,
                     cache_max_age = NULL) {
  strategy <- match.arg(strategy)
  selector <- arad_selector(
    indicator_ids = indicator_ids,
    set_id = set_id,
    base_id = base_id,
    selection_id = selection_id
  )
  api_key <- arad_api_key(api_key)
  snapshot_value <- arad_snapshot_value(snapshot_ids)
  from <- arad_date(from, "from")
  to <- arad_date(to, "to")
  months_before <- arad_months_before(months_before)

  if (!is.null(from) && !is.null(to) && from > to) {
    arad_abort("`from` must not be later than `to`.", "arad_input_error")
  }
  if (!is.null(months_before) && (!is.null(from) || !is.null(to))) {
    arad_abort("Use either `months_before` or `from`/`to`, not both.", "arad_input_error")
  }

  base_query <- c(
    arad_selector_query(selector),
    list(
      delimiter = "semicolon",
      decimal_separator = "point",
      period_sort = "asc"
    )
  )
  if (!is.null(snapshot_value)) {
    base_query$snapshot_id_list <- snapshot_value
  }

  if (!is.null(months_before)) {
    query <- base_query
    query$months_before <- months_before
    raw <- arad_request(
      "data", query = query, api_key = api_key, base_url = base_url,
      cache = cache, cache_dir = cache_dir, cache_max_age = cache_max_age
    )
    data <- arad_parse_data_response(raw, encoding = encoding)
    arad_validate_expected_indicators(data, selector)
    return(arad_attach_diagnostics(
      data,
      strategy = "direct-months-before",
      data_requests = 1L,
      updates_requests = 0L
    ))
  }

  if (identical(strategy, "direct")) {
    query <- base_query
    if (!is.null(from)) query$period_from <- arad_date_param(from)
    if (!is.null(to)) query$period_to <- arad_date_param(to)
    raw <- arad_request(
      "data", query = query, api_key = api_key, base_url = base_url,
      cache = cache, cache_dir = cache_dir, cache_max_age = cache_max_age
    )
    data <- arad_parse_data_response(raw, encoding = encoding)
    arad_validate_expected_indicators(data, selector)
    return(arad_attach_diagnostics(
      data,
      strategy = "direct",
      data_requests = 1L,
      updates_requests = 0L,
      resolved_from = from,
      resolved_to = to
    ))
  }

  resolved_from <- from
  resolved_to <- to
  updates_requests <- 0L

  if (is.null(resolved_from) || is.null(resolved_to)) {
    updates <- arad_updates_selector(
      selector = selector,
      snapshot_value = snapshot_value,
      api_key = api_key,
      base_url = base_url,
      encoding = encoding,
      cache = cache,
      cache_dir = cache_dir,
      cache_max_age = cache_max_age
    )
    updates_requests <- 1L

    if (nrow(updates) == 0L) {
      return(arad_attach_diagnostics(
        arad_empty_data(),
        strategy = "auto-empty",
        data_requests = 0L,
        updates_requests = updates_requests
      ))
    }

    if (is.null(resolved_from)) {
      candidates <- updates$data_from[!is.na(updates$data_from)]
      if (length(candidates) == 0L) {
        arad_abort("ARAD `/updates` did not provide a usable lower data boundary.", "arad_integrity_error")
      }
      resolved_from <- min(candidates)
    }
    if (is.null(resolved_to)) {
      candidates <- updates$data_to[!is.na(updates$data_to)]
      if (length(candidates) == 0L) {
        arad_abort("ARAD `/updates` did not provide a usable upper data boundary.", "arad_integrity_error")
      }
      resolved_to <- max(candidates)
    }
  }

  if (resolved_from > resolved_to) {
    return(arad_attach_diagnostics(
      arad_empty_data(),
      strategy = "auto-empty",
      data_requests = 0L,
      updates_requests = updates_requests,
      resolved_from = resolved_from,
      resolved_to = resolved_to,
      chunk_days = chunk_days
    ))
  }

  chunks <- arad_make_chunks(resolved_from, resolved_to, chunk_days = chunk_days)
  pieces <- vector("list", length(chunks))

  for (i in seq_along(chunks)) {
    query <- base_query
    query$period_from <- arad_date_param(chunks[[i]]$from)
    query$period_to <- arad_date_param(chunks[[i]]$to)
    raw <- arad_request(
      "data", query = query, api_key = api_key, base_url = base_url,
      cache = cache, cache_dir = cache_dir, cache_max_age = cache_max_age
    )
    pieces[[i]] <- arad_parse_data_response(raw, encoding = encoding)
  }

  if (length(pieces) == 0L) {
    data <- arad_empty_data()
  } else {
    data <- tibble::as_tibble(do.call(rbind, pieces))
  }

  arad_validate_data_keys(data)
  data <- arad_sort_data(data)
  arad_validate_expected_indicators(data, selector)

  arad_attach_diagnostics(
    data,
    strategy = if (length(chunks) > 1L) "auto-chunked" else "auto-single",
    data_requests = length(chunks),
    updates_requests = updates_requests,
    resolved_from = resolved_from,
    resolved_to = resolved_to,
    chunk_days = as.integer(chunk_days)
  )
}
