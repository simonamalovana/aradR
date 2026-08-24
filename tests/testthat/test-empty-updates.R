test_that("empty updates response yields an empty typed result", {
  csv <- "indicator_id;snapshot_id;update_date;data_from;data_to"
  updates <- aradR:::arad_parse_updates_response(charToRaw(csv), encoding = "UTF-8")

  expect_equal(nrow(updates), 0L)
  expect_s3_class(updates$data_from, "Date")
  expect_s3_class(updates$update_date, "POSIXct")
})
