\name{arad_snapshots}
\alias{arad_snapshots}
\title{List available ARAD snapshots}
\usage{
arad_snapshots(
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
\item{lang}{Metadata language: cs or en.}
\item{api_key}{ARAD API key. If NULL, ARAD_API_KEY is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding. Defaults to Windows-1250.}
\item{cache}{Response cache mode: none, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
\item{cache_max_age}{Maximum cache age in seconds.}
}
\value{A tibble with snapshot_id and snapshot_name.}
\description{Retrieves the list of ARAD snapshots. Unlike the indicator metadata endpoints, this service does not require an ARAD scope selector.}
