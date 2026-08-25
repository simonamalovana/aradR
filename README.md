# aradR

Modern R client and toolkit for the Czech National Bank ARAD API.

`aradR` is an independent, reliability-first R package for discovering, retrieving, validating, reshaping, and working reproducibly with data from the Czech National Bank's ARAD database.

**Author and maintainer:** Simona Malovana

## Project status

**Release candidate (`0.2.0`).** The core retrieval API is reliability-calibrated, the human-readable discovery workflow has been validated against the live ARAD API, and the public API is frozen for the 0.2.0 release candidate. The repository is currently private.

## Install

For the current release-candidate build:

```r
pak::pak("simonamalovana/aradR")
# alternatively:
remotes::install_github("simonamalovana/aradR")
```

While the repository is private, GitHub access is required for installation.

## Quick start

Store your ARAD API key outside source code, preferably in `~/.Renviron`:

```text
ARAD_API_KEY=your_key_here
```

Then browse, find, inspect and retrieve data:

```r
library(aradR)

# Browse a known ARAD scope without knowing indicator IDs
catalog <- arad_catalog(set_id = 1058, lang = "en")

# Human-readable search across names, hierarchy paths and dimensions
hits <- arad_find("inflation", set_id = 1058, lang = "en")

# Inspect a candidate before downloading observations
info <- arad_info(hits$indicator_id[1], lang = "en")

# Retrieve the selected series
x <- arad_get(
  indicator_ids = hits$indicator_id[1],
  from = "2015-01-01",
  to = "2026-01-01"
)

# Optional wide analytical table
wide <- arad_wide(x)
```

For a full available history, omit `from` and `to`.

Exactly one ARAD selector is accepted where a scoped endpoint requires one: `indicator_ids`, `set_id`, `base_id`, or `selection_id`.

## Discovery workflow

ARAD's metadata endpoints are scoped: they do not expose one unscoped global indicator catalogue. `aradR` therefore keeps the scope explicit while removing the need to know indicator IDs in advance.

```r
# One row per indicator, including hierarchy path and availability
catalog <- arad_catalog(base_id = "MBOP", lang = "en")

# Rich human-readable search
hits <- arad_find(
  "households",
  base_id = "MBOP",
  lang = "en",
  frequency = "M"
)

# See why the leading results matched
hits[, c("indicator_id", "indicator_name", "relevance_score", "matched_in")]

# Detailed metadata for selected candidates
info <- arad_info(hits$indicator_id[1], lang = "en")
info$summary
info$dimensions
info$updates
```

`arad_find()` searches indicator names/IDs and ARAD hierarchy paths and, by default, base/dimension labels and values. Results are ordered deterministically by explainable relevance: exact ID/name matches first, then partial ID/name matches, hierarchy-path matches and dimension matches. `relevance_score` is an ordinal score for ordering the current result set; `matched_in` shows which metadata sources matched. With `details = TRUE`, availability and update metadata are added only for the matched indicators.

`data_from` and `data_to` are availability boundaries reported by ARAD through `/updates`. In particular, `data_to` can extend into a forecast or reporting horizon and should not automatically be interpreted as the latest observed historical date.

`arad_search()` remains available as a faster, lightweight search over indicator names and IDs when hierarchy/dimension discovery is not needed.

## Why aradR

- reliability-first bounded retrieval for long histories;
- explicit parsing and structural validation;
- genuine missing values preserved rather than silently dropped;
- safe handling of identical cross-chunk boundary overlaps;
- explicit errors for conflicting duplicate observations;
- ranked, explainable human-readable scoped discovery and metadata inspection;
- snapshot support;
- opt-in session or disk caching;
- retrieval diagnostics for reproducibility;
- automated tests plus bounded live ARAD audits and live UX acceptance checks.

## Retrieval model

`arad_get()` defaults to `strategy = "auto"`: missing date boundaries are resolved through `/updates`, and long histories are divided into deterministic bounded requests before parsing and combination. `strategy = "direct"` remains available for diagnostics and benchmarking.

API responses are ingested as character fields first and explicitly validated afterwards. Genuine missing values remain `NA`; malformed non-missing numeric values, invalid dates, structural parsing problems, and conflicting duplicate observation keys fail loudly.

Retrieval details are attached to results:

```r
attr(x, "arad_diagnostics")
```

## Lower-level metadata helpers

```r
ind <- arad_indicators(set_id = 1058, lang = "en")
hits <- arad_search("inflation", set_id = 1058, lang = "en")
dims <- arad_dimensions(indicator_ids = hits$indicator_id)
paths <- arad_tree(indicator_ids = hits$indicator_id, lang = "en")
snaps <- arad_snapshots(lang = "en")
updates <- arad_updates(indicator_ids = hits$indicator_id)
```

## Wide output

`arad_get()` intentionally returns a stable long format. Convert it when needed:

```r
wide <- arad_wide(x)
```

`arad_wide()` returns one row per period and one column per series. When the same indicator is present in multiple snapshot contexts, snapshot IDs are added to column names automatically so values are not conflated.

## Caching

Caching is explicit and disabled by default:

```r
x <- arad_get("SMV5M603", cache = "session")

x <- arad_get(
  "SMV5M603",
  cache = "disk",
  cache_max_age = 24 * 60 * 60
)

arad_cache_clear()
```

Available modes are `"none"`, `"session"`, and `"disk"`. API keys are never written to cache; credential-specific cache separation uses only a one-way hash.

## Reliability baseline

The initial reliability calibration completed on 24 August 2026. Coverage included long monthly, quarterly and annual series across several ARAD scopes, a mixed multi-indicator request, snapshot-backed data, and the daily `SFTP01D15` policy-rate series. The daily series was checked over its full 1995–2026 history and over approximately 3-year and 10-year request windows.

Across the completed matrix, the production default of 3650 days matched finer references exactly: no missing-key differences, no `NA` mismatches, no numeric-value mismatches, and maximum absolute difference zero. Direct requests also matched the references in the tested cases. The 3650-day default is retained as the calibrated default for the current coverage matrix.

The audit remains deliberately bounded and rate-limited because ARAD asks clients not to overload the API with excessive request volume or frequency.

## Documentation

- `vignette("get-started", package = "aradR")` — end-to-end onboarding;
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — common failures and diagnostics;
- [`docs/architecture.md`](docs/architecture.md) — public API and reliability design;
- [`AUTHORS.md`](AUTHORS.md) — authorship and upstream provenance;
- `_pkgdown.yml` — website structure ready for publication when the repository is made public.

## Data citation

When presenting data obtained from ARAD, identify the source as the Czech National Bank ARAD database (for example, `Source: CNB ARAD`).

## Author

`aradR` is authored and maintained by **Simona Malovana**. The package metadata and citation information identify Simona Malovana as the package author and maintainer.

## Provenance

The project is independent from `cnbrrr`, but its initial design review and selected implementation ideas are informed by the MIT-licensed [`petrbouchal/cnbrrr`](https://github.com/petrbouchal/cnbrrr) package by Petr Bouchal. Any adapted code retains the attribution required by its MIT license. See `NOTICE.md`.

## License

MIT. See `LICENSE.md`.
