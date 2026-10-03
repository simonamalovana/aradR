# aradR 0.2.0

**Author and maintainer:** Simona Malovana

`aradR 0.2.0` is the first stable release of the independent reliability-first R client and toolkit for the **public Czech National Bank ARAD API**.

## Highlights

- robust bounded retrieval for long ARAD histories with explicit integrity checks;
- character-first parsing that preserves genuine missing values while rejecting malformed observations;
- human-readable scoped discovery through `arad_catalog()`, `arad_find()` and `arad_info()`;
- deterministic relevance ordering with `relevance_score` and `matched_in` provenance;
- snapshot-aware retrieval and safe long-to-wide reshaping;
- explicit session/disk caching, disabled by default;
- retrieval diagnostics for reproducible analytical workflows;
- compatibility with both the legacy workplace HTTP stack (`httr2 0.2.2`) and current supported `httr2`/`curl` stacks;
- release validation covering current R on Ubuntu, macOS and Windows, pkgdown documentation, and a separate Windows R 4.1 compatibility build.

## Public-package scope

Version 0.2.0 targets the public CNB ARAD API only. Organization-internal endpoints, integrated Windows/Negotiate authentication, proxy-specific private-network behavior, and related internal diagnostics are intentionally outside this package and can evolve separately as a thin integration layer on top of the public core.

## Reliability evidence

The bounded live reliability calibration completed on 24 August 2026 covered monthly, quarterly, annual and daily data, long histories across several ARAD scopes, single- and multi-indicator requests, and snapshot-backed retrieval. The production 3650-day chunk size matched finer references across the completed matrix with no key, missing-value or numeric mismatches.

Live UX acceptance also covered catalogue browsing and end-to-end find → info → get → wide workflows against the public ARAD API.

## Compatibility and diagnostics

- R >= 4.1.0 remains supported.
- `httr2 >= 0.2.2` remains supported.
- With `httr2 >= 1.2.0`, aradR verifies before a network request that `curl >= 6.4.0` and `curl_modify_url()` are available.
- Incompatible loaded HTTP stacks fail early with an actionable update-and-restart message rather than a low-level curl error.
- API keys and common credential-bearing diagnostics are redacted from surfaced transport/server messages.

## Installation

After the final release is published, install the released package from GitHub using the release tag, or install the current repository version with:

```r
pak::pak("simonamalovana/aradR")
# alternatively:
remotes::install_github("simonamalovana/aradR")
```

Configure the ARAD API key outside source code, preferably through `ARAD_API_KEY` in `~/.Renviron`.

## Provenance

`aradR` is an independent project authored and maintained by Simona Malovana. Selected design ideas were informed by the MIT-licensed `petrbouchal/cnbrrr` project by Petr Bouchal; required attribution is retained in `NOTICE.md`.

## License

MIT. See `LICENSE.md`.
