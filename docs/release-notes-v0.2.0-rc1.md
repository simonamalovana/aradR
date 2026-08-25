# aradR 0.2.0 RC1

**Author and maintainer:** Simona Malovana

`aradR 0.2.0 RC1` is the first release candidate of the independent reliability-first R client and toolkit for the Czech National Bank ARAD API.

## Highlights

- robust bounded retrieval for long ARAD histories;
- strict parsing and integrity checks that preserve genuine missing values;
- human-readable scoped discovery through `arad_catalog()`, `arad_find()` and `arad_info()`;
- deterministic relevance ranking with explainable `relevance_score` and `matched_in` output;
- snapshot support, caching and safe long-to-wide reshaping;
- live-tested browse → find → info → get → wide workflows against the current ARAD API;
- release-candidate validation on Ubuntu, macOS and Windows plus a clean pkgdown build.

## Status

This is a pre-release intended for testing and feedback before the final `v0.2.0` release.

`aradR` is authored and maintained by Simona Malovana. It is an independent project and is not currently an official CNB-maintained package.

The project was informed by the MIT-licensed `cnbrrr` package by Petr Bouchal; required upstream attribution is retained in `NOTICE.md`.
