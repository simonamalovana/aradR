test_that("session cache avoids duplicate requests", {
  arad_cache_clear("session")
  on.exit(arad_cache_clear("session"), add = TRUE)

  count <- 0L
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = function(endpoint, query, api_key, base_url) {
    count <<- count + 1L
    make_arad_raw(c(
      "indicator_id;indicator_name;frequency_code;frequency_name;unit_mult_code;unit_mult_name;unit",
      "A1;Test;M;Monthly;0;units;%"
    ))
  })

  first <- arad_indicators(set_id = 1, api_key = "key", cache = "session")
  second <- arad_indicators(set_id = 1, api_key = "key", cache = "session")
  expect_equal(count, 1L)
  expect_false(isTRUE(attr(first, "arad_cache_hit")))
  expect_true(isTRUE(attr(second, "arad_cache_hit")))

  arad_cache_clear("session")
  arad_indicators(set_id = 1, api_key = "key", cache = "session")
  expect_equal(count, 2L)
})

test_that("disk cache is persistent within a directory", {
  cache_dir <- tempfile("aradR-cache-")
  on.exit(unlink(cache_dir, recursive = TRUE), add = TRUE)

  count <- 0L
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = function(endpoint, query, api_key, base_url) {
    count <<- count + 1L
    make_arad_raw(c(
      "snapshot_id;snapshot_name",
      "25;Baseline"
    ))
  })

  arad_snapshots(api_key = "key", cache = "disk", cache_dir = cache_dir)
  arad_snapshots(api_key = "key", cache = "disk", cache_dir = cache_dir)
  expect_equal(count, 1L)
  expect_true(length(list.files(cache_dir, pattern = "\\.rds$")) == 1L)

  arad_cache_clear("disk", cache_dir = cache_dir)
  expect_equal(length(list.files(cache_dir, pattern = "\\.rds$")), 0L)
})

test_that("cache keys are separated by API credential", {
  arad_cache_clear("session")
  on.exit(arad_cache_clear("session"), add = TRUE)

  count <- 0L
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = function(endpoint, query, api_key, base_url) {
    count <<- count + 1L
    make_arad_raw(c(
      "snapshot_id;snapshot_name",
      "25;Baseline"
    ))
  })

  arad_snapshots(api_key = "key-one", cache = "session")
  arad_snapshots(api_key = "key-two", cache = "session")
  expect_equal(count, 2L)
})

test_that("invalid cache configuration fails clearly", {
  expect_error(
    arad_snapshots(api_key = "key", cache = "mystery"),
    class = "arad_input_error"
  )
  expect_error(
    arad_snapshots(api_key = "key", cache = "session", cache_max_age = -1),
    class = "arad_input_error"
  )
})
