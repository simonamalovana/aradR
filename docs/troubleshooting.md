# Troubleshooting aradR

This guide is for problems that arise while discovering or retrieving ARAD data. Do not paste API keys into issues, logs, screenshots, or reproducible examples.

## `ARAD_API_KEY` is missing

`aradR` reads the key from the `api_key` argument or, by default, the `ARAD_API_KEY` environment variable.

Recommended setup in `~/.Renviron`:

```text
ARAD_API_KEY=your_key_here
```

Restart R after changing `.Renviron`.

## HTTP 400 / invalid request

Check that:

- exactly one selector is supplied (`indicator_ids`, `set_id`, `base_id`, or `selection_id`);
- date strings are valid and `from <= to`;
- `months_before` is not combined with `from` / `to`;
- the API key is valid;
- snapshot IDs are valid for the requested data.

Server messages are surfaced where possible, but credentials are redacted.

## Internal endpoint: proxy 303 or HTTP 401

The public ARAD endpoint is the package default. If your organization provides an internal ARAD endpoint that uses integrated Negotiate authentication, enable it with `arad_use_internal()` rather than changing only `options(aradR.base_url = ...)`.

```r
arad_use_internal("https://internal.example/api/v1")
```

Internal mode bypasses configured proxies for ARAD requests and asks libcurl to authenticate with the current integrated login. It has been validated with Windows integrated authentication.

A low-level error such as `Received HTTP code 303 from proxy after CONNECT` means a network proxy intercepted the connection before ARAD was reached. In internal mode, aradR bypasses that proxy for the ARAD request.

An HTTP 401 response in internal mode means the endpoint was reached but integrated authentication was not accepted. Confirm that the R session is running under an authorized login and that Negotiate authentication is available. Do not put a Windows password into R code.

Restore normal public-endpoint behaviour with:

```r
arad_use_external()
```

## No rows returned

An empty result is not automatically an error. First inspect availability:

```r
arad_updates(indicator_ids = "YOUR_ID")
```

For metadata, remember that ARAD endpoints are scoped; a valid indicator may not belong to the set/base you are querying.

## `NA` values

`aradR` deliberately preserves genuine source `NA` values. It does not assume every missing value is corruption.

Malformed non-missing numeric fields, invalid dates, and structural parsing failures raise explicit errors instead of being silently converted to missing observations.

## Duplicate or conflicting observations

ARAD can return the same lower-frequency boundary observation in two adjacent date requests. `aradR` safely collapses cross-chunk duplicates only when the complete observation is identical.

If the same indicator/snapshot/period key contains conflicting values, retrieval fails with an integrity error. This is intentional; inspect the error instead of calling `distinct()` blindly.

## Wide reshaping fails

`arad_wide()` requires `indicator_id`, `period`, and numeric `value` columns. If several snapshot contexts would map into the same indicator-period cell, keep the default `snapshot = "auto"` or use `snapshot = "include"`.

Using `snapshot = "ignore"` is only safe when that choice does not create duplicate period/series cells.

## Cache appears stale

Caching is off by default. If you enabled session or disk caching, either lower `cache_max_age`, force a non-cached call with `cache = "none"`, or clear the cache:

```r
arad_cache_clear()
```

## A long request looks suspicious

Keep the original result and inspect:

```r
attr(x, "arad_diagnostics")
```

Do not immediately launch many repeated API calls. The package's default bounded retrieval is calibrated from live comparisons against finer chunking, and ARAD asks clients not to overload the service.

If you can reproduce a mismatch, report:

- `packageVersion("aradR")`;
- indicator IDs (these are not secrets);
- date range and snapshot choice;
- the function call with the API key removed;
- the error class/message or a compact comparison;
- `attr(x, "arad_diagnostics")` when available.

## ARAD data issue vs aradR client issue

Use the aradR GitHub issue tracker for package behaviour, parsing, validation, caching, or API ergonomics. For questions about the meaning, publication, or official content of an ARAD series, use the Czech National Bank's ARAD support/contact channels.
