arad_md5_string <- function(x) {
  file <- tempfile()
  on.exit(unlink(file), add = TRUE)
  writeLines(enc2utf8(paste(x, collapse = "\n")), file, useBytes = TRUE)
  unname(tools::md5sum(file))
}

.aradR_session_cache <- new.env(parent = emptyenv())

arad_cache_mode <- function(cache = NULL) {
  if (is.null(cache)) {
    cache <- getOption("aradR.cache", "none")
  }
  if (length(cache) != 1L || is.na(cache)) {
    arad_abort("`cache` must be one of 'none', 'session', or 'disk'.", "arad_input_error")
  }
  cache <- tolower(trimws(as.character(cache)))
  if (!cache %in% c("none", "session", "disk")) {
    arad_abort("`cache` must be one of 'none', 'session', or 'disk'.", "arad_input_error")
  }
  cache
}

arad_cache_age <- function(cache_max_age = NULL) {
  if (is.null(cache_max_age)) {
    cache_max_age <- getOption("aradR.cache_max_age", Inf)
  }
  if (length(cache_max_age) != 1L || is.na(cache_max_age) || cache_max_age < 0) {
    arad_abort("`cache_max_age` must be a non-negative number of seconds or Inf.", "arad_input_error")
  }
  as.numeric(cache_max_age)
}

arad_cache_directory <- function(cache_dir = NULL) {
  if (is.null(cache_dir)) {
    cache_dir <- getOption("aradR.cache_dir", NULL)
  }
  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("aradR", which = "cache")
  }
  if (length(cache_dir) != 1L || is.na(cache_dir) || !nzchar(trimws(cache_dir))) {
    arad_abort("`cache_dir` must be a non-empty directory path.", "arad_input_error")
  }
  path.expand(trimws(cache_dir))
}

arad_cache_key <- function(endpoint, query, base_url, api_key) {
  query <- query[order(names(query))]
  query_text <- if (length(query) == 0L) {
    ""
  } else {
    paste(
      paste0(
        names(query),
        "=",
        vapply(query, function(x) paste(as.character(x), collapse = ","), character(1))
      ),
      collapse = "&"
    )
  }

  # Separate caches belonging to different ARAD credentials without ever
  # persisting the API key itself.
  credential_hash <- arad_md5_string(api_key)
  arad_md5_string(c(base_url, endpoint, query_text, credential_hash))
}

arad_cache_is_fresh <- function(stored_at, max_age) {
  if (is.infinite(max_age)) {
    return(TRUE)
  }
  age <- as.numeric(difftime(Sys.time(), stored_at, units = "secs"))
  is.finite(age) && age <= max_age
}

arad_cache_get <- function(key, mode, max_age, cache_dir = NULL) {
  if (identical(mode, "none")) {
    return(NULL)
  }

  if (identical(mode, "session")) {
    if (!exists(key, envir = .aradR_session_cache, inherits = FALSE)) {
      return(NULL)
    }
    entry <- get(key, envir = .aradR_session_cache, inherits = FALSE)
    if (!arad_cache_is_fresh(entry$stored_at, max_age)) {
      rm(list = key, envir = .aradR_session_cache)
      return(NULL)
    }
    return(entry$raw)
  }

  directory <- arad_cache_directory(cache_dir)
  path <- file.path(directory, paste0(key, ".rds"))
  if (!file.exists(path)) {
    return(NULL)
  }
  entry <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(entry) || !is.list(entry) || !is.raw(entry$raw) || is.null(entry$stored_at)) {
    unlink(path)
    return(NULL)
  }
  if (!arad_cache_is_fresh(entry$stored_at, max_age)) {
    unlink(path)
    return(NULL)
  }
  entry$raw
}

arad_cache_set <- function(key, raw, mode, cache_dir = NULL) {
  if (identical(mode, "none")) {
    return(invisible(raw))
  }
  entry <- list(version = 1L, stored_at = Sys.time(), raw = raw)

  if (identical(mode, "session")) {
    assign(key, entry, envir = .aradR_session_cache)
    return(invisible(raw))
  }

  directory <- arad_cache_directory(cache_dir)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  saveRDS(entry, file.path(directory, paste0(key, ".rds")))
  invisible(raw)
}

#' Clear aradR response caches
#'
#' Clears cached raw ARAD API responses. Session caching lives only in the
#' current R process; disk caching is stored in the aradR user cache directory.
#'
#' @param cache Which cache to clear: `"session"`, `"disk"`, or `"all"`.
#' @param cache_dir Optional disk cache directory.
#'
#' @return Invisibly, `TRUE`.
#' @export
arad_cache_clear <- function(cache = c("all", "session", "disk"), cache_dir = NULL) {
  cache <- match.arg(cache)

  if (cache %in% c("all", "session")) {
    keys <- ls(envir = .aradR_session_cache, all.names = TRUE)
    if (length(keys) > 0L) {
      rm(list = keys, envir = .aradR_session_cache)
    }
  }

  if (cache %in% c("all", "disk")) {
    directory <- arad_cache_directory(cache_dir)
    if (dir.exists(directory)) {
      files <- list.files(directory, pattern = "^[0-9a-f]{32}\\.rds$", full.names = TRUE)
      if (length(files) > 0L) unlink(files)
    }
  }

  invisible(TRUE)
}
