\name{arad_catalog}
\alias{arad_catalog}
\title{Build an enriched catalogue of indicators within an ARAD scope}
\usage{
arad_catalog(
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  lang = c("cs", "en"),
  include_path = TRUE,
  include_availability = TRUE,
  api_key = NULL,
  base_url = NULL,
  encoding = "windows-1250",
  cache = NULL,
  cache_dir = NULL,
  cache_max_age = NULL
)
}
\arguments{
\item{indicator_ids}{Character vector of indicator IDs.}
\item{set_id}{ARAD set ID.}
\item{base_id}{ARAD base ID.}
\item{selection_id}{ARAD user selection ID.}
\item{lang}{Metadata language, \code{"cs"} or \code{"en"}.}
\item{include_path}{Include the ARAD hierarchy path for each indicator.}
\item{include_availability}{Include available data boundaries, latest update timestamp and snapshot-context count.}
\item{api_key}{ARAD API key. If \code{NULL}, \code{ARAD_API_KEY} is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding.}
\item{cache}{Response cache mode: none, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
\item{cache_max_age}{Maximum cache age in seconds.}
}
\value{A tibble with one row per indicator in the selected scope.}
\description{Combines basic indicator metadata with hierarchy paths and optional availability metadata for human-facing browsing. Exactly one normal ARAD selector must be supplied.}
