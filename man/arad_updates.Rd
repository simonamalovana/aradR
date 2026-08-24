\name{arad_updates}
\alias{arad_updates}
\title{Retrieve ARAD update metadata}
\usage{
arad_updates(
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  snapshot_ids = NULL,
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
\item{snapshot_ids}{Optional snapshot IDs, or ALL / LAST.}
\item{api_key}{ARAD API key. If NULL, ARAD_API_KEY is used.}
\item{base_url}{ARAD API base URL. Primarily intended for testing.}
\item{encoding}{Response encoding. Defaults to Windows-1250.}
}
\value{
A tibble with indicator_id, snapshot_id, update_date, data_from, and data_to.
}
\description{
Retrieves the last update timestamp and available data boundaries from the ARAD updates endpoint. Exactly one selector must be supplied.
}
