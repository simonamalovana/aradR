# aradR

[![R-CMD-check](https://github.com/simonamalovana/aradR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/simonamalovana/aradR/actions/workflows/R-CMD-check.yaml)

**Reliable access to Czech National Bank ARAD data from R.**

`aradR` is an independent open-source R package for discovering, inspecting, retrieving and reshaping time series from the public Czech National Bank ARAD API. It is designed for analytical workflows where reliable long-range retrieval, explicit validation and reproducibility matter.

> `aradR` is a personal project authored and maintained by Simona Malovana. It is not official Czech National Bank software and does not imply CNB endorsement.

## Install

The package is being prepared for CRAN. Until the first CRAN release, install the current version from GitHub:

```r
pak::pak("simonamalovana/aradR")
# or
remotes::install_github("simonamalovana/aradR")
```

After the CRAN release, the standard installation will be:

```r
install.packages("aradR")
```

## Quick start

ARAD API access requires an API key. Store it outside source code, for example in `~/.Renviron`:

```text
ARAD_API_KEY=your_key_here
```

Then discover a series using human-readable metadata and retrieve it:

```r
library(aradR)

hits <- arad_find(
  "inflation",
  set_id = 1058,
  lang = "en"
)

info <- arad_info(hits$indicator_id[1], lang = "en")

data <- arad_get(
  indicator_ids = hits$indicator_id[1],
  from = "2020-01-01"
)

wide <- arad_wide(data)
```

You do not need to know an indicator ID in advance. Start from a known ARAD set, base, selection or indicator and use `arad_find()` or `arad_catalog()` to explore the available series.

## Why aradR

- **Human-readable discovery** — search names, hierarchy paths and dimension metadata.
- **Reliable long-history retrieval** — bounded requests and deterministic chunking instead of one fragile large download.
- **Strict validation** — malformed dates, values, structures and conflicting duplicate observations fail explicitly.
- **Genuine missing values preserved** — source `NA` values are not silently discarded.
- **Snapshots supported** — retrieve current or snapshot-backed series without conflating observations.
- **Reproducible diagnostics** — retrieval strategy, resolved range and request count travel with the result.
- **Optional caching** — session or disk caching is explicit and off by default.

## Core workflow

### 1. Find data

```r
catalog <- arad_catalog(set_id = 1058, lang = "en")

hits <- arad_find(
  "inflation",
  set_id = 1058,
  lang = "en"
)

hits[, c("indicator_id", "indicator_name", "relevance_score", "matched_in")]
```

`arad_find()` ranks results deterministically and reports where each match came from. `data_from` and `data_to` are availability boundaries reported by ARAD; `data_to` can extend into a forecast or reporting horizon and is not necessarily the latest observed historical date.

### 2. Inspect a candidate

```r
info <- arad_info(hits$indicator_id[1], lang = "en")

info$summary
info$dimensions
info$updates
```

### 3. Retrieve observations

```r
x <- arad_get(
  indicator_ids = hits$indicator_id[1],
  from = "2015-01-01",
  to = "2026-01-01"
)
```

Omit `from` and `to` to retrieve the full ARAD-reported history. Long ranges are resolved and split into bounded requests automatically.

### 4. Reshape when useful

```r
wide <- arad_wide(x)
```

The stable package output is long format. `arad_wide()` creates one row per period and safely distinguishes snapshot contexts when needed.

## Reliability model

`arad_get()` uses `strategy = "auto"` by default. Missing boundaries are resolved through `/updates`; long histories are split into deterministic intervals; responses are parsed character-first and validated before numeric conversion; identical chunk-boundary overlaps can be collapsed, while conflicting duplicate observation keys are treated as integrity errors.

Retrieval diagnostics are attached to every result:

```r
attr(x, "arad_diagnostics")
```

The production default chunk size has been calibrated against finer-grained live references across monthly, quarterly, annual and daily series, including multi-indicator and snapshot-backed retrieval.

## Caching

Caching is disabled by default:

```r
x <- arad_get("SMV5M603", cache = "session")

x <- arad_get(
  "SMV5M603",
  cache = "disk",
  cache_max_age = 24 * 60 * 60
)

arad_cache_clear()
```

Disk cache files use R's user cache directory. API keys are never written to cached response files.

## Documentation

Full documentation is being published at **https://simonamalovana.github.io/aradR/**.

Start with:

- **Get started** — the end-to-end workflow from API key to analytical data;
- **Finding data** — practical discovery when you do not know indicator IDs;
- **Reliability and reproducibility** — chunking, validation, missing values, caching and diagnostics;
- **Reference** — complete function documentation.

The official ARAD documentation and API-key instructions are maintained by the Czech National Bank. `aradR` wraps the public API but does not replace its methodological documentation.

## Scope

`aradR 0.2.0` targets the **public ARAD API only**. Organization-internal endpoints, Windows integrated authentication and private-network proxy behavior are intentionally outside this package.

## Data citation

When presenting data obtained from ARAD, identify the data source as the Czech National Bank ARAD database (for example, `Source: CNB ARAD`). Package citation and data-source citation are separate: using `aradR` does not make the package the source of the underlying data.

## Author and provenance

`aradR` is authored and maintained by **Simona Malovana**.

The initial design review and selected implementation ideas were informed by the MIT-licensed [`petrbouchal/cnbrrr`](https://github.com/petrbouchal/cnbrrr) package by Petr Bouchal. Third-party provenance and attribution are documented in `NOTICE.md` and in the distributed package notice.

## License

MIT © 2026 Simona Malovana.
