test_that("dimensions parser accepts live ARAD base_code alias", {
  raw <- make_arad_raw(c(
    "indicator_id;base_code;base_name;dim_code;dim_name;dim_value_code;dim_value_name;dim_rank",
    "A1;BASE1;Prices;D1;Sector;H;Households;1"
  ))

  out <- aradR:::arad_parse_dimensions_response(raw)

  expect_equal(out$indicator_id, "A1")
  expect_equal(out$base_id, "BASE1")
  expect_equal(out$base_name, "Prices")
  expect_equal(out$dim_rank, 1L)
})

test_that("dimensions parser still accepts legacy base_id schema", {
  raw <- make_arad_raw(c(
    "indicator_id;base_id;base_name;dim_code;dim_name;dim_value_code;dim_value_name;dim_rank",
    "A1;BASE1;Prices;D1;Sector;H;Households;1"
  ))

  out <- aradR:::arad_parse_dimensions_response(raw)

  expect_equal(out$base_id, "BASE1")
})
