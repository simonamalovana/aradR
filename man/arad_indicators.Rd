\name{arad_indicators}
\alias{arad_indicators}
\title{List ARAD indicators and basic metadata}
\usage{
arad_indicators(
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  lang = c("cs", "en"),
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
\item{lang}{Metadata language: cs or en.}
\item{api_key}{ARAD API key. If NULL, ARAD_API_KEY is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding. Defaults to Windows-1250.}
\item{cache}{Response cache mode: none, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
\item{cache_max_age}{Maximum cache age in seconds.}
}
\value{A tibble with indicator ID, name, frequency, scaling and unit metadata.}
\description{Retrieves basic metadata from the ARAD indicators endpoint. Exactly one ARAD scope selector must be supplied.}
