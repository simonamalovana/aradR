#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(aradR))

out_dir <- "ux-results"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

write_csv <- function(x, path) {
  utils::write.csv(x, file.path(out_dir, path), row.names = FALSE, na = "")
}

safe_value <- function(expr) {
  tryCatch(
    list(ok = TRUE, value = expr, error = NA_character_),
    error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e))
  )
}

selector_args <- function(scenario) {
  if (identical(scenario$scope_type, "set")) {
    list(set_id = scenario$scope_id)
  } else if (identical(scenario$scope_type, "base")) {
    list(base_id = scenario$scope_id)
  } else {
    stop("Unsupported scope type: ", scenario$scope_type)
  }
}

scenarios <- list(
  list(
    name = "balance_of_payments",
    scope_type = "base",
    scope_id = "MBOP",
    attempts = list(
      list(term = "běžný účet", lang = "cs"),
      list(term = "bilance", lang = "cs"),
      list(term = "current account", lang = "en"),
      list(term = "balance", lang = "en")
    )
  ),
  list(
    name = "financial_accounts_households",
    scope_type = "set",
    scope_id = "1032",
    attempts = list(
      list(term = "domácnosti", lang = "cs"),
      list(term = "aktiva", lang = "cs"),
      list(term = "households", lang = "en"),
      list(term = "assets", lang = "en")
    )
  ),
  list(
    name = "state_budget_tax",
    scope_type = "set",
    scope_id = "1115",
    attempts = list(
      list(term = "daň", lang = "cs"),
      list(term = "příjmy", lang = "cs"),
      list(term = "tax", lang = "en"),
      list(term = "revenue", lang = "en")
    )
  )
)

# Explicitly exercise browsing once, including availability metadata.
catalog_result <- safe_value(do.call(
  arad_catalog,
  c(
    list(lang = "cs", cache = "session"),
    selector_args(scenarios[[1]])
  )
))

if (catalog_result$ok) {
  catalog <- catalog_result$value
  write_csv(utils::head(catalog, 25L), "catalog-MBOP-sample.csv")
  catalog_summary <- data.frame(
    scope_type = "base",
    scope_id = "MBOP",
    n_indicators = nrow(catalog),
    has_path = "path" %in% names(catalog),
    has_availability = all(c("data_from", "data_to", "last_update") %in% names(catalog)),
    status = if (nrow(catalog) > 0L) "pass" else "fail",
    error = NA_character_,
    stringsAsFactors = FALSE
  )
} else {
  catalog_summary <- data.frame(
    scope_type = "base",
    scope_id = "MBOP",
    n_indicators = NA_integer_,
    has_path = FALSE,
    has_availability = FALSE,
    status = "fail",
    error = catalog_result$error,
    stringsAsFactors = FALSE
  )
}
write_csv(catalog_summary, "catalog-summary.csv")

attempt_rows <- list()
scenario_rows <- list()
selected_summaries <- list()

