arad_request_failure_message <- function(endpoint, error, api_key, mode) {
  detail <- conditionMessage(error)
  detail <- arad_redact(detail, api_key)
  detail <- gsub("api_key=[^&[:space:]]+", "api_key=<redacted>", detail, perl = TRUE)
  detail <- trimws(detail)

  if (nchar(detail) > 400L) {
    detail <- paste0(substr(detail, 1L, 400L), "...")
  }

  hint <- ""
  if (grepl("proxy after CONNECT", detail, ignore.case = TRUE)) {
    hint <- paste0(
      " The network proxy blocked the connection before ARAD was reached.",
      " For an integrated internal endpoint, use `arad_use_internal()` rather than only changing `base_url`."
    )
  } else if (identical(mode, "internal")) {
    hint <- " Internal mode could not establish an authenticated connection to the configured endpoint."
  }

  if (nzchar(detail)) {
    sprintf(
      "ARAD request to `/%s` failed before a valid response was received: %s%s",
      endpoint,
      detail,
      hint
    )
  } else {
    sprintf(
      "ARAD request to `/%s` failed before a valid response was received.%s",
      endpoint,
      hint
    )
  }
}

arad_request_raw <- function(endpoint,
                             query,
                             api_key,
                             base_url = NULL,
                             timeout = 30,
                             max_tries = 3L) {
  base_url <- arad_base_url(base_url)
  api_key <- arad_api_key(api_key)
  mode <- arad_request_mode(base_url)

  request <- httr2::request(base_url) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_url_query(!!!c(query, list(api_key = api_key))) |>
    httr2::req_user_agent("aradR R package") |>
    httr2::req_timeout(seconds = timeout) |>
    httr2::req_retry(max_tries = max_tries) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    arad_apply_transport(mode = mode)

  response <- tryCatch(
    httr2::req_perform(request),
    error = function(e) {
      arad_abort(
        arad_request_failure_message(endpoint, e, api_key, mode),
        "arad_http_error"
      )
    }
  )

  status <- httr2::resp_status(response)
  if (status >= 400L) {
    body <- tryCatch(httr2::resp_body_string(response), error = function(e) "")
    body <- arad_redact(body, api_key)
    body <- trimws(body)
    if (nchar(body) > 500L) {
      body <- paste0(substr(body, 1L, 500L), "...")
    }

    suffix <- if (nzchar(body)) paste0(" Server response: ", body) else ""
    if (status == 401L && identical(mode, "internal")) {
      suffix <- paste0(
        suffix,
        " Integrated authentication was not accepted. Verify that the session is running under an authorized login and that Negotiate authentication is available."
      )
    }

    error_class <- if (status == 400L) {
      "arad_api_error"
    } else if (status == 401L) {
      "arad_auth_error"
    } else {
      "arad_http_error"
    }

    arad_abort(
      sprintf("ARAD request to `/%s` returned HTTP %s.%s", endpoint, status, suffix),
      error_class
    )
  }

  httr2::resp_body_raw(response)
}

arad_request <- function(endpoint,
                         query,
                         api_key,
                         base_url = NULL,
                         cache = NULL,
                         cache_dir = NULL,
                         cache_max_age = NULL) {
  base_url <- arad_base_url(base_url)
  api_key <- arad_api_key(api_key)
  cache <- arad_cache_mode(cache)
  cache_max_age <- arad_cache_age(cache_max_age)
  key <- arad_cache_key(endpoint, query, base_url, api_key)

  cached <- arad_cache_get(
    key,
    mode = cache,
    max_age = cache_max_age,
    cache_dir = cache_dir
  )
  if (!is.null(cached)) {
    attr(cached, "arad_cache_hit") <- TRUE
    return(cached)
  }

  request_fn <- getOption("aradR.request_fn")
  if (!is.null(request_fn)) {
    if (!is.function(request_fn)) {
      arad_abort("Option `aradR.request_fn` must be a function.", "arad_input_error")
    }
    raw <- request_fn(endpoint = endpoint, query = query, api_key = api_key, base_url = base_url)
  } else {
    raw <- arad_request_raw(endpoint = endpoint, query = query, api_key = api_key, base_url = base_url)
  }

  if (!is.raw(raw)) {
    arad_abort("ARAD request function must return raw bytes.", "arad_parse_error")
  }

  arad_cache_set(key, raw, mode = cache, cache_dir = cache_dir)
  attr(raw, "arad_cache_hit") <- FALSE
  raw
}
