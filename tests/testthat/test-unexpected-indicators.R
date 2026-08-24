test_that("unexpected indicator IDs fail integrity validation", {
  data <- tibble::tibble(
    indicator_id = "Y1",
    snapshot_id = NA_character_,
    period = as.Date("2020-01-01"),
    value = 1
  )
  selector <- aradR:::arad_selector(indicator_ids = "X1")

  expect_error(
    aradR:::arad_validate_expected_indicators(data, selector),
    class = "arad_integrity_error"
  )
})
