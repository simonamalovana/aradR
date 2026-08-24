\name{arad_info}
\alias{arad_info}
\title{Inspect selected ARAD indicators in detail}
\usage{
arad_info(
  indicator_ids,
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
\item{indicator_ids}{Character vector of indicator IDs to inspect.}
\item{lang}{Metadata language, \code{"cs"} or \code{"en"}.}
\item{api_key}{ARAD API key. If \code{NULL}, \code{ARAD_API_KEY} is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding.}
\item{cache}{Response cache mode: none, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
\item{cache_max_age}{Maximum cache age in seconds.}
}
\value{A named list with \code{summary}, \code{dimensions}, and \code{updates} tibbles.}
\description{Retrieves a compact path/availability summary plus detailed dimension metadata and raw update rows for candidate indicators selected through discovery.}
