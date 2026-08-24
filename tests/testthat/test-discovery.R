discovery_stub <- function(endpoint, query, api_key, base_url) {
  rows <- switch(
    endpoint,
    indicators = c(
      "indicator_id;indicator_name;frequency_code;frequency_name;unit_mult_code;unit_mult_name;unit",
      "A1;Consumer prices;M;Monthly;0;units;index",
      "A2;Policy rate;D;Daily;0;units;%"
    ),
    `indicators-tree` = c(
      "indicator_id;path",
      "A1;ARAD/Statistics/Prices",
      "A2;ARAD/Monetary policy/Interest rates"
    ),
    `indicators-dims` = c(
      "indicator_id;base_id;base_name;dim_code;dim_name;dim_value_code;dim_value_name;dim_rank",
      "A1;PRICES;Prices;SEC;Sector;HH;Households;1",
      "A2;RATES;Interest rates;TYPE;Rate type;POL;Policy rate;1"
    ),
    updates = c(
      "indicator_id;snapshot_id;update_date;data_from;data_to",
      "A1;;20260824120000;20000101;20260701",
      "A1;S1;20260823120000;20050101;20260601",
      "A2;;20260824130000;19950101;20260824"
    ),
    stop("unexpected endpoint")
  )

  if (!is.null(query$indicator_id_list)) {
    ids <- strsplit(query$indicator_id_list, ",", fixed = TRUE)[[1L]]
    row_ids <- sub(";.*$", "", rows[-1L])
    rows <- c(rows[[1L]], rows[-1L][row_ids %in% ids])
  }

  make_arad_raw(rows)
}

test_that("arad_catalog builds one-row-per-indicator discovery metadata", {
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = discovery_stub)

  out <- arad_catalog(set_id = 1, lang = "en", api_key = "key")

  expect_equal(out$indicator_id, c("A1", "A2"))
  expect_equal(out$path, c(
    "ARAD/Statistics/Prices",
    "ARAD/Monetary policy/Interest rates"
  ))
  expect_equal(out$data_from, as.Date(c("2000-01-01", "1995-01-01")))
  expect_equal(out$data_to, as.Date(c("2026-07-01", "2026-08-24")))
  expect_equal(out$snapshot_contexts, c(2L, 1L))
  expect_s3_class(out$last_update, "POSIXct")
})

test_that("arad_find searches hierarchy and dimensions without indicator IDs", {
  calls <- new.env(parent = emptyenv())
  calls$updates_query <- NULL

  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = function(endpoint, query, api_key, base_url) {
    if (identical(endpoint, "updates")) {
      calls$updates_query <- query
    }
    discovery_stub(endpoint, query, api_key, base_url)
  })

  path_hit <- arad_find("monetary", set_id = 1, api_key = "key")
  expect_equal(path_hit$indicator_id, "A2")
  expect_equal(path_hit$frequency_code, "D")
  expect_equal(path_hit$data_from, as.Date("1995-01-01"))
  expect_equal(calls$updates_query$indicator_id_list, "A2")

  dimension_hit <- arad_find(
    "households", set_id = 1, details = FALSE, api_key = "key"
  )
  expect_equal(dimension_hit$indicator_id, "A1")
  expect_true("path" %in% names(dimension_hit))
  expect_false("data_from" %in% names(dimension_hit))
})

test_that("arad_find supports frequency filtering and empty detailed results", {
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = discovery_stub)

  daily <- arad_find("rate", set_id = 1, frequency = "D", api_key = "key")
  expect_equal(daily$indicator_id, "A2")

  none <- arad_find("does-not-exist", set_id = 1, api_key = "key")
  expect_equal(nrow(none), 0L)
  expect_true(all(c("path", "data_from", "data_to", "last_update", "snapshot_contexts") %in% names(none)))
})

test_that("arad_info returns summary dimensions and raw update rows", {
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = discovery_stub)

  info <- arad_info("A1", api_key = "key")

  expect_equal(names(info), c("summary", "dimensions", "updates"))
  expect_equal(info$summary$indicator_id, "A1")
  expect_equal(info$summary$snapshot_contexts, 2L)
  expect_equal(info$dimensions$dim_value_name, "Households")
  expect_equal(nrow(info$updates), 2L)
})

test_that("discovery helpers validate user-facing flags", {
  expect_error(
    arad_catalog(set_id = 1, include_path = NA, api_key = "key"),
    class = "arad_input_error"
  )
  expect_error(
    arad_find("x", set_id = 1, details = "yes", api_key = "key"),
    class = "arad_input_error"
  )
  expect_error(
    arad_info(character(), api_key = "key"),
    class = "arad_input_error"
  )
})
