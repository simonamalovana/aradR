test_that("arad_wide reshapes ordinary long data", {
  x <- tibble::tibble(
    indicator_id = c("A", "A", "B", "B"),
    snapshot_id = NA_character_,
    period = as.Date(c("2026-01-01", "2026-02-01", "2026-01-01", "2026-02-01")),
    value = c(1, 2, 10, NA_real_)
  )

  out <- arad_wide(x)

  expect_equal(names(out), c("period", "A", "B"))
  expect_equal(out$A, c(1, 2))
  expect_equal(out$B, c(10, NA_real_))
})

test_that("arad_wide fills missing period-series cells with NA", {
  x <- tibble::tibble(
    indicator_id = c("A", "A", "B"),
    period = as.Date(c("2026-01-01", "2026-02-01", "2026-02-01")),
    value = c(1, 2, 20)
  )

  out <- arad_wide(x)

  expect_equal(out$B, c(NA_real_, 20))
})

test_that("arad_wide automatically distinguishes snapshot contexts", {
  x <- tibble::tibble(
    indicator_id = c("A", "A", "A", "A"),
    snapshot_id = c(NA, NA, "S1", "S1"),
    period = as.Date(c("2026-01-01", "2026-02-01", "2026-01-01", "2026-02-01")),
    value = c(1, 2, 11, 12)
  )

  out <- arad_wide(x)

  expect_equal(names(out), c("period", "A__current", "A__S1"))
  expect_equal(out$A__current, c(1, 2))
  expect_equal(out$A__S1, c(11, 12))
})

test_that("arad_wide rejects ambiguous ignored snapshots", {
  x <- tibble::tibble(
    indicator_id = c("A", "A"),
    snapshot_id = c(NA, "S1"),
    period = as.Date(c("2026-01-01", "2026-01-01")),
    value = c(1, 11)
  )

  expect_error(
    arad_wide(x, snapshot = "ignore"),
    class = "arad_integrity_error"
  )
})

test_that("arad_wide preserves retrieval diagnostics", {
  x <- tibble::tibble(
    indicator_id = "A",
    snapshot_id = NA_character_,
    period = as.Date("2026-01-01"),
    value = 1
  )
  attr(x, "arad_diagnostics") <- list(strategy = "auto-single", data_requests = 1L)

  out <- arad_wide(x)

  expect_identical(attr(out, "arad_diagnostics"), attr(x, "arad_diagnostics"))
})

test_that("arad_wide validates its input contract", {
  expect_error(arad_wide(list()), class = "arad_input_error")

  x <- tibble::tibble(
    indicator_id = "A",
    period = as.Date("2026-01-01"),
    value = 1
  )

  expect_error(
    arad_wide(x, snapshot = "include"),
    class = "arad_input_error"
  )
})
