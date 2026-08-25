arad_endpoint_mode <- function() {
  mode <- getOption("aradR.endpoint_mode", "external")
  if (length(mode) != 1L || is.na(mode) || !mode %in% c("external", "internal")) {
    arad_abort(
      "Option `aradR.endpoint_mode` must be either `external` or `internal`.",
      "arad_input_error"
    )
  }
  mode
}

arad_request_mode <- function(base_url) {
  mode <- arad_endpoint_mode()
  if (!identical(mode, "internal")) {
    return(mode)
  }

  configured <- getOption("aradR.base_url", NULL)
  if (is.null(configured)) {
    return("external")
  }

  configured <- arad_validate_base_url(configured)
  if (!identical(base_url, configured)) {
    return("external")
  }

  "internal"
}

arad_apply_transport <- function(request, mode = arad_endpoint_mode()) {
  if (identical(mode, "internal")) {
    request <- httr2::req_options(
      request,
      proxy = "",
      noproxy = "*",
      httpauth = 4L,
      userpwd = ":"
    )
  }
  request
}

#' Configure ARAD endpoint mode
#'
#' `arad_use_internal()` opts in to an organization-provided ARAD endpoint that
#' is protected by integrated Negotiate authentication. The public ARAD endpoint
#' remains the package default unless this function is called.
#'
#' Internal mode bypasses configured proxies for requests to the configured
#' internal base URL and asks libcurl to use Negotiate authentication with the
#' current login. This is validated on Windows integrated authentication; other
#' platforms depend on local libcurl/Kerberos configuration.
#'
#' `arad_use_external()` restores the public ARAD endpoint and normal network
#' handling.
#'
#' @param base_url Internal ARAD REST API base URL. If omitted, the value of
#'   `ARAD_INTERNAL_BASE_URL` is used.
#' @param api_key Optional ARAD API key or internal user identifier. When
#'   supplied, it is stored only in the current R process as `ARAD_API_KEY`.
#' @return The configured base URL, invisibly.
#' @export
#' @examples
#' \dontrun{
#' arad_use_internal("https://internal.example/api/v1")
#' arad_catalog(set_id = 1058)
#'
#' arad_use_external()
#' }
arad_use_internal <- function(base_url = Sys.getenv("ARAD_INTERNAL_BASE_URL", unset = ""),
                              api_key = NULL) {
  if (length(base_url) != 1L || is.na(base_url) || !nzchar(trimws(base_url))) {
    arad_abort(
      "Supply `base_url` or set `ARAD_INTERNAL_BASE_URL` before using internal mode.",
      "arad_input_error"
    )
  }

  base_url <- arad_validate_base_url(base_url)

  if (!is.null(api_key)) {
    Sys.setenv(ARAD_API_KEY = arad_api_key(api_key))
  }

  options(
    aradR.base_url = base_url,
    aradR.endpoint_mode = "internal"
  )

  invisible(base_url)
}

#' @rdname arad_use_internal
#' @export
arad_use_external <- function(api_key = NULL) {
  if (!is.null(api_key)) {
    Sys.setenv(ARAD_API_KEY = arad_api_key(api_key))
  }

  options(
    aradR.base_url = NULL,
    aradR.endpoint_mode = "external"
  )

  invisible(arad_external_base_url())
}
