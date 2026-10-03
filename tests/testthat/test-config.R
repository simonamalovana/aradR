test_that("public ARAD is the default endpoint", {
  expect_identical(
    aradR:::arad_base_url(),
    "https://www.cnb.cz/aradb/api/v1"
  )
})

test_that("legacy endpoint option cannot redirect the default endpoint", {
  old_base <- getOption("aradR.base_url", NULL)
  on.exit(options(aradR.base_url = old_base), add = TRUE)

  options(aradR.base_url = "https://internal.example/api/v1")

  expect_identical(
    aradR:::arad_base_url(),
    "https://www.cnb.cz/aradb/api/v1"
  )
})

test_that("explicit base URLs remain validated for tests and advanced calls", {
  expect_identical(
    aradR:::arad_base_url("https://example.org/api/v1/"),
    "https://example.org/api/v1"
  )
  expect_error(aradR:::arad_base_url(""), class = "arad_input_error")
})

test_that("pre-response HTTP errors retain useful redacted diagnostics", {
  err <- simpleError(
    "Received HTTP code 303 from proxy after CONNECT for api_key=secret-123"
  )
  msg <- aradR:::arad_request_failure_message(
    "indicators",
    err,
    api_key = "secret-123"
  )

  expect_match(msg, "303")
  expect_true(grepl("proxy", msg, ignore.case = TRUE))
  expect_true(grepl("public ARAD API", msg, fixed = TRUE))
  expect_false(grepl("secret-123", msg, fixed = TRUE))
  expect_false(grepl("arad_use_internal", msg, fixed = TRUE))
})
