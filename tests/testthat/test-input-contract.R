test_that("months_before cannot be mixed with explicit dates", {
  expect_error(
    arad_get(
      indicator_ids = "X1",
      from = "2020-01-01",
      months_before = 12,
      api_key = "test-key",
      strategy = "direct",
      encoding = "UTF-8"
    ),
    class = "arad_input_error"
  )
})

test_that("from cannot be later than to", {
  expect_error(
    arad_get(
      indicator_ids = "X1",
      from = "2020-02-01",
      to = "2020-01-01",
      api_key = "test-key",
      strategy = "direct",
      encoding = "UTF-8"
    ),
    class = "arad_input_error"
  )
})
