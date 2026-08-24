test_that("genuine missing values are never dropped", {
  csv <- paste(
    c(
      "indicator_id;snapshot_id;period;value",
      "X1;;20200101;1",
      "X1;;20200102;NA",
      "X1;;20200103;3"
    ),
    collapse = "\r\n"
  )

  data <- aradR:::arad_parse_data_response(charToRaw(csv), encoding = "UTF-8")
  expect_equal(nrow(data), 3L)
  expect_true(is.na(data$value[[2]]))
})
