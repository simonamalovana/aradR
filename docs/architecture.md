# aradR architecture

## Purpose and scope

`aradR` is an independent, reliability-first R client and toolkit for the **public Czech National Bank ARAD API**. It is not a compatibility fork of `cnbrrr`; the package uses a new public API and implementation focused on explicit validation, reproducible retrieval, human-readable discovery, and maintainable testing/documentation.

Version 0.2.0 deliberately covers the public ARAD service only. Organization-internal endpoints, integrated Windows authentication, proxy-specific private-network transport, and related internal diagnostics belong in a separate thin integration package rather than the public core.

## Public API

### Discover and understand indicators

- `arad_catalog()` — browse one row per indicator within an explicit ARAD scope, including hierarchy and availability metadata.
- `arad_find()` — human-readable scoped discovery across indicator names/IDs, hierarchy paths, and optional dimension metadata, with deterministic relevance ordering and match provenance.
- `arad_info()` — inspect one selected indicator through a compact summary plus detailed dimensions and update metadata.
- `arad_search()` — lightweight scoped search over indicator names/IDs.
- `arad_indicators()` — basic indicator metadata from `/indicators`.
- `arad_dimensions()` — dimensional metadata from `/indicators-dims`.
- `arad_tree()` — ARAD hierarchy paths from `/indicators-tree`.
- `arad_snapshots()` — snapshot discovery from `/snapshots`.

### Retrieval and availability

- `arad_get()` — retrieve time series from `/data` using exactly one selector (`indicator_ids`, `set_id`, `base_id`, or `selection_id`).
- `arad_updates()` — retrieve update metadata and ARAD-reported data boundaries from `/updates`.

`data_from` and `data_to` describe ARAD-reported availability. In particular, `data_to` can extend into forecast/report horizons and is not necessarily the latest observed historical date.

### Analytical helpers

- `arad_wide()` — safe long-to-wide reshaping with snapshot-aware series naming.

### Reproducibility

- explicit raw-response caching: `none`, `session`, or `disk`;
- `arad_cache_clear()` for cache lifecycle management;
- caching is off by default to avoid accidental staleness;
- retrieval diagnostics are attached to `arad_get()` output and preserved by `arad_wide()`.

## Endpoint and HTTP dependency policy

The public CNB ARAD endpoint is the default package endpoint. Explicit `base_url` arguments remain low-level testing/advanced hooks; the package does not implement integrated private-network authentication.

The declared compatibility floor remains R >= 4.1.0 and httr2 >= 0.2.2. aradR supports the legacy httr2 0.2.2 workplace stack and also current httr2 versions. For httr2 >= 1.2.0, aradR verifies before a network request that curl >= 6.4.0 and `curl_modify_url()` are available; incompatible loaded stacks fail early with an actionable update-and-restart error.

## Mapping from cnbrrr

| cnbrrr | aradR decision |
|---|---|
| `arad_get_data()` | Replace with `arad_get()` and a new retrieval/parsing implementation. |
| `arad_list_indicators()` / `arad_get_indicators()` | Replace with the scoped discovery stack (`arad_catalog()`, `arad_find()`, `arad_info()`, `arad_indicators()`, `arad_search()`); do not preserve aliases. |
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

The audit remains bounded and rate-limited because ARAD asks clients not to overload the API. Broader live audits remain explicit release/reliability tools rather than routine package checks.

## Validation model

Routine pull requests and relevant pushes to `main` run read-only R CMD checks. Release-candidate validation adds macOS, Windows, and pkgdown checks. A separate read-only Windows R 4.1 compatibility workflow verifies that the declared legacy workplace stack can build, install, and load the package. Publication of tags or GitHub Release assets is intentionally separate from validation.

## User-facing workflow

The package is organised around a short browse → find → inspect → retrieve → reshape workflow:

1. configure `ARAD_API_KEY`;
2. browse a known scope with `arad_catalog()`;
3. find human-readable candidates with `arad_find()`;
4. inspect a selected series with `arad_info()`;
5. retrieve with `arad_get()`;
6. optionally reshape with `arad_wide()`;
7. use diagnostics, caching, snapshots, and update metadata as needed.

The Get Started vignette and troubleshooting guide are the primary onboarding documents. `_pkgdown.yml` defines the public website structure.

## Later layers

Potential additions should be driven by a clear user benefit and should not duplicate simple R-side transformations. Candidates include update-aware refresh helpers, selective support for `/data-trans` if it proves materially useful beyond `arad_wide()`, and a separate internal integration package built on top of the public core.

## Provenance

Selected design ideas are informed by the MIT-licensed `petrbouchal/cnbrrr` project. `aradR` uses a new implementation and public API; attribution requirements are documented in `NOTICE.md`.
