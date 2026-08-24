# aradR architecture

## Purpose

`aradR` is an independent R client and toolkit for the Czech National Bank ARAD API. It is not a compatibility fork of `cnbrrr`; the goal is a reliability-first core with explicit validation, a cleaner public API, and maintainable testing/documentation suitable for an eventually CNB-recommended package.

## Public API

### Retrieval and availability

- `arad_get()` — retrieve time series from `/data` using exactly one selector (`indicator_ids`, `set_id`, `base_id`, or `selection_id`).
- `arad_updates()` — retrieve update metadata and data boundaries from `/updates`.

### Discovery and metadata

- `arad_indicators()` — basic indicator metadata from `/indicators`.
- `arad_search()` — scoped search/filtering over indicator metadata.
- `arad_dimensions()` — dimensional metadata from `/indicators-dims`.
- `arad_tree()` — ARAD hierarchy paths from `/indicators-tree`.
- `arad_snapshots()` — snapshot discovery from `/snapshots`.

### Analytical helpers

- `arad_wide()` — safe long-to-wide reshaping with snapshot-aware series naming.

### Reproducibility

- explicit raw-response caching: `none`, `session`, or `disk`;
- `arad_cache_clear()` for cache lifecycle management;
- caching is off by default to avoid accidental staleness;
- retrieval diagnostics are attached to `arad_get()` output and preserved by `arad_wide()`.

## Mapping from cnbrrr

| cnbrrr | aradR decision |
|---|---|
| `arad_get_data()` | Replace with `arad_get()` and a new retrieval/parsing implementation. |
| `arad_list_indicators()` / `arad_get_indicators()` | Replace with `arad_indicators()` and `arad_search()`; do not preserve aliases. |
| `arad_indicators_dims()` | Retain capability as `arad_dimensions()`. |
| `arad_indicators_tree()` | Retain capability as `arad_tree()`. |
| snapshot support | Promote to first-class `arad_snapshots()` API. |
| caching in downloaded files | Replace with explicit raw-response session/disk cache keyed by request and credential hash. |
| `arad_parse_date()` | Keep as an internal implementation detail. |
| `arad_validate_indicators()` | Replace with stricter internal selector/input validation. |

## Reliability model

1. **Do not parse numeric values during CSV ingestion.** Read API fields as character data first.
2. **Validate structure explicitly.** Required columns, dates, numeric values, IDs, and observation keys are checked before returning data.
3. **Preserve genuine missing values.** Empty/NA/NULL value fields remain `NA_real_`; they are not automatically dropped or treated as errors.
4. **Chunk long requests deterministically.** In `strategy = "auto"`, explicit or update-derived date ranges are divided into bounded intervals before `/data` calls.
5. **Resolve missing range boundaries through `/updates`.** This allows full-history requests to be chunked without guessing start/end dates.
6. **Handle boundary overlap conservatively.** Identical cross-chunk observations can be collapsed; conflicting values for the same indicator/snapshot/period remain a hard integrity error.
7. **Retry transient HTTP failures.** API credentials are handled separately and redacted from surfaced server responses.
8. **Keep caching explicit.** Cached raw responses are never silently enabled. API keys are not stored; a one-way hash is used only to prevent cache collision between credentials.
9. **Attach diagnostics.** Returned data carries an `arad_diagnostics` attribute describing retrieval strategy, resolved range, and number of data requests.

## Reliability calibration

The initial live calibration completed on 24 August 2026. It covered:

- monthly, quarterly, annual and daily data;
- long histories across several ARAD scopes;
- approximately 3-year and 10-year windows for a daily series;
- single- and multi-indicator requests;
- snapshot-backed retrieval.

The normal 3650-day chunk size matched finer references exactly across the completed matrix: no key differences, no `NA` mismatches, no numeric mismatches, and maximum absolute difference zero. It is therefore the calibrated production default for the current test matrix.

The audit remains bounded and rate-limited because ARAD asks clients not to overload the API. Broader live audits and full multi-OS CI are release/reliability tools rather than routine PR checks.

## User-facing documentation

The package is organised around a short discovery → retrieval → reshape workflow:

1. configure `ARAD_API_KEY`;
2. discover series with `arad_indicators()` / `arad_search()`;
3. retrieve with `arad_get()`;
4. optionally reshape with `arad_wide()`;
5. use diagnostics, caching, snapshots, and update metadata as needed.

The Get Started vignette and troubleshooting guide are the primary onboarding documents. `_pkgdown.yml` defines the future public website structure.

## Later layers

Potential additions should be driven by a clear user benefit and should not duplicate simple R-side transformations. Candidates include update-aware refresh helpers and selective support for `/data-trans` if it proves materially useful beyond `arad_wide()`.

## Provenance

Selected design ideas are informed by the MIT-licensed `petrbouchal/cnbrrr` project. `aradR` uses a new implementation and public API; attribution requirements are documented in `NOTICE.md`.
