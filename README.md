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
- reproducible caching and downloads
- support for snapshots and update workflows
- comprehensive automated tests and continuous integration
- concise documentation for both occasional and advanced R users

## Initial API

The first reliability core exposes two functions:

```r
library(aradR)

# Full available history, automatically bounded and chunked
x <- arad_get(
  indicator_ids = "SMV5M603",
  api_key = Sys.getenv("ARAD_API_KEY")
)

# Explicit period
y <- arad_get(
  indicator_ids = c("SMV5M601", "SMV5M603"),
  from = "2015-01-01",
  to = "2026-01-01"
)

# Availability and last-update metadata
u <- arad_updates(indicator_ids = "SMV5M603")
```

Exactly one ARAD selector is accepted per call: `indicator_ids`, `set_id`, `base_id`, or `selection_id`.

`arad_get()` defaults to `strategy = "auto"`: missing date boundaries are resolved through `/updates`, and long histories are divided into deterministic non-overlapping requests before they are parsed and combined. `strategy = "direct"` is available for diagnostics and benchmarking.

API responses are ingested as character fields first and explicitly validated afterwards. Genuine missing values are preserved; malformed non-missing numeric values, invalid dates, structural parsing problems, and duplicate observation keys fail loudly.

Retrieval details are available via:

```r
attr(x, "arad_diagnostics")
```

The current default chunk size is provisional until the known long-range ARAD failure is reproduced with a confirmed indicator/date fixture.

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
