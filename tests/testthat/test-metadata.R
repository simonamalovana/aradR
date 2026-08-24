test_that("metadata endpoints use documented schemas", {
  calls <- new.env(parent = emptyenv())
  calls$endpoints <- character()
  calls$queries <- list()

  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = function(endpoint, query, api_key, base_url) {
    calls$endpoints <- c(calls$endpoints, endpoint)
    calls$queries[[length(calls$queries) + 1L]] <- query
    switch(
      endpoint,
      indicators = make_arad_raw(c(
        "indicator_id;indicator_name;frequency_code;frequency_name;unit_mult_code;unit_mult_name;unit",
        "A1;Inflation;M;Monthly;0;units;%",
        "A2;GDP;Q;Quarterly;6;millions;CZK"
      )),
      `indicators-dims` = make_arad_raw(c(
        "indicator_id;base_id;base_name;dim_code;dim_name;dim_value_code;dim_value_name;dim_rank",
        "A1;BASE1;Prices;D1;Sector;H;Households;1"
      )),
      `indicators-tree` = make_arad_raw(c(
        "indicator_id;path",
        "A1;ARAD/Statistics/Prices"
      )),
      snapshots = make_arad_raw(c(
        "snapshot_id;snapshot_name",
        "25;Baseline"
      )),
      stop("unexpected endpoint")
    )
  })

  indicators <- arad_indicators(set_id = "1058", lang = "en", api_key = "key")
  expect_equal(indicators$indicator_id, c("A1", "A2"))
  expect_equal(indicators$unit_mult_code, c(0L, 6L))
  expect_equal(calls$queries[[1]]$set_id, "1058")
  expect_equal(calls$queries[[1]]$lang, "en")

  dimensions <- arad_dimensions(indicator_ids = "A1", api_key = "key")
  expect_equal(dimensions$dim_rank, 1L)
  expect_equal(dimensions$base_id, "BASE1")

  tree <- arad_tree(indicator_ids = "A1", api_key = "key")
  expect_equal(tree$path, "ARAD/Statistics/Prices")

  snapshots <- arad_snapshots(lang = "en", api_key = "key")
  expect_equal(snapshots$snapshot_id, "25")
  expect_false("indicator_id_list" %in% names(calls$queries[[4]]))
  expect_equal(calls$endpoints, c("indicators", "indicators-dims", "indicators-tree", "snapshots"))
})

test_that("arad_search filters names, IDs and frequencies", {
  old <- getOption("aradR.request_fn")
  on.exit(options(aradR.request_fn = old), add = TRUE)
  options(aradR.request_fn = function(endpoint, query, api_key, base_url) {
    expect_equal(endpoint, "indicators")
    make_arad_raw(c(
      "indicator_id;indicator_name;frequency_code;frequency_name;unit_mult_code;unit_mult_name;unit",
      "CPI_M;Consumer prices;M;Monthly;0;units;index",
      "GDP_Q;Gross domestic product;Q;Quarterly;6;millions;CZK",
      "CPI_Q;Consumer prices quarterly;Q;Quarterly;0;units;index"
    ))
  })

  out <- arad_search("consumer", set_id = 1, frequency = "Q", api_key = "key")
  expect_equal(out$indicator_id, "CPI_Q")

  by_id <- arad_search("^GDP", set_id = 1, regex = TRUE, api_key = "key")
  expect_equal(by_id$indicator_id, "GDP_Q")
})

test_that("metadata parsers reject malformed documented fields", {
  bad <- make_arad_raw(c(
    "indicator_id;indicator_name;frequency_code;frequency_name;unit_mult_code;unit_mult_name;unit",
    "A1;Test;M;Monthly;not-an-integer;units;%"
  ))
  expect_error(
    aradR:::arad_parse_indicators_response(bad),
    class = "arad_parse_error"
  )

  bad_tree <- make_arad_raw(c("indicator_id;path", "A1;"))
  expect_error(
    aradR:::arad_parse_tree_response(bad_tree),
    class = "arad_integrity_error"
  )
})
