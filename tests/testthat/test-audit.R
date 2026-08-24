test_that("audit comparison detects keys, NA and values", {
  reference <- tibble::tibble(
    indicator_id = c("A", "A", "A"),
    snapshot_id = c(NA_character_, NA_character_, NA_character_),
    period = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01")),
    value = c(1, NA, 3)
  )

  same <- reference[c(3, 1, 2), ]
  expect_true(aradR:::arad_compare_data(reference, same)$ok)

  missing_key <- reference[-1, ]
  expect_equal(aradR:::arad_compare_data(reference, missing_key)$reason, "key_mismatch")

  na_change <- reference
  na_change$value[2] <- 2
  comparison <- aradR:::arad_compare_data(reference, na_change)
  expect_false(comparison$ok)
  expect_equal(comparison$reason, "na_mismatch")
  expect_equal(comparison$na_mismatches, 1L)

  value_change <- reference
  value_change$value[1] <- 1.5
  comparison <- aradR:::arad_compare_data(reference, value_change)
  expect_equal(comparison$reason, "value_mismatch")
  expect_equal(comparison$value_mismatches, 1L)

  expect_true(aradR:::arad_compare_data(reference, value_change, tolerance = 0.5)$ok)
})

test_that("audit sampling is stratified and bounded", {
  indicators <- tibble::tibble(
    indicator_id = paste0("I", 1:8),
    frequency_code = c("M", "M", "M", "M", "Q", "Q", "Q", "Q")
  )
  updates <- tibble::tibble(
    indicator_id = paste0("I", 1:8),
    snapshot_id = NA_character_,
    update_date = as.POSIXct(rep("2026-01-01", 8), tz = "UTC"),
    data_from = as.Date(c(
      "2024-01-01", "2018-01-01", "1990-01-01", "1991-01-01",
      "2024-01-01", "2018-01-01", "1990-01-01", "1991-01-01"
    )),
    data_to = as.Date(rep("2026-01-01", 8))
  )

  sample <- aradR:::arad_audit_sample(
    indicators,
    updates,
    sample_per_stratum = 1,
    max_series = 6,
    seed = 42
  )
  expect_lte(nrow(sample), 6L)
  expect_true(all(sample$frequency_code %in% c("M", "Q")))
  expect_true(all(sample$history_band %in% c("short", "medium", "long")))

  again <- aradR:::arad_audit_sample(
    indicators,
    updates,
    sample_per_stratum = 1,
    max_series = 6,
    seed = 42
  )
  expect_equal(sample$indicator_id, again$indicator_id)
})

test_that("singleton audit strata always preserve their member", {
  indicators <- tibble::tibble(
    indicator_id = c("I1", "I2", "I3"),
    frequency_code = c("M", "Q", "A")
  )
  updates <- tibble::tibble(
    indicator_id = c("I1", "I2", "I3"),
    snapshot_id = NA_character_,
    update_date = as.POSIXct(rep("2026-01-01", 3), tz = "UTC"),
    data_from = as.Date(rep("2024-01-01", 3)),
    data_to = as.Date(rep("2026-01-01", 3))
  )

  for (seed in seq_len(20L)) {
    sampled <- aradR:::arad_audit_sample(
      indicators,
      updates,
      sample_per_stratum = 1,
      max_series = 3,
      seed = seed
    )
    expect_setequal(sampled$indicator_id, indicators$indicator_id)
  }
})
