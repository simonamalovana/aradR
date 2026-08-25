\name{arad_find}
\alias{arad_find}
\title{Find indicators using human-readable metadata}
\usage{
arad_find(
  term,
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  frequency = NULL,
  search_dimensions = TRUE,
  details = TRUE,
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
\item{term}{Non-empty text or regular expression to search for.}
\item{indicator_ids}{Character vector of indicator IDs.}
\item{set_id}{ARAD set ID.}
\item{base_id}{ARAD base ID.}
\item{selection_id}{ARAD user selection ID.}
\item{frequency}{Optional frequency code(s) to retain.}
\item{search_dimensions}{Search base and dimension labels/codes as well as names, IDs and hierarchy paths.}
\item{details}{Add availability/update columns for matched indicators. \code{data_to} is the ARAD-reported availability boundary and can extend into a forecast or reporting horizon; it is not necessarily the latest observed historical date.}
\item{regex}{Interpret \code{term} as a regular expression.}
\item{ignore_case}{Ignore case while matching.}
\item{lang}{Metadata language, \code{"cs"} or \code{"en"}.}
\item{api_key}{ARAD API key. If \code{NULL}, \code{ARAD_API_KEY} is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding.}
\item{cache}{Response cache mode: none, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
\item{cache_max_age}{Maximum cache age in seconds.}
}
\value{A filtered, path-aware indicator catalogue ordered by relevance. \code{relevance_score} is an ordinal score intended only to order results for the current query, and \code{matched_in} records which metadata sources matched. With \code{details = TRUE}, availability columns are included.}
\description{Searches names, IDs and ARAD hierarchy paths and, by default, base/dimension metadata so a user does not need to know an indicator ID in advance. ARAD metadata endpoints remain scoped, so exactly one selector is required. Results are ordered deterministically: exact ID/name matches first, then partial ID/name matches, hierarchy-path matches and dimension matches, with stable name/ID tie-breaking.}
