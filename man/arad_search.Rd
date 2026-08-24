\name{arad_search}
\alias{arad_search}
\title{Search indicators within an ARAD scope}
\usage{
arad_search(
  term,
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  frequency = NULL,
  regex = FALSE,
  ignore_case = TRUE,
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
\item{term}{Non-empty search text or regular expression.}
\item{indicator_ids}{Character vector of indicator IDs.}
\item{set_id}{ARAD set ID.}
\item{base_id}{ARAD base ID.}
\item{selection_id}{ARAD user selection ID.}
\item{frequency}{Optional frequency code(s) to retain.}
\item{regex}{Interpret term as a regular expression.}
\item{ignore_case}{Ignore case while matching.}
\item{lang}{Metadata language: cs or en.}
\item{api_key}{ARAD API key. If NULL, ARAD_API_KEY is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding. Defaults to Windows-1250.}
\item{cache}{Response cache mode: none, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
\item{cache_max_age}{Maximum cache age in seconds.}
}
\value{A filtered indicator metadata tibble.}
\description{Searches indicator IDs and names returned by the ARAD indicators endpoint. Because ARAD does not expose an unscoped global indicator list through this endpoint, exactly one normal ARAD selector is required.}