for (scenario in scenarios) {
  selected_hits <- NULL
  selected_term <- NA_character_
  selected_lang <- NA_character_

  for (attempt in scenario$attempts) {
    result <- safe_value(do.call(
      arad_find,
      c(
        list(
          term = attempt$term,
          lang = attempt$lang,
          details = TRUE,
          cache = "session"
        ),
        selector_args(scenario)
      )
    ))

    hit_count <- if (result$ok) nrow(result$value) else NA_integer_
    attempt_rows[[length(attempt_rows) + 1L]] <- data.frame(
      scenario = scenario$name,
      scope_type = scenario$scope_type,
      scope_id = scenario$scope_id,
      term = attempt$term,
      lang = attempt$lang,
      hits = hit_count,
      status = if (result$ok) "ok" else "error",
      error = result$error,
      stringsAsFactors = FALSE
    )

    if (result$ok && nrow(result$value) > 0L) {
      selected_hits <- result$value
      selected_term <- attempt$term
      selected_lang <- attempt$lang
      break
    }
  }

  if (is.null(selected_hits)) {
    scenario_rows[[length(scenario_rows) + 1L]] <- data.frame(
      scenario = scenario$name,
      scope_type = scenario$scope_type,
      scope_id = scenario$scope_id,
      selected_term = selected_term,
      lang = selected_lang,
      n_hits = 0L,
      indicator_id = NA_character_,
      indicator_name = NA_character_,
      frequency_code = NA_character_,
      data_from = as.Date(NA),
      data_to = as.Date(NA),
      snapshot_contexts = NA_integer_,
      retrieved_rows = NA_integer_,
      wide_columns = NA_integer_,
      status = "fail",
      error = "No human-readable search term returned a candidate.",
      stringsAsFactors = FALSE
    )
    next
  }

  write_csv(utils::head(selected_hits, 20L), paste0("hits-", scenario$name, ".csv"))

  candidates <- selected_hits[
    !is.na(selected_hits$data_from) & !is.na(selected_hits$data_to),
    , drop = FALSE
  ]
  if (nrow(candidates) == 0L) {
    candidates <- selected_hits
  }
  if ("snapshot_contexts" %in% names(candidates)) {
    ordinary <- candidates[candidates$snapshot_contexts == 1L, , drop = FALSE]
    if (nrow(ordinary) > 0L) candidates <- ordinary
  }

  candidate <- candidates[1L, , drop = FALSE]
  id <- candidate$indicator_id[[1L]]

  info_result <- safe_value(arad_info(
    indicator_ids = id,
    lang = selected_lang,
    cache = "session"
  ))

  if (!info_result$ok || nrow(info_result$value$summary) == 0L) {
    scenario_rows[[length(scenario_rows) + 1L]] <- data.frame(
      scenario = scenario$name,
      scope_type = scenario$scope_type,
      scope_id = scenario$scope_id,
      selected_term = selected_term,
      lang = selected_lang,
      n_hits = nrow(selected_hits),
      indicator_id = id,
      indicator_name = candidate$indicator_name[[1L]],
      frequency_code = candidate$frequency_code[[1L]],
      data_from = candidate$data_from[[1L]],
      data_to = candidate$data_to[[1L]],
      snapshot_contexts = candidate$snapshot_contexts[[1L]],
      retrieved_rows = NA_integer_,
      wide_columns = NA_integer_,
      status = "fail",
      error = if (info_result$ok) "arad_info() returned no summary row." else info_result$error,
      stringsAsFactors = FALSE
    )
    next
  }

  summary <- info_result$value$summary[1L, , drop = FALSE]
  selected_summaries[[length(selected_summaries) + 1L]] <- cbind(
    data.frame(scenario = scenario$name, stringsAsFactors = FALSE),
    summary
  )

  data_from <- summary$data_from[[1L]]
  data_to <- summary$data_to[[1L]]
  if (is.na(data_from) || is.na(data_to)) {
    scenario_rows[[length(scenario_rows) + 1L]] <- data.frame(
      scenario = scenario$name,
      scope_type = scenario$scope_type,
      scope_id = scenario$scope_id,
      selected_term = selected_term,
      lang = selected_lang,
      n_hits = nrow(selected_hits),
      indicator_id = id,
      indicator_name = summary$indicator_name[[1L]],
      frequency_code = summary$frequency_code[[1L]],
      data_from = data_from,
      data_to = data_to,
      snapshot_contexts = summary$snapshot_contexts[[1L]],
      retrieved_rows = NA_integer_,
      wide_columns = NA_integer_,
      status = "fail",
      error = "Selected series has no usable availability boundaries.",
      stringsAsFactors = FALSE
    )
    next
  }

  request_from <- max(data_from, data_to - 730L)
  data_result <- safe_value(arad_get(
    indicator_ids = id,
    from = request_from,
    to = data_to,
    cache = "session"
  ))

  if (!data_result$ok) {
    scenario_rows[[length(scenario_rows) + 1L]] <- data.frame(
      scenario = scenario$name,
      scope_type = scenario$scope_type,
      scope_id = scenario$scope_id,
      selected_term = selected_term,
      lang = selected_lang,
      n_hits = nrow(selected_hits),
      indicator_id = id,
      indicator_name = summary$indicator_name[[1L]],
      frequency_code = summary$frequency_code[[1L]],
      data_from = data_from,
      data_to = data_to,
      snapshot_contexts = summary$snapshot_contexts[[1L]],
      retrieved_rows = NA_integer_,
      wide_columns = NA_integer_,
      status = "fail",
      error = data_result$error,
      stringsAsFactors = FALSE
    )
    next
  }

  x <- data_result$value
  wide_result <- safe_value(arad_wide(x))
  pass <- nrow(x) > 0L && wide_result$ok && nrow(wide_result$value) > 0L && ncol(wide_result$value) >= 2L

  scenario_rows[[length(scenario_rows) + 1L]] <- data.frame(
    scenario = scenario$name,
    scope_type = scenario$scope_type,
    scope_id = scenario$scope_id,
    selected_term = selected_term,
    lang = selected_lang,
    n_hits = nrow(selected_hits),
    indicator_id = id,
    indicator_name = summary$indicator_name[[1L]],
    frequency_code = summary$frequency_code[[1L]],
    data_from = data_from,
    data_to = data_to,
    snapshot_contexts = summary$snapshot_contexts[[1L]],
    retrieved_rows = nrow(x),
    wide_columns = if (wide_result$ok) ncol(wide_result$value) else NA_integer_,
    status = if (pass) "pass" else "fail",
    error = if (pass) NA_character_ else if (!wide_result$ok) wide_result$error else "Retrieval or reshape returned no usable observations.",
    stringsAsFactors = FALSE
  )
}

attempts <- do.call(rbind, attempt_rows)
scenarios_out <- do.call(rbind, scenario_rows)
write_csv(attempts, "search-attempts.csv")
write_csv(scenarios_out, "scenario-results.csv")
if (length(selected_summaries) > 0L) {
  write_csv(do.call(rbind, selected_summaries), "selected-series.csv")
}

capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))

report <- c(
  "# aradR 0.2.0 live UX acceptance",
  "",
  sprintf("Catalogue browse: %s (%s indicators)", catalog_summary$status, catalog_summary$n_indicators),
  "",
  "## Scenarios"
)
for (i in seq_len(nrow(scenarios_out))) {
  row <- scenarios_out[i, ]
  report <- c(
    report,
    sprintf(
      "- %s: %s; query='%s' (%s); hits=%s; selected=%s (%s); rows=%s; wide_cols=%s%s",
      row$scenario,
      toupper(row$status),
      row$selected_term,
      row$lang,
      row$n_hits,
      row$indicator_id,
      row$indicator_name,
      row$retrieved_rows,
      row$wide_columns,
      if (is.na(row$error)) "" else paste0("; error=", row$error)
    )
  )
}
writeLines(report, file.path(out_dir, "report.md"))

print(scenarios_out)

if (!identical(catalog_summary$status[[1L]], "pass") || any(scenarios_out$status != "pass")) {
  stop("Live UX acceptance failed. Inspect ux-results artifacts.")
}
