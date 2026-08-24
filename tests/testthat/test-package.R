test_that("package metadata is internally consistent", {
  expect_identical(as.character(utils::packageVersion("aradR")), "0.1.0")
})
