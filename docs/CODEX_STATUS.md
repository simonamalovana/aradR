# Codex status

## Current authorization

The product owner has explicitly decided that `aradR 0.2.0` is the **external/public package only** and should be completed and released before any organization-internal ARAD integration work.

Internal endpoint support, integrated Windows/Negotiate authentication, proxy-specific private-network behavior, and related diagnostics are out of scope for this repository's 0.2.0 release path. They should be developed separately as a thin internal package or integration layer that depends on the public `aradR` core rather than duplicating it.

No final tag, GitHub Release, CRAN submission, or publication action is authorized merely by this status file; those remain separate owner decisions.

## External-only implementation

The public package now:

- uses the public CNB ARAD API as its only default endpoint;
- no longer exports `arad_use_internal()` or `arad_use_external()`;
- contains no integrated Negotiate authentication or private proxy-bypass transport;
- keeps explicit `base_url` arguments only as low-level testing/advanced request hooks;
- keeps the reliability/discovery/retrieval/cache core unchanged by the external/internal split;
- retains R >= 4.1.0 and the legacy `httr2 0.2.2` workplace stack;
- retains the pre-request modern `httr2`/`curl` compatibility guard with actionable remediation;
- documents the external-only scope consistently in README, NEWS, vignette, troubleshooting, architecture, DESCRIPTION and pkgdown configuration.

## Release-readiness validation — 3 October 2026

The release-readiness tree at commit `b79d7e15cc4edaa656f909be961c2bc0852e1955` passed all configured read-only gates:

- `R-CMD-check` run 49: **success** on Ubuntu current/release R;
- `Release candidate validation` run 8: **success**, including macOS current/release R, Windows current/release R, and pkgdown build/verification on Ubuntu;
- `Windows R 4.1 compatibility` run 11: **success**, including setup of R 4.1.0, workplace-compatible `httr2 0.2.2` / `readr 2.1.4` / `tibble 3.2.1`, Windows binary build, clean install/load verification, and workflow artifact creation.

The same substantive code/workflow changes had also passed an earlier complete three-gate run before final documentation alignment.

Routine validation is now read-only. The Windows R 4.1 workflow no longer checks out a release tag, uses `contents: write`, requires a live ARAD secret, or uploads an asset to a GitHub Release. Release publication is therefore separated from validation.

## Repository state

Historical reliability Issues #1 and #4 and release-candidate Issue #13 are closed as completed. Internal integration Issue #17 is closed in this repository as moved out of the public package scope. Historical live-audit trigger PR #5 is closed as obsolete and should not be merged.

A current `docs/release-notes-v0.2.0.md` draft is prepared for the eventual final release.

## Remaining step before publication

After the release-readiness PR is merged, publication itself remains a separate explicit owner decision. At that point the release operation should tag the exact approved `main` revision as `v0.2.0`, create the GitHub Release using the prepared final notes, and attach any intentionally published binary assets only as part of that explicit release action.
