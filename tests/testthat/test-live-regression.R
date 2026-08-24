test_that("live long-range retrieval matches a finer chunked reference", {
  skip_if_not(identical(tolower(Sys.getenv("ARADR_RUN_LIVE_TESTS", unset = "false")), "true"))

  indicator <- Sys.getenv("ARADR_REGRESSION_INDICATOR", unset = "")
  from <- Sys.getenv("ARADR_REGRESSION_FROM", unset = "")
  to <- Sys.getenv("ARADR_REGRESSION_TO", unset = "")
  api_key <- Sys.getenv("ARAD_API_KEY", unset = "")

  skip_if(!nzchar(indicator), "Set ARADR_REGRESSION_INDICATOR for live regression tests.")
  skip_if(!nzchar(from), "Set ARADR_REGRESSION_FROM for live regression tests.")
  skip_if(!nzchar(to), "Set ARADR_REGRESSION_TO for live regression tests.")
  skip_if(!nzchar(api_key), "Set ARAD_API_KEY for live regression tests.")

  reference_chunk_days <- suppressWarnings(as.integer(
    Sys.getenv("ARADR_REFERENCE_CHUNK_DAYS", unset = "730")
  ))
  candidate_chunk_days <- suppressWarnings(as.integer(
    Sys.getenv("ARADR_CANDIDATE_CHUNK_DAYS", unset = "3650")
  ))

  reference <- arad_get(
    indicator_ids = indicator,
    from = from,
    to = to,
    strategy = "auto",
    chunk_days = reference_chunk_days,
    api_key = api_key
  )
  candidate <- arad_get(
    indicator_ids = indicator,
    from = from,
    to = to,
    strategy = "auto",
    chunk_days = candidate_chunk_days,
    api_key = api_key
  )

  expect_equal(as.data.frame(candidate), as.data.frame(reference))
})
