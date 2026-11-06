# Example 01: Czech mortgage rates and monetary policy
#
# Reproducible aradR workflow (requires your own ARAD API key).
# This example intentionally does NOT hard-code an unverified ARAD indicator ID.
#
# PREPARATION
# 1. Install aradR from CRAN:
#      install.packages("aradR")
# 2. Obtain your personal API key in ARAD, then set ARAD_API_KEY in ~/.Renviron.
# 3. This script uses the monthly CNB ARAD series
#      SMIRNOOBUVMIRS305CZK011111
#    New-business interest rate, households + NPISH, housing loans,
#    Czech koruna, banks incl. building societies, total fixing periods.
#    Verify its methodology against the ECB MIR comparator before interpretation.
# 4. Optional: override the series ID with ARAD_MORTGAGE_ID in ~/.Renviron.
#
# The corresponding harmonised ECB MIR series used on the interactive site:
# https://data.ecb.europa.eu/data/datasets/MIR/MIR.M.CZ.B.A2C.A.R.A.2250.CZK.N
# Bank rates are from new loans. The 2W repo is a month-end policy rate.
# Their difference is NOT a bank profit margin or a causal pass-through estimate.

stopifnot(requireNamespace("aradR", quietly = TRUE))
library(aradR)

indicator_id <- trimws(Sys.getenv("ARAD_MORTGAGE_ID", "SMIRNOOBUVMIRS305CZK011111"))
if (!nzchar(indicator_id)) {
  stop("ARAD_MORTGAGE_ID is blank. Set a valid ARAD series or unset the variable.")
}

# Inspect the metadata, and cross-check it against the definition above.
metadata <- arad_info(indicator_id, lang = "en")
print(metadata$summary)

mortgage <- arad_get(
  indicator_ids = indicator_id,
  from = "2015-01-01"
)
retrieval_diagnostics <- attr(mortgage, "arad_diagnostics")
stopifnot(all(c("period", "value", "indicator_id") %in% names(mortgage)))
mortgage <- mortgage[mortgage$indicator_id == indicator_id, , drop = FALSE]
if ("snapshot_id" %in% names(mortgage) &&
    any(!is.na(mortgage$snapshot_id) & nzchar(as.character(mortgage$snapshot_id)))) {
  stop("The selected series has snapshots. Choose one vintage explicitly before comparison.")
}
mortgage$month <- format(as.Date(mortgage$period), "%Y-%m")
if (anyDuplicated(mortgage$month)) {
  stop("Multiple observations in a single month: check frequency and indicator selection.")
}
mortgage$value <- as.numeric(mortgage$value)
if (any(!is.na(mortgage$value) & (mortgage$value < 0 | mortgage$value > 20))) {
  stop("Unexpected mortgage rate range; confirm series and percent-p.a. units.")
}
mortgage <- mortgage[!is.na(mortgage$value), c("month", "value")]
names(mortgage)[2] <- "mortgage"

# CNB official history of policy-rate changes. The monthly observation is
# the rate effective at the end of each month (NOT a monthly average).
repo_url <- paste0(
  "https://www.cnb.cz/en/faq/.galleries/",
  "development_of_the_cnb_2w_repo_rate.txt"
)
repo_history <- read.table(
  repo_url, header = TRUE, sep = "|", stringsAsFactors = FALSE,
  check.names = FALSE, fileEncoding = "UTF-8-BOM"
)
names(repo_history) <- c("valid_from", "repo")
repo_history$date <- as.Date(as.character(repo_history$valid_from), format = "%Y%m%d")
repo_history$repo <- as.numeric(repo_history$repo)
repo_history <- repo_history[order(repo_history$date), ]

month_end <- function(month) {
  first <- as.Date(paste0(month, "-01"))
  seq(first, by = "month", length.out = 2)[2] - 1
}
ends <- as.Date(vapply(mortgage$month, function(m) as.character(month_end(m)), ""))
indices <- findInterval(ends, repo_history$date)
if (any(indices == 0L)) stop("Policy history does not cover the selected period.")
mortgage$repo <- repo_history$repo[indices]
mortgage <- mortgage[order(mortgage$month), ]
names(mortgage)[names(mortgage) == "month"] <- "period"

# The verified dataset behind both lines.
write.csv(mortgage, "mortgage-vs-policy-rates.csv", row.names = FALSE)

# Generate a compact, publication-friendly PNG using base graphics.
png("mortgage-vs-policy-rates.png", width = 1500, height = 800, res = 160)
par(mar = c(4.5, 4.5, 3, 1), bty = "l", las = 1)
time <- as.Date(paste0(mortgage$period, "-01"))
ylim <- c(0, max(mortgage$mortgage, mortgage$repo, na.rm = TRUE) * 1.1)
plot(time, mortgage$mortgage, type = "l", col = "#147f7b", lwd = 2.5,
     xlab = "", ylab = "Interest rate (% p.a.)", ylim = ylim,
     main = "Czech mortgage rates and the 2W repo rate")
lines(time, mortgage$repo, col = "#d78b56", lwd = 2.5)
legend("topleft", bty = "n", c("New housing loans (monthly AAR)", "2W repo (month-end)"),
       col = c("#147f7b", "#d78b56"), lty = 1, lwd = 2.5)
mtext("Source: CNB ARAD (via aradR); CNB policy-rate history", side = 1, line = 3, cex = .7)
dev.off()

cat("Created mortgage-vs-policy-rates.csv and mortgage-vs-policy-rates.png\n")
cat("Data available through", tail(mortgage$period, 1), "\n")
cat("aradR diagnostics:\n")
print(retrieval_diagnostics)
