arad_request_raw <- function(endpoint,
                             query,
                             api_key,
                             base_url = NULL,
                             timeout = 30,
                             max_tries = 3L) {
  base_url <- arad_base_url(base_url)
  api_key <- arad_api_key(api_key)

  request <- httr2::request(base_url) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_url_query(!!!c(query, list(api_key = api_key))) |>
    httr2::req_user_agent("aradR R package") |>
    httr2::req_timeout(seconds = timeout) |>
    httr2::req_retry(max_tries = max_tries) |>
    httr2::req_error(is_error = function(resp) FALSE)

  response <- tryCatch(
    httr2::req_perform(request),
    error = function(e) {
      arad_abort(
        sprintf("ARAD request to `/%s` failed before a valid response was received.", endpoint),
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
    arad_abort(
      sprintf("ARAD request to `/%s` returned HTTP %s.%s", endpoint, status, suffix),
      if (status == 400L) "arad_api_error" else "arad_http_error"
    )
  }

  httr2::resp_body_raw(response)
}

arad_request <- function(endpoint, query, api_key, base_url = NULL) {
  request_fn <- getOption("aradR.request_fn")
  if (!is.null(request_fn)) {
    if (!is.function(request_fn)) {
      arad_abort("Option `aradR.request_fn` must be a function.", "arad_input_error")
    }
    return(request_fn(endpoint = endpoint, query = query, api_key = api_key, base_url = base_url))
  }
  arad_request_raw(endpoint = endpoint, query = query, api_key = api_key, base_url = base_url)
}
