test_that("auto strategy retrieves explicit ranges in bounded chunks", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L

  fake_request <- function(endpoint, query, api_key, base_url) {
    expect_identical(endpoint, "data")
    calls$n <- calls$n + 1L

    from <- as.Date(query$period_from, format = "%Y%m%d")
    to <- as.Date(query$period_to, format = "%Y%m%d")
    dates <- seq(from, to, by = "day")
    values <- as.integer(dates - as.Date("2020-01-01")) + 1L

    rows <- paste(
      "X1",
      "",
      format(dates, "%Y%m%d"),
      values,
      sep = ";"
    )
    charToRaw(paste(c("indicator_id;snapshot_id;period;value", rows), collapse = "\r\n"))
  }

  old_request <- getOption("aradR.request_fn")
  options(aradR.request_fn = fake_request)
  on.exit(options(aradR.request_fn = old_request), add = TRUE)

  data <- arad_get(
    indicator_ids = "X1",
    from = "2020-01-01",
    to = "2020-01-05",
    chunk_days = 2L,
    api_key = "test-key",
    encoding = "UTF-8"
  )

  expect_equal(calls$n, 3L)
  expect_equal(nrow(data), 5L)
  expect_equal(data$value, 1:5)

  diagnostics <- attr(data, "arad_diagnostics")
  expect_identical(diagnostics$strategy, "auto-chunked")
  expect_equal(diagnostics$data_requests, 3L)
  expect_equal(diagnostics$updates_requests, 0L)
})

test_that("direct strategy makes one request", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L

  fake_request <- function(endpoint, query, api_key, base_url) {
    calls$n <- calls$n + 1L
    charToRaw(paste(
      c(
        "indicator_id;snapshot_id;period;value",
        "X1;;20200101;1"
      ),
      collapse = "\r\n"
    ))
  }

  old_request <- getOption("aradR.request_fn")
  options(aradR.request_fn = fake_request)
  on.exit(options(aradR.request_fn = old_request), add = TRUE)

  data <- arad_get(
    indicator_ids = "X1",
    from = "2020-01-01",
    to = "2020-01-05",
    strategy = "direct",
    api_key = "test-key",
    encoding = "UTF-8"
  )

  expect_equal(calls$n, 1L)
  expect_identical(attr(data, "arad_diagnostics")$strategy, "direct")
})

test_that("auto strategy resolves omitted boundaries through updates", {
  calls <- new.env(parent = emptyenv())
  calls$updates <- 0L
  calls$data <- 0L

  fake_request <- function(endpoint, query, api_key, base_url) {
    if (identical(endpoint, "updates")) {
      calls$updates <- calls$updates + 1L
      return(charToRaw(paste(
        c(
          "indicator_id;snapshot_id;update_date;data_from;data_to",
          "X1;;20260824153045;20200101;20200103"
        ),
        collapse = "\r\n"
      )))
    }

    calls$data <- calls$data + 1L
    from <- as.Date(query$period_from, format = "%Y%m%d")
    to <- as.Date(query$period_to, format = "%Y%m%d")
    dates <- seq(from, to, by = "day")
    rows <- paste("X1", "", format(dates, "%Y%m%d"), seq_along(dates), sep = ";")
    charToRaw(paste(c("indicator_id;snapshot_id;period;value", rows), collapse = "\r\n"))
  }

  old_request <- getOption("aradR.request_fn")
  options(aradR.request_fn = fake_request)
  on.exit(options(aradR.request_fn = old_request), add = TRUE)

  data <- arad_get(
    indicator_ids = "X1",
    chunk_days = 2L,
    api_key = "test-key",
    encoding = "UTF-8"
  )

  expect_equal(calls$updates, 1L)
  expect_equal(calls$data, 2L)
  expect_equal(nrow(data), 3L)
  expect_identical(attr(data, "arad_diagnostics")$updates_requests, 1L)
})

test_that("identical observations repeated across adjacent chunks are collapsed", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L

  fake_request <- function(endpoint, query, api_key, base_url) {
    calls$n <- calls$n + 1L
    rows <- if (calls$n == 1L) {
      c("X1;;20200131;10", "X1;;20200229;20")
    } else {
      c("X1;;20200229;20", "X1;;20200331;30")
    }
    charToRaw(paste(c("indicator_id;snapshot_id;period;value", rows), collapse = "\r\n"))
  }

  old_request <- getOption("aradR.request_fn")
  options(aradR.request_fn = fake_request)
  on.exit(options(aradR.request_fn = old_request), add = TRUE)

  data <- arad_get(
    indicator_ids = "X1",
    from = "2020-01-01",
    to = "2020-03-31",
    chunk_days = 46L,
    api_key = "test-key",
    encoding = "UTF-8"
  )

  expect_equal(calls$n, 2L)
  expect_equal(nrow(data), 3L)
  expect_equal(data$period, as.Date(c("2020-01-31", "2020-02-29", "2020-03-31")))
  expect_equal(data$value, c(10, 20, 30))
})

test_that("conflicting observations repeated across adjacent chunks fail loudly", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L

  fake_request <- function(endpoint, query, api_key, base_url) {
    calls$n <- calls$n + 1L
    rows <- if (calls$n == 1L) {
      c("X1;;20200131;10", "X1;;20200229;20")
    } else {
      c("X1;;20200229;21", "X1;;20200331;30")
    }
    charToRaw(paste(c("indicator_id;snapshot_id;period;value", rows), collapse = "\r\n"))
  }

  old_request <- getOption("aradR.request_fn")
  options(aradR.request_fn = fake_request)
  on.exit(options(aradR.request_fn = old_request), add = TRUE)

  expect_error(
    arad_get(
      indicator_ids = "X1",
      from = "2020-01-01",
      to = "2020-03-31",
      chunk_days = 46L,
      api_key = "test-key",
      encoding = "UTF-8"
    ),
    class = "arad_integrity_error"
  )
})
