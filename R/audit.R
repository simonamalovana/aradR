arad_data_key <- function(data) {
  snapshot <- ifelse(is.na(data$snapshot_id), "<NA>", data$snapshot_id)
  paste(data$indicator_id, snapshot, format(data$period, "%Y%m%d"), sep = "\r")
}

arad_compare_data <- function(reference, candidate, tolerance = 0) {
  tolerance <- as.numeric(tolerance)
  if (length(tolerance) != 1L || is.na(tolerance) || tolerance < 0) {
    arad_abort("`tolerance` must be a non-negative number.", "arad_input_error")
  }

  reference <- arad_sort_data(reference)
  candidate <- arad_sort_data(candidate)
  reference_key <- arad_data_key(reference)
  candidate_key <- arad_data_key(candidate)

  missing_in_candidate <- setdiff(reference_key, candidate_key)
  extra_in_candidate <- setdiff(candidate_key, reference_key)

  if (length(missing_in_candidate) > 0L || length(extra_in_candidate) > 0L) {
    return(list(
      ok = FALSE,
      reason = "key_mismatch",
      n_reference = nrow(reference),
      n_candidate = nrow(candidate),
      missing_keys = length(missing_in_candidate),
      extra_keys = length(extra_in_candidate),
      na_mismatches = NA_integer_,
      value_mismatches = NA_integer_,
      max_abs_diff = NA_real_
    ))
  }

  if (length(reference_key) == 0L) {
    return(list(
      ok = TRUE,
      reason = "match",
      n_reference = 0L,
      n_candidate = 0L,
      missing_keys = 0L,
      extra_keys = 0L,
      na_mismatches = 0L,
      value_mismatches = 0L,
      max_abs_diff = 0
    ))
  }

  candidate_index <- match(reference_key, candidate_key)
  ref_value <- reference$value
  cand_value <- candidate$value[candidate_index]

  na_mismatch <- xor(is.na(ref_value), is.na(cand_value))
  comparable <- !is.na(ref_value) & !is.na(cand_value)
  diff <- abs(ref_value[comparable] - cand_value[comparable])
  value_mismatch <- if (length(diff) == 0L) logical() else diff > tolerance
  max_abs_diff <- if (length(diff) == 0L) 0 else max(diff)

  list(
    ok = !any(na_mismatch) && !any(value_mismatch),
    reason = if (any(na_mismatch)) "na_mismatch" else if (any(value_mismatch)) "value_mismatch" else "match",
    n_reference = nrow(reference),
    n_candidate = nrow(candidate),
    missing_keys = 0L,
    extra_keys = 0L,
    na_mismatches = sum(na_mismatch),
    value_mismatches = sum(value_mismatch),
    max_abs_diff = max_abs_diff
  )
}

arad_history_band <- function(data_from, data_to) {
  days <- as.numeric(data_to - data_from)
  cut(
    days,
    breaks = c(-Inf, 365 * 5, 365 * 15, Inf),
    labels = c("short", "medium", "long"),
    right = FALSE
  )
}

arad_audit_sample <- function(indicators,
                              updates,
                              sample_per_stratum = 2L,
                              max_series = 24L,
                              seed = 1L) {
  sample_per_stratum <- as.integer(sample_per_stratum)
  max_series <- as.integer(max_series)
  if (sample_per_stratum < 1L || max_series < 1L) {
    arad_abort("Audit sample sizes must be positive integers.", "arad_input_error")
  }

  usable <- updates[!is.na(updates$data_from) & !is.na(updates$data_to), , drop = FALSE]
  if (nrow(usable) == 0L) {
    return(tibble::tibble())
  }

  groups <- split(usable, usable$indicator_id)
  bounds <- lapply(groups, function(x) {
    tibble::tibble(
      indicator_id = x$indicator_id[[1L]],
      data_from = min(x$data_from),
      data_to = max(x$data_to)
    )
  })
  bounds <- tibble::as_tibble(do.call(rbind, bounds))

  idx <- match(bounds$indicator_id, indicators$indicator_id)
  bounds$frequency_code <- indicators$frequency_code[idx]
  bounds$history_band <- as.character(arad_history_band(bounds$data_from, bounds$data_to))
  bounds <- bounds[!is.na(bounds$frequency_code), , drop = FALSE]
  if (nrow(bounds) == 0L) return(bounds)

  stratum <- paste(bounds$frequency_code, bounds$history_band, sep = "::")
  split_rows <- split(seq_len(nrow(bounds)), stratum)
  set.seed(seed)
  selected <- unlist(lapply(split_rows, function(rows) {
    if (length(rows) <= sample_per_stratum) {
      rows
    } else {
      sample(rows, sample_per_stratum)
    }
  }), use.names = FALSE)
  selected <- unique(selected)
  if (length(selected) > max_series) {
    selected <- sample(selected, max_series)
  }
  bounds[selected, , drop = FALSE]
}
