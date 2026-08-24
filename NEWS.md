# aradR (development version)

## Reliability core

- Added the initial public API: `arad_get()` and `arad_updates()`.
- Added strict exactly-one-selector validation for indicator, set, base, and user-selection requests.
- Added character-first ARAD CSV ingestion followed by explicit date and numeric parsing.
- Added integrity checks for required columns, malformed non-missing values, and duplicate observation keys.
- Added deterministic chunking for long histories and `/updates`-based boundary discovery.
- Added request retries, API-key redaction, retrieval diagnostics, unit tests, and an opt-in live long-range regression test.
