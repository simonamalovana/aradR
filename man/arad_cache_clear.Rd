\name{arad_cache_clear}
\alias{arad_cache_clear}
\title{Clear aradR response caches}
\usage{
arad_cache_clear(cache = c("all", "session", "disk"), cache_dir = NULL)
}
\arguments{
\item{cache}{Which cache to clear: all, session, or disk.}
\item{cache_dir}{Optional disk cache directory.}
}
\value{Invisibly, TRUE.}
\description{Clears raw ARAD API responses stored by aradR in the current R session and/or on disk.}
