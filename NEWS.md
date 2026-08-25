# aradR 0.2.0 (release candidate)

**Author and maintainer:** Simona Malovana

## Discovery UX

- Added `arad_catalog()` for one-row-per-indicator browsing within an ARAD set, base, selection or explicit indicator list.
- Added `arad_find()` as a higher-level human-readable search across indicator names/IDs, ARAD hierarchy paths and, by default, base/dimension labels and values.
- `arad_find()` now returns deterministic, explainable relevance ordering through `relevance_score` and `matched_in`; exact ID/name matches rank ahead of partial name/ID, path and dimension matches, with stable tie-breaking.
- `arad_find(details = TRUE)` enriches only matched indicators with available data boundaries, latest update timestamp and snapshot-context count.
- Added `arad_info()` for inspecting selected candidate series through a compact summary plus detailed dimensions and raw update rows.
- Kept `arad_search()` unchanged as the fast, lightweight name/ID search for backwards compatibility.
- Clarified that ARAD-reported `data_to` can extend into forecast/report horizons and is not necessarily the latest observed historical date.
- Updated onboarding and reference documentation around a browse → find → inspect → retrieve workflow.

## Endpoint configuration and diagnostics

- Added `arad_use_internal()` as an explicit opt-in for organization-provided ARAD endpoints using integrated Negotiate authentication; the public ARAD endpoint remains the default.
- Internal mode bypasses configured proxies for ARAD requests and uses the current integrated login rather than storing a Windows password in R.
- Added `arad_use_external()` to restore the public endpoint and normal network handling.
- Improved pre-response HTTP diagnostics so proxy/connection failures retain the underlying redacted error instead of collapsing to a generic message; HTTP 401 responses are now classified as authentication errors.
- Internal endpoint addresses and credentials are not embedded in the public package.

## Live validation and compatibility

- Live 0.2.0 UX acceptance covers catalogue browsing and end-to-end find → info → get → wide workflows in balance-of-payments, financial-accounts and state-budget scopes.
- Added compatibility with the current `/indicators-dims` `base_code` response while preserving the stable public `base_id` column; legacy `base_id` responses remain supported.
- Release-candidate CI validates package checks across Ubuntu, macOS and Windows and builds the pkgdown documentation site before release.

# aradR 0.1.0 (pre-release)

**Author and maintainer:** Simona Malovana

## Reliability core

- Added the initial public API: `arad_get()` and `arad_updates()`.
- Added strict exactly-one-selector validation for indicator, set, base, and user-selection requests.
- Added character-first ARAD CSV ingestion followed by explicit date and numeric parsing.
- Added integrity checks for required columns, malformed non-missing values, and conflicting duplicate observation keys.
- Added deterministic chunking for long histories and `/updates`-based boundary discovery.
- Added safe collapse of identical cross-chunk boundary overlaps.
- Added request retries, API-key redaction, retrieval diagnostics, unit tests, and opt-in live regression tooling.

## Discovery and metadata

- Added `arad_indicators()` for basic indicator metadata.
- Added `arad_dimensions()` for base/dimension metadata.
- Added `arad_tree()` for ARAD hierarchy paths.
- Added `arad_snapshots()` for snapshot discovery.
- Added `arad_search()` for scoped local search over indicator IDs and names, including frequency filtering.

## User workflow

- Added `arad_wide()` for safe long-to-wide reshaping with automatic snapshot disambiguation.
- Added an end-to-end Get Started vignette.
- Added a troubleshooting guide, contribution guidance, package citation metadata, and pkgdown site configuration.
- Reworked the README around installation and a discovery → retrieval → reshape workflow.

## Caching and validation

- Added explicit `none`, `session`, and `disk` raw-response cache modes; caching remains disabled by default.
- Added `arad_cache_clear()` and configurable cache age/location.
- Cache entries are credential-separated using a one-way API-key hash; API keys are not persisted.
- Added automated tests for metadata schemas, caching behaviour, malformed metadata, and wide reshaping.

## Live audit

- Added stratified audit sampling and comparison logic that distinguishes key, missing-value, and numeric mismatches.
- Completed the initial M/Q/Y/D, multi-indicator and snapshot-backed reliability calibration.
- Retained the 3650-day production chunk size after exact agreement with finer references across the completed audit matrix.
- CI is cost-controlled: routine package PRs use one Ubuntu check, while the broader live audit and multi-OS checks are reserved for justified reliability/release validation.
