test_that("legacy workplace HTTP stack remains supported", {
  expect_invisible(
    aradR:::arad_check_http_dependencies(
      httr2_version = "0.2.2",
      curl_version = "5.0.0",
      curl_modify_url_available = FALSE
    )
  )
})

test_that("modern httr2 and curl stack is accepted", {
  expect_invisible(
    aradR:::arad_check_http_dependencies(
      httr2_version = "1.2.1",
      curl_version = "6.4.0",
      curl_modify_url_available = TRUE
    )
  )
})

test_that("modern httr2 with old curl fails with an actionable error", {
  expect_error(
    aradR:::arad_check_http_dependencies(
      httr2_version = "1.2.1",
      curl_version = "5.0.0",
      curl_modify_url_available = FALSE
    ),
    regexp = "httr2 1.2.1 requires curl >= 6.4.0.*loaded curl version is 5.0.0.*restart R",
    class = "arad_dependency_error"
  )
})

test_that("missing curl URL capability is detected even with new version metadata", {
  expect_error(
    aradR:::arad_check_http_dependencies(
      httr2_version = "1.2.1",
      curl_version = "6.4.0",
      curl_modify_url_available = FALSE
    ),
    class = "arad_dependency_error"
  )
})
