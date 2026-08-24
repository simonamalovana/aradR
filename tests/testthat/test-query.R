test_that("exactly one selector is required", {
  expect_error(
    aradR:::arad_selector(),
    class = "arad_selector_error"
  )
  expect_error(
    aradR:::arad_selector(indicator_ids = "X1", set_id = "1058"),
    class = "arad_selector_error"
  )

  selector <- aradR:::arad_selector(indicator_ids = c("X1", "X2", "X1"))
  expect_identical(selector$param, "indicator_id_list")
  expect_identical(selector$value, "X1,X2")
})

test_that("dates accept Date and documented string forms", {
  expect_identical(
    aradR:::arad_date("20200131", "from"),
    as.Date("2020-01-31")
  )
  expect_identical(
    aradR:::arad_date("2020-01-31", "from"),
    as.Date("2020-01-31")
  )
  expect_error(
    aradR:::arad_date("31/01/2020", "from"),
    class = "arad_input_error"
  )
})

test_that("chunking is inclusive, contiguous, and non-overlapping", {
  chunks <- aradR:::arad_make_chunks(
    as.Date("2020-01-01"),
    as.Date("2020-01-05"),
    chunk_days = 2L
  )

  expect_length(chunks, 3L)
  expect_identical(chunks[[1]]$from, as.Date("2020-01-01"))
  expect_identical(chunks[[1]]$to, as.Date("2020-01-02"))
  expect_identical(chunks[[2]]$from, as.Date("2020-01-03"))
  expect_identical(chunks[[2]]$to, as.Date("2020-01-04"))
  expect_identical(chunks[[3]]$from, as.Date("2020-01-05"))
  expect_identical(chunks[[3]]$to, as.Date("2020-01-05"))
})
