# CRAN readiness — aradR 0.2.0

Status: preparation in progress. This checklist covers the external/public package only.

## Package identity and ownership

- [x] `aradR` is an independent personal open-source package authored and maintained by Simona Malovana.
- [x] `Authors@R` identifies one human author/maintainer with an email address.
- [x] MIT licensing is declared as `MIT + file LICENSE`.
- [x] `LICENSE` names Simona Malovana as the copyright holder.
- [x] Third-party provenance is retained in the distributed package under `inst/NOTICE`.
- [x] README and user documentation explicitly state that aradR is not official Czech National Bank software and does not imply CNB endorsement.
- [ ] Confirm whether any source code or substantial implementation was copied/derived from `petrbouchal/cnbrrr` rather than only informed by it. If yes, add the upstream author as an `Authors@R` contributor (`ctb`) and retain attribution with the affected material as required by the MIT license.

## Package name

- [x] No current CRAN package named `aradR` was found on 2026-10-03.
- [x] No current Bioconductor software package named `aradR` was found on 2026-10-03.
- [ ] Re-check current CRAN, CRAN Archive and Bioconductor immediately before first submission because package names are persistent.

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
- [x] Dedicated R-devel source-package CRAN gate added: it builds the source tarball with `R CMD build` and checks that tarball with `R CMD check --as-cran`.
- [x] First R-devel CRAN-gate run passed on 2026-10-03 using R Under development (2026-10-02 r90631) on Ubuntu 24.04.5: 0 ERRORs, 0 WARNINGs, 1 NOTE.
- [x] The sole NOTE was the expected CRAN incoming-feasibility note identifying the maintainer and `New submission`; package namespace, dependencies, tests, vignettes, PDF manual and HTML manual were all OK.
- [ ] Run Win-builder/R-devel on the final source tarball before submission.

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
- [x] pkgdown site is published through GitHub Pages and the deployment completed successfully on 2026-10-04.
- [x] Canonical documentation URL is `https://simonamalovana.com/aradR/`.
- [x] The canonical documentation URL is included in `DESCRIPTION` and `_pkgdown.yml`.
- [ ] After CRAN acceptance, switch pre-release installation wording/badges to the CRAN release where appropriate.

## Package size and repository hygiene

- [x] Repository is small (approximately 201 KB in GitHub repository metadata on 2026-10-03), far below CRAN package-size concerns.
- [x] Development-only GitHub/workflow/docs files are excluded from the source package through `.Rbuildignore` where appropriate.
- [x] The GitHub-only `AUTHORS.md` is excluded from the source tarball; author metadata remains in `Authors@R`.
- [x] The distributed third-party notice is under `inst/` and is therefore retained in the built package.
- [x] The R-devel gate retains the actual source tarball and complete check directory as CI artifacts for inspection.
- [ ] Inspect the final submission tarball contents once more immediately before submission.

## Remaining submission gates

Before submitting 0.2.0 to CRAN:

1. confirm the exact `cnbrrr` provenance/derived-code status and add contributor attribution if required;
2. run Win-builder/R-devel against the final tarball;
3. re-check package-name availability;
4. prepare `cran-comments.md` with the actual final check environments/results;
5. submit the source package through the CRAN submission form and confirm the submission email.

## Explicitly not part of this release

- internal/private ARAD endpoints;
- integrated Windows/Negotiate authentication;
- organization-specific proxy behaviour;
- internal CNB branding or claims of official CNB support.
