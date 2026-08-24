arad_abort <- function(message, class = "arad_error") {
  condition <- structure(
    list(message = message, call = NULL),
    class = c(class, "arad_error", "error", "condition")
  )
  stop(condition)
}

arad_redact <- function(text, secret) {
  if (is.null(secret) || length(secret) != 1L || is.na(secret) || !nzchar(secret)) {
    return(text)
  }
  gsub(secret, "<redacted>", text, fixed = TRUE)
}
