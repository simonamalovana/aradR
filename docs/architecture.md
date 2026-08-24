# aradR architecture

## Purpose

`aradR` is an independent R client and toolkit for the Czech National Bank ARAD API. It is not a compatibility fork of `cnbrrr`; the goal is a smaller, reliability-first core with explicit validation and a broader, cleaner public API.

## Public API direction

### v0.1 core

- `arad_get()` — retrieve time series from `/data` using exactly one selector (`indicator_ids`, `set_id`, `base_id`, or `selection_id`).
- `arad_updates()` — retrieve update metadata and data boundaries from `/updates`.

### next layers

- `arad_indicators()` / `arad_search()` — indicator discovery and filtering.
- `arad_dimensions()` — dimensional metadata.
- `arad_tree()` — ARAD hierarchy metadata.
- `arad_snapshots()` — snapshot discovery.
- optional helpers for wide output, reproducible cache management, and update-aware workflows.

## Mapping from cnbrrr

| cnbrrr | aradR decision |
|---|---|
| `arad_get_data()` | Replace with `arad_get()` and a new retrieval/parsing implementation. |
| `arad_list_indicators()` / `arad_get_indicators()` | Redesign as discovery-focused API; do not preserve aliases. |
| `arad_indicators_dims()` | Retain capability under a clearer name. |
| `arad_indicators_tree()` | Retain capability under a clearer name. |
| `arad_parse_date()` | Keep as an internal implementation detail. |
| `arad_validate_indicators()` | Replace with stricter internal selector/input validation. |

## Reliability model

1. **Do not parse numeric values during CSV ingestion.** Read API fields as character data first.
2. **Validate structure explicitly.** Required columns, dates, numeric values, IDs, and duplicate observation keys are checked before returning data.
3. **Preserve genuine missing values.** Empty/NA/NULL value fields remain `NA_real_`; they are not automatically dropped or treated as errors.
4. **Chunk long requests deterministically.** In `strategy = "auto"`, explicit or update-derived date ranges are divided into bounded, non-overlapping intervals before `/data` calls. This directly targets the long-request failure observed in the predecessor implementation while limiting per-request data volume.
5. **Resolve missing range boundaries through `/updates`.** This allows full-history requests to be chunked without guessing start/end dates.
6. **Retry transient HTTP failures, never credentials errors.** API keys are read from `ARAD_API_KEY` by default and must never be written to logs, fixtures, or the repository.
7. **Attach diagnostics.** Returned data carries an `arad_diagnostics` attribute describing retrieval strategy, resolved range, and number of data requests.

## Known limitation before live benchmark

The safe default chunk size is provisional until Issue #1 is reproduced with confirmed failing indicator IDs and date ranges. Unit tests verify chunk construction and parsing deterministically; live API regression tests will tune the default and verify the known long-range failure once a confirmed fixture is available.

## Provenance

Selected design ideas are informed by the MIT-licensed `petrbouchal/cnbrrr` project. `aradR` uses a new implementation and public API; attribution requirements are documented in `NOTICE.md`.
