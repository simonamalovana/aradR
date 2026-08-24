#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(aradR))

parse_csv_env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = default)
  out <- trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
  unique(out[nzchar(out)])
}

api_key <- Sys.getenv("ARAD_API_KEY", unset = "")
if (!nzchar(api_key)) stop("ARAD_API_KEY is required for target discovery")

# Respect an explicit target when deliberately supplied. Otherwise discover a
# current higher-frequency target from bounded candidate bases.
explicit <- parse_csv_env("ARADR_FINAL_TARGET_INDICATORS", "")
if (length(explicit) > 0L) {
  message("Using explicit final coverage target: ", paste(explicit, collapse = ", "))
  source("tools/final-coverage-audit.R", chdir = FALSE)
  quit(save = "no", status = 0L)
}

candidate_bases <- parse_csv_env("ARADR_FINAL_TARGET_BASES", "MIRF,SGFSDEF")
if (length(candidate_bases) == 0L) stop("No candidate bases configured for higher-frequency discovery")

output_dir <- Sys.getenv("ARADR_AUDIT_OUTPUT_DIR", unset = "audit-results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

higher_frequency <- function(code) {
  !is.na(code) & nzchar(code) & !(toupper(code) %in% c("M", "Q", "Y", "A"))
}

discovery <- list()
candidates <- list()

for (base_id in candidate_bases) {
  message("Discovering higher-frequency candidates in base ", base_id, " ...")
  metadata <- tryCatch(
    arad_indicators(base_id = base_id, lang = "en", api_key = api_key, cache = "none"),
    error = identity
  )
  updates <- tryCatch(
    arad_updates(base_id = base_id, api_key = api_key, cache = "none"),
    error = identity
  )

  if (inherits(metadata, "error") || inherits(updates, "error")) {
    discovery[[length(discovery) + 1L]] <- data.frame(
      base_id = base_id,
      status = "error",
      detail = paste(
        c(
          if (inherits(metadata, "error")) paste0("metadata: ", conditionMessage(metadata)),
          if (inherits(updates, "error")) paste0("updates: ", conditionMessage(updates))
        ),
        collapse = " | "
      ),
      stringsAsFactors = FALSE
    )
    next
  }

  hf <- metadata[higher_frequency(metadata$frequency_code), , drop = FALSE]
  if (nrow(hf) == 0L) {
    discovery[[length(discovery) + 1L]] <- data.frame(
      base_id = base_id, status = "no_higher_frequency", detail = "No higher-frequency metadata rows",
      stringsAsFactors = FALSE
    )
    next
  }

  current <- updates
  if ("snapshot_id" %in% names(current)) {
    current_no_snapshot <- current[is.na(current$snapshot_id), , drop = FALSE]
    if (nrow(current_no_snapshot) > 0L) current <- current_no_snapshot
  }
  current <- current[!is.na(current$data_from) & !is.na(current$data_to), , drop = FALSE]
  current <- current[current$indicator_id %in% hf$indicator_id, , drop = FALSE]
  if (nrow(current) == 0L) {
    discovery[[length(discovery) + 1L]] <- data.frame(
      base_id = base_id, status = "no_updates", detail = "Higher-frequency rows had no usable update boundaries",
      stringsAsFactors = FALSE
    )
    next
  }

  ids <- unique(current$indicator_id)
  bounds <- do.call(rbind, lapply(ids, function(id) {
    x <- current[current$indicator_id == id, , drop = FALSE]
    data.frame(
      base_id = base_id,
      indicator_id = id,
      data_from = min(x$data_from),
      data_to = max(x$data_to),
      stringsAsFactors = FALSE
    )
  }))
  idx <- match(bounds$indicator_id, hf$indicator_id)
  bounds$frequency_code <- hf$frequency_code[idx]
  bounds$indicator_name <- hf$indicator_name[idx]
  bounds$history_days <- as.numeric(bounds$data_to - bounds$data_from)
  candidates[[length(candidates) + 1L]] <- bounds
  discovery[[length(discovery) + 1L]] <- data.frame(
    base_id = base_id, status = "ok", detail = paste(nrow(bounds), "usable higher-frequency candidates"),
    stringsAsFactors = FALSE
  )
}

discovery_table <- do.call(rbind, discovery)
write.csv(discovery_table, file.path(output_dir, "final-target-discovery.csv"), row.names = FALSE, na = "")

if (length(candidates) == 0L) {
  stop("Could not discover a usable higher-frequency target; inspect final-target-discovery.csv")
}

candidate_table <- do.call(rbind, candidates)
# Prefer at least ten years of source history so 3y and 10y windows are both
# meaningful, then choose the shortest such history to bound request volume.
ten_years <- 365 * 10
eligible <- candidate_table[candidate_table$history_days >= ten_years, , drop = FALSE]
if (nrow(eligible) == 0L) eligible <- candidate_table
eligible <- eligible[order(eligible$history_days, eligible$indicator_id), , drop = FALSE]
selected <- eligible[1L, , drop = FALSE]
write.csv(selected, file.path(output_dir, "final-target-selected.csv"), row.names = FALSE, na = "")

Sys.setenv(ARADR_FINAL_TARGET_INDICATORS = selected$indicator_id[[1L]])
message(
  "Selected ", selected$indicator_id[[1L]], " (", selected$frequency_code[[1L]], ", ",
  selected$history_days[[1L]], " days history) from base ", selected$base_id[[1L]]
)

source("tools/final-coverage-audit.R", chdir = FALSE)
