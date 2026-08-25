test_that("public ARAD remains the default endpoint mode", {
  old_base <- getOption("aradR.base_url", NULL)
  old_mode <- getOption("aradR.endpoint_mode", NULL)
  on.exit(options(aradR.base_url = old_base, aradR.endpoint_mode = old_mode), add = TRUE)

  options(aradR.base_url = NULL, aradR.endpoint_mode = NULL)

  expect_identical(aradR:::arad_endpoint_mode(), "external")
  expect_identical(
    aradR:::arad_base_url(),
    "https://www.cnb.cz/aradb/api/v1"
  )
})

test_that("internal mode configures endpoint, proxy bypass and Negotiate", {
  old_base <- getOption("aradR.base_url", NULL)
  old_mode <- getOption("aradR.endpoint_mode", NULL)
  old_key <- Sys.getenv("ARAD_API_KEY", unset = NA_character_)
  on.exit({
    options(aradR.base_url = old_base, aradR.endpoint_mode = old_mode)
    if (is.na(old_key)) Sys.unsetenv("ARAD_API_KEY") else Sys.setenv(ARAD_API_KEY = old_key)
  }, add = TRUE)

  expect_identical(
    arad_use_internal("https://internal.example/api/v1/", api_key = " test-user "),
    "https://internal.example/api/v1"
  )
  expect_identical(getOption("aradR.base_url"), "https://internal.example/api/v1")
  expect_identical(getOption("aradR.endpoint_mode"), "internal")
  expect_identical(Sys.getenv("ARAD_API_KEY"), "test-user")

  req <- httr2::request("https://internal.example")
  req <- aradR:::arad_apply_transport(req)

  expect_identical(req$options$proxy, "")
  expect_identical(req$options$noproxy, "*")
  expect_equal(req$options$httpauth, 4L)
  expect_identical(req$options$userpwd, ":")

  expect_identical(
    arad_use_external(),
    "https://www.cnb.cz/aradb/api/v1"
  )
  expect_null(getOption("aradR.base_url"))
  expect_identical(getOption("aradR.endpoint_mode"), "external")
})

test_that("internal mode requires an explicit configured endpoint", {
  old_url <- Sys.getenv("ARAD_INTERNAL_BASE_URL", unset = NA_character_)
  on.exit({
    if (is.na(old_url)) {
      Sys.unsetenv("ARAD_INTERNAL_BASE_URL")
    } else {
      Sys.setenv(ARAD_INTERNAL_BASE_URL = old_url)
    }
  }, add = TRUE)

  Sys.unsetenv("ARAD_INTERNAL_BASE_URL")
  expect_error(arad_use_internal(), class = "arad_input_error")
})

test_that("pre-response HTTP errors retain useful redacted diagnostics", {
  err <- simpleError(
    "Received HTTP code 303 from proxy after CONNECT for api_key=secret-123"
  )
  msg <- aradR:::arad_request_failure_message(
    "indicators",
    err,
    api_key = "secret-123",
    mode = "external"
  )

  expect_match(msg, "303")
  expect_match(msg, "proxy", ignore.case = TRUE)
  expect_match(msg, "arad_use_internal", fixed = TRUE)
  expect_false(grepl("secret-123", msg, fixed = TRUE))
})
