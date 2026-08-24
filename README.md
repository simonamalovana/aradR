# aradR

Modern R client and toolkit for the Czech National Bank ARAD API.

`aradR` is being developed as an independent, reliability-first R package for discovering, retrieving, validating, and working with data from the Czech National Bank's ARAD database.

## Project status

Early development. The package API is not yet stable and the repository is currently private.

## Design goals

- reliable retrieval of long and complex time series
- explicit validation of parsed data and missing values
- clear, actionable error messages
- convenient discovery of ARAD indicators and metadata
- reproducible, explicit caching and downloads
- support for snapshots and update workflows
- comprehensive automated tests and continuous integration
- staged live stress testing against the ARAD API
- concise documentation for both occasional and advanced R users

## Core API

```r
library(aradR)

# Full available history, automatically bounded and chunked
x <- arad_get(indicator_ids = "SMV5M603")

# Explicit period
y <- arad_get(
  indicator_ids = c("SMV5M601", "SMV5M603"),
  from = "2015-01-01",
  to = "2026-01-01"
)

# Availability and last-update metadata
u <- arad_updates(indicator_ids = "SMV5M603")
```

Exactly one ARAD selector is accepted where a scoped endpoint requires one: `indicator_ids`, `set_id`, `base_id`, or `selection_id`.

`arad_get()` defaults to `strategy = "auto"`: missing date boundaries are resolved through `/updates`, and long histories are divided into deterministic non-overlapping requests before they are parsed and combined. `strategy = "direct"` is available for diagnostics and benchmarking.

API responses are ingested as character fields first and explicitly validated afterwards. Genuine missing values are preserved; malformed non-missing numeric values, invalid dates, structural parsing problems, and conflicting duplicate observation keys fail loudly. Identical cross-chunk boundary overlaps are collapsed safely.

Retrieval details are available via:

```r
attr(x, "arad_diagnostics")
```

## Discovery and metadata

```r
# Basic metadata for a set
ind <- arad_indicators(set_id = 1058, lang = "en")

# Search within that ARAD scope
hits <- arad_search("inflation", set_id = 1058, lang = "en")

# Dimensional definitions and ARAD tree paths
dims <- arad_dimensions(indicator_ids = hits$indicator_id)
paths <- arad_tree(indicator_ids = hits$indicator_id, lang = "en")

# Available monetary-policy-report snapshots
snaps <- arad_snapshots(lang = "en")
```

ARAD's metadata endpoints require a scope selector; there is no assumption in `aradR` that `/indicators` provides a global unscoped catalogue.

## Caching

Caching is explicit and disabled by default:

```r
# Reuse responses during the current R session
x <- arad_get("SMV5M603", cache = "session")

# Persist raw API responses on disk
ind <- arad_indicators(set_id = 1058, cache = "disk")

# Clear cached responses
arad_cache_clear()
```

Available modes are `"none"`, `"session"`, and `"disk"`. Disk cache location and maximum age can be configured with `cache_dir` / `cache_max_age` or the corresponding `aradR.*` options. API keys are never written to cache; credential-specific cache separation uses only a one-way hash.

## Reliability audit

The repository includes staged live audits and GitHub Actions workflows that compare fine-grained chunked retrieval, the normal `aradR` chunk size, and a single direct ARAD request.

The initial reliability calibration completed on 24 August 2026. Coverage included long monthly, quarterly and annual series across multiple ARAD scopes, a mixed multi-indicator request, snapshot-backed data, and the daily `SFTP01D15` policy-rate series. The daily series was checked over its full 1995–2026 history and over approximately 3-year and 10-year windows.

Across the completed matrix, the production default of 3650 days matched the finer references exactly: no missing-key differences, no `NA` mismatches, no numeric-value mismatches, and maximum absolute difference zero. Direct requests also matched the references in the tested cases. The 3650-day default is therefore retained as the calibrated default for the current coverage matrix.

The audit remains intentionally bounded and rate-limited because ARAD documents that excessive request frequency or volume may lead to API access being blocked. Release-quality validation can re-run the broader staged audit and the full multi-OS package check when needed.

## Development architecture

See [`docs/architecture.md`](docs/architecture.md) for the current public-API plan, mapping from `cnbrrr`, and reliability model.

## API key

Obtain an ARAD API key from your ARAD account and store it outside source code, preferably in `.Renviron`:

```text
ARAD_API_KEY=your_key_here
```

Never commit API keys to a repository.

## Provenance

The project is independent from `cnbrrr`, but its initial design review and selected implementation ideas are informed by the MIT-licensed [`petrbouchal/cnbrrr`](https://github.com/petrbouchal/cnbrrr) package by Petr Bouchal. Any code adapted from that project retains the attribution required by its MIT license. See `NOTICE.md`.

## License

MIT. See `LICENSE.md`.
