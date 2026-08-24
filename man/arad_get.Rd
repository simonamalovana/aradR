\name{arad_get}
\alias{arad_get}
\title{Retrieve time series from ARAD}
\usage{
arad_get(
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  from = NULL,
  to = NULL,
  months_before = NULL,
  snapshot_ids = NULL,
  strategy = c("auto", "direct"),
  chunk_days = getOption("aradR.chunk_days", 3650L),
  api_key = NULL,
  base_url = NULL,
  encoding = "windows-1250"
)
}
\arguments{
\item{indicator_ids}{Character vector of indicator IDs.}
\item{set_id}{ARAD set ID.}
\item{base_id}{ARAD base ID.}
\item{selection_id}{ARAD user selection ID.}
\item{from}{Start date as a Date, YYYY-MM-DD, or YYYYMMDD.}
\item{to}{End date as a Date, YYYY-MM-DD, or YYYYMMDD.}
\item{months_before}{Optional positive integer; an ARAD-native alternative to from/to.}
\item{snapshot_ids}{Optional snapshot IDs, or ALL / LAST.}
\item{strategy}{Retrieval strategy. auto uses bounded requests; direct makes one data request.}
\item{chunk_days}{Maximum inclusive date span of each automatic chunk.}
\item{api_key}{ARAD API key. If NULL, ARAD_API_KEY is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding. Defaults to Windows-1250.}
}
\value{
A tibble with columns indicator_id, snapshot_id, period, and value. Retrieval diagnostics are stored in the arad_diagnostics attribute.
}
\description{
Reliability-first retrieval of ARAD time series. Exactly one selector must be supplied. With strategy = "auto", long date ranges are split into deterministic, non-overlapping chunks; omitted boundaries are resolved through the ARAD updates endpoint.
}
