test_that("data parser preserves genuine missing values", {
  csv <- paste(
    c(
      "indicator_id;snapshot_id;period;value",
      "X1;;20200101;1.5",
      "X1;;20200102;"
    ),
    collapse = "\r\n"
  )

  data <- aradR:::arad_parse_data_response(charToRaw(csv), encoding = "UTF-8")

  expect_equal(nrow(data), 2L)
  expect_equal(data$value[[1]], 1.5)
  expect_true(is.na(data$value[[2]]))
  expect_s3_class(data$period, "Date")
})

test_that("non-missing invalid numeric values fail loudly", {
  csv <- paste(
    c(
      "indicator_id;snapshot_id;period;value",
      "X1;;20200101;not-a-number"
    ),
    collapse = "\r\n"
  )

  expect_error(
    aradR:::arad_parse_data_response(charToRaw(csv), encoding = "UTF-8"),
    class = "arad_parse_error"
  )
})

test_that("invalid periods and duplicate observation keys fail loudly", {
  bad_date <- paste(
    c(
      "indicator_id;snapshot_id;period;value",
      "X1;;20201340;1"
    ),
    collapse = "\r\n"
  )
  expect_error(
    aradR:::arad_parse_data_response(charToRaw(bad_date), encoding = "UTF-8"),
    class = "arad_parse_error"
  )

  duplicate <- paste(
    c(
      "indicator_id;snapshot_id;period;value",
      "X1;;20200101;1",
      "X1;;20200101;2"
    ),
    collapse = "\r\n"
  )
  expect_error(
    aradR:::arad_parse_data_response(charToRaw(duplicate), encoding = "UTF-8"),
    class = "arad_integrity_error"
  )
})

test_that("updates parser exposes typed date boundaries", {
  csv <- paste(
    c(
      "indicator_id;snapshot_id;update_date;data_from;data_to",
      "X1;;20260824153045;19930131;20260731"
    ),
    collapse = "\r\n"
  )

  updates <- aradR:::arad_parse_updates_response(charToRaw(csv), encoding = "UTF-8")
  expect_identical(updates$data_from[[1]], as.Date("1993-01-31"))
  expect_identical(updates$data_to[[1]], as.Date("2026-07-31"))
  expect_s3_class(updates$update_date, "POSIXct")
})
