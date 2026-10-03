# Next implementation goal

## Goal

**Finish release readiness for the external/public aradR 0.2.0 package.**

The package is now deliberately scoped to the public Czech National Bank ARAD API. Internal endpoint support and integrated authentication are a separate future package/integration problem and must not block or expand the 0.2.0 public release.

## Scope

### 1. Verify the external-only split

- Confirm no exported function, ordinary user documentation, test, or pkgdown reference depends on `arad_use_internal()`, `arad_use_external()`, endpoint mode, Negotiate authentication, or proxy-bypass transport.
- Confirm the public CNB ARAD API remains the default endpoint.
- Keep explicit `base_url` arguments only as low-level testing/advanced hooks; do not add integrated private-network behavior back into the public package.

### 2. Dependency compatibility

- Preserve the existing `httr2`/`curl` compatibility guard and actionable update/restart diagnostics.
- Keep `curl` direct and `rlang` transitive unless the implementation starts calling the rlang API directly.
- Preserve R >= 4.1 unless evidence requires a separate owner decision.

### 3. Deterministic release-readiness validation

- Run offline unit tests and source-package checks without ARAD credentials.
- Validate package installation/load and generated documentation consistency.
- Keep live public-ARAD validation separate, bounded, secret-gated and opt-in.
- Keep routine CI read-only and separate from release/tag publication.

### 4. External-only documentation

- README, NEWS, DESCRIPTION, vignette, troubleshooting and pkgdown must consistently describe aradR as a public ARAD client.
- Do not document organization-internal endpoint addresses, integrated authentication, or private proxy behavior in the public package.
- Historical planning/audit documents may describe earlier prerelease experiments, but current status and release guidance must clearly supersede them.

## Definition of done

- The exported API contains only the intended public ARAD client functions.
- Offline tests/checks pass on the intended supported stack.
- No ordinary documentation or generated reference page exposes the removed internal endpoint mode.
- Public ARAD discovery → inspect → retrieve → reshape workflows remain unchanged and tested.
- Known `httr2`/`curl` incompatibilities still fail early with actionable diagnostics.
- Remaining blockers, if any, are external-package release issues rather than internal-network integration work.

Versioning, tags, GitHub Releases, CRAN submission, or other publication actions require a separate explicit owner decision.
