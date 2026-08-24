test_that("API keys are required and explicit keys are accepted", {
  old <- Sys.getenv("ARAD_API_KEY", unset = NA_character_)
  Sys.unsetenv("ARAD_API_KEY")
  on.exit({
    if (is.na(old)) Sys.unsetenv("ARAD_API_KEY") else Sys.setenv(ARAD_API_KEY = old)
  }, add = TRUE)

  expect_error(aradR:::arad_api_key(), class = "arad_auth_error")
  expect_identical(aradR:::arad_api_key(" test-key "), "test-key")
})

test_that("redaction never returns a secret", {
  text <- "request failed for api_key=secret-123"
  redacted <- aradR:::arad_redact(text, "secret-123")
  expect_false(grepl("secret-123", redacted, fixed = TRUE))
  expect_true(grepl("<redacted>", redacted, fixed = TRUE))
})
