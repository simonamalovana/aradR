# CRAN readiness — aradR 0.2.0

Status: final pre-submission validation in progress. This checklist covers the external/public package only.

## Package identity and ownership

- [x] `aradR` is an independent personal open-source package authored and maintained by Simona Malovana.
- [x] `Authors@R` identifies Simona Malovana as author/maintainer with a maintainer email address.
- [x] MIT licensing is declared as `MIT + file LICENSE`.
- [x] `LICENSE` names Simona Malovana as the copyright holder.
- [x] Third-party provenance is retained in the distributed package under `inst/NOTICE`.
- [x] README and user documentation explicitly state that aradR is not official Czech National Bank software and does not imply CNB endorsement.
- [x] Provenance review completed on 2026-10-04. The current `aradR` codebase is a substantially different reliability-first implementation with its own retrieval, parsing, caching, discovery and diagnostics architecture. Early design review and selected implementation ideas were informed by the MIT-licensed `petrbouchal/cnbrrr` package.
- [x] Petr Bouchal is conservatively credited as an `Authors@R` contributor (`ctb`, ORCID 0000-0002-0471-716X), and the upstream MIT attribution remains in `NOTICE.md` and distributed `inst/NOTICE`.

## Package name

- [x] Current CRAN package list re-checked on 2026-10-04; no package named `aradR` was found.
- [x] CRAN Archive searches on 2026-10-04 returned no evidence of a historical `aradR` package.
- [x] Current Bioconductor 3.23 software package list re-checked on 2026-10-04; no package named `aradR` was found.

## Dependencies and portability

Strong dependencies:

- `curl`
- `httr2 (>= 0.2.2)`
- `readr`
- `tibble`

Suggested dependencies:

- `knitr`
- `rmarkdown`
- `testthat (>= 3.0.0)`

- [x] All declared dependencies are standard CRAN packages.
- [x] Package targets `R >= 4.1.0`.
- [x] Existing release-readiness CI has passed on Ubuntu, macOS and Windows.
- [x] A dedicated Windows R 4.1.0 compatibility build/install test has passed with the legacy supported `httr2 0.2.2` stack.
- [x] Dedicated Ubuntu R-devel source-package CRAN gate builds the source tarball with `R CMD build` and checks that tarball with `R CMD check --as-cran`.
- [x] Ubuntu R-devel CRAN gate has passed with 0 ERRORs, 0 WARNINGs and 1 NOTE; the sole NOTE is the expected `New submission` incoming-feasibility note.
- [x] Windows R-devel source-tarball `R CMD check --as-cran` gate added for final pre-submission validation.
- [ ] Final Windows R-devel gate must pass on the exact pre-submission branch/tarball.

## Internet and external API behaviour

- [x] Routine unit tests do not require an ARAD API key.
- [x] Live regression/audit tests are explicit opt-in tests and are not run by default.
- [x] Network and proxy failures are converted into informative package-specific errors.
- [x] Authentication errors redact the API key from surfaced diagnostics.
- [x] Requests have bounded timeout/retry behaviour.
- [x] Documentation examples/vignettes do not execute live ARAD calls during package checks.
- [x] The package warns users not to overload the public API and uses bounded retrieval for long histories.

## User files and caching

- [x] Caching is disabled by default.
- [x] Disk caching uses `tools::R_user_dir("aradR", which = "cache")` by default.
- [x] Cache lifecycle is user-controlled through `arad_cache_clear()`.
- [x] API keys are not stored in cached response files.

## Documentation

- [x] Every currently exported function has an `.Rd` help topic.
- [x] pkgdown reference is grouped into discovery, retrieval and caching sections.
- [x] Getting-started vignette covers installation, API key configuration, discovery, inspection, retrieval, reshape, snapshots, caching and diagnostics.
- [x] Dedicated `Finding data in ARAD` vignette added.
- [x] Dedicated `Reliability and reproducibility` vignette added.
- [x] README rewritten as a concise package landing page.
- [x] pkgdown site is published through GitHub Pages.
- [x] Canonical documentation URL is `https://simonamalovana.com/aradR/`.
- [x] The canonical documentation URL is included in `DESCRIPTION` and `_pkgdown.yml`.
- [ ] After CRAN acceptance, switch pre-release installation wording/badges to the CRAN release where appropriate.

## Package size and repository hygiene

- [x] Repository is small and well below CRAN package-size concerns.
- [x] Development-only GitHub/workflow/docs files are excluded from the source package through `.Rbuildignore` where appropriate.
- [x] The GitHub-only `AUTHORS.md` is excluded from the source tarball; author metadata remains in `Authors@R`.
- [x] The distributed third-party notice is under `inst/` and is therefore retained in the built package.
- [x] The R-devel gates retain the actual source tarball and complete check directory as CI artifacts for inspection.
- [ ] Inspect the final source tarball artifact once more after all final CI gates pass.

## Submission material

- [x] `cran-comments.md` prepared with test environments, check result, internet/API behavior and new-submission explanation.
- [x] Public documentation website published and included in package metadata.
- [x] Package-name availability re-checked immediately before final validation.
- [ ] Merge final pre-submission PR only after all CI gates are green.
- [ ] Submit the resulting source package through the CRAN submission form and confirm the submission email.

## Explicitly not part of this release

- internal/private ARAD endpoints;
- integrated Windows/Negotiate authentication;
- organization-specific proxy behaviour;
- internal CNB branding or claims of official CNB support.
