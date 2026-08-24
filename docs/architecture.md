# aradR architecture

## Purpose

`aradR` is an independent R client and toolkit for the Czech National Bank ARAD API. It is not a compatibility fork of `cnbrrr`; the goal is a reliability-first core with explicit validation, a cleaner public API, and maintainable testing/documentation suitable for an eventually CNB-recommended package.

## Public API direction

### Reliability and retrieval

- `arad_get()` — retrieve time series from `/data` using exactly one selector (`indicator_ids`, `set_id`, `base_id`, or `selection_id`).
- `arad_updates()` — retrieve update metadata and data boundaries from `/updates`.

### Discovery and metadata

- `arad_indicators()` — basic indicator metadata from `/indicators`.
- `arad_search()` — scoped search/filtering over indicator metadata.
- `arad_dimensions()` — dimensional metadata from `/indicators-dims`.
- `arad_tree()` — ARAD hierarchy paths from `/indicators-tree`.
- `arad_snapshots()` — snapshot discovery from `/snapshots`.

### Reproducibility

- explicit raw-response caching: `none`, `session`, or `disk`.
- `arad_cache_clear()` for cache lifecycle management.
- caching is off by default to avoid accidental staleness; users must opt in.

### Later layers

- convenient long-to-wide output helpers.
- update-aware refresh workflows.
- richer examples/vignettes and pkgdown site.
- possible `/data-trans` support only if it provides a user benefit not already covered cleanly by reshaping `arad_get()` output in R.

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
2. **Validate structure explicitly.** Required columns, dates, numeric values, IDs, and duplicate observation keys are checked before returning data.
3. **Preserve genuine missing values.** Empty/NA/NULL value fields remain `NA_real_`; they are not automatically dropped or treated as errors.
4. **Chunk long requests deterministically.** In `strategy = "auto"`, explicit or update-derived date ranges are divided into bounded, non-overlapping intervals before `/data` calls.
5. **Resolve missing range boundaries through `/updates`.** This allows full-history requests to be chunked without guessing start/end dates.
6. **Retry transient HTTP failures.** API credentials are handled separately and redacted from surfaced server responses.
7. **Keep caching explicit.** Cached raw responses are never silently enabled. API keys are not stored; a one-way hash is used only to prevent cache collision between credentials.
8. **Attach diagnostics.** Returned data carries an `arad_diagnostics` attribute describing retrieval strategy, resolved range, and number of data requests.

## Live validation strategy without the original failing fixture

The original long-range failure can be investigated without knowing the exact series that triggered it. The repository contains a staged audit that:

1. discovers indicators and update boundaries within one or more ARAD sets;
2. stratifies candidates by frequency and history length;
3. samples a bounded number of series from each stratum;
4. retrieves each series using fine chunking as a reference;
5. compares the normal aradR chunk size against the reference;
6. separately compares a single direct `/data` request against the same reference;
7. distinguishes missing-key, NA-pattern and numeric-value mismatches;
8. writes machine-readable audit artifacts.

The audit is deliberately rate-limited and sampled because ARAD documentation warns that excessive request frequency or data volume can result in API access being blocked. Coverage should therefore be expanded in controlled batches across ARAD areas rather than by attempting an unrestricted one-shot download of the full database.

The default `aradR.chunk_days` remains provisional until this staged audit has covered a sufficiently broad set of frequencies, history lengths, and statistical areas.

## Provenance

Selected design ideas are informed by the MIT-licensed `petrbouchal/cnbrrr` project. `aradR` uses a new implementation and public API; attribution requirements are documented in `NOTICE.md`.
