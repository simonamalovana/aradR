arad_loaded_or_installed_version <- function(package) {
  if (package %in% loadedNamespaces()) {
    return(getNamespaceVersion(package))
  }

  utils::packageVersion(package)
}

arad_curl_modify_url_available <- function() {
  # curl_version() is available on both the legacy and current curl stacks we
  # support. Calling it through the declared namespace import ensures curl is
  # a genuine direct runtime dependency without referencing curl_modify_url()
  # on older curl releases where that function does not exist.
  invisible(curl_version())
  "curl_modify_url" %in% getNamespaceExports(loadNamespace("curl"))
}

arad_check_http_dependencies <- function(
    httr2_version = arad_loaded_or_installed_version("httr2"),
    curl_version = arad_loaded_or_installed_version("curl"),
    curl_modify_url_available = arad_curl_modify_url_available()) {
  httr2_version <- as.character(httr2_version)
  curl_version <- as.character(curl_version)

  modern_url_stack <- utils::compareVersion(httr2_version, "1.2.0") >= 0L
  compatible_curl <- utils::compareVersion(curl_version, "6.4.0") >= 0L &&
    isTRUE(curl_modify_url_available)

  if (modern_url_stack && !compatible_curl) {
    arad_abort(
      sprintf(
        paste0(
          "aradR cannot use the installed HTTP packages: httr2 %s requires ",
          "curl >= 6.4.0 with `curl_modify_url()`, but the loaded curl version is %s. ",
          "Update curl with `install.packages(\"curl\")`, restart R, and try again. ",
          "If the update is blocked in your environment, contact your R administrator."
        ),
        httr2_version,
        curl_version
      ),
      "arad_dependency_error"
    )
  }

  invisible(TRUE)
}
