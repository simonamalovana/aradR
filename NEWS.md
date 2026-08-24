# aradR (development version)

## Reliability core

- Added the initial public API: `arad_get()` and `arad_updates()`.
- Added strict exactly-one-selector validation for indicator, set, base, and user-selection requests.
- Added character-first ARAD CSV ingestion followed by explicit date and numeric parsing.
- Added integrity checks for required columns, malformed non-missing values, and duplicate observation keys.
- Added deterministic chunking for long histories and `/updates`-based boundary discovery.
- Added request retries, API-key redaction, retrieval diagnostics, unit tests, and an opt-in live long-range regression test.

## Discovery and metadata

- Added `arad_indicators()` for basic indicator metadata.
- Added `arad_dimensions()` for base/dimension metadata.
- Added `arad_tree()` for ARAD hierarchy paths.
- Added `arad_snapshots()` for snapshot discovery.
- Added `arad_search()` for scoped local search over indicator IDs and names, including frequency filtering.

## Caching and validation

- Added explicit `none`, `session`, and `disk` raw-response cache modes; caching remains disabled by default.
- Added `arad_cache_clear()` and configurable cache age/location.
- Cache entries are credential-separated using a one-way API-key hash; API keys are not persisted.
- Added automated tests for metadata schemas, caching behavior and malformed metadata.

## Live audit

- Added stratified audit sampling by frequency and history length.
- Added direct-vs-standard-vs-fine-chunk comparison logic that distinguishes key, missing-value and numeric mismatches.
- Added `tools/live-audit.R` and a manual GitHub Actions workflow that uploads audit artifacts.
- The live audit is deliberately sampled and rate-limited to avoid excessive ARAD API load.
