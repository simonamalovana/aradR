# Proposed first implementation goal

## Goal

**Make aradR installation, HTTP dependency compatibility, and routine
validation reliably release-ready without publishing a release.**

This is a proposal for review. Implementation remains unapproved until the
planning pull request is reviewed and merged and the product owner explicitly
authorizes implementation.

## Why this is first

The current package already has a broad retrieval and discovery API. Its most
immediate risks are narrower: `DESCRIPTION` does not prevent a known-bad
`httr2`/`curl` combination, the runtime guard needs evidence at the real
compatibility boundary, routine validation lacks one reproducible offline entry
point, and validation is coupled to a write-enabled release workflow that can
target a nonexistent tag. Resolving those risks is more important than adding
features or expanding the release matrix.

## Scope

### 1. Dependency compatibility

- Verify and harden the existing `httr2`/`curl` compatibility strategy against
  actual supported and invalid installations.
- Keep `curl` as a justified direct dependency.
- Keep `rlang` transitive through `httr2`; do not add it to `DESCRIPTION` unless
  aradR code begins calling the rlang API directly.
- Determine the simplest correct minimum-version declarations in `DESCRIPTION`
  that prevent known-bad combinations wherever R's dependency solver can
  reasonably enforce the constraint. Avoid speculative or unnecessarily high
  floors.
- Retain a pre-request runtime capability/version diagnostic for cases that
  installation metadata cannot prevent, especially when an old `curl` namespace
  is already loaded after an on-disk update.
- Make dependency errors state the incompatible installed/loaded versions or
  missing capability and tell the user exactly which package to update and when
  to restart R.

### 2. Reproducible routine validation

- Establish and document one offline validation entry point covering unit tests,
  a source build, clean-library install/load smoke testing, and the appropriate
  package checks.
- Ensure the routine path is deterministic, keeps artifacts outside the source
  tree, and produces a concise release-readiness result.
- Require no ARAD credentials for standard local, pull-request, or push
  validation. Keep every live test separate, secret-gated, and opt-in.

### 3. CI and release safety

- Decouple package/binary validation from tag checkout, GitHub Release lookup,
  asset upload, and other publication steps.
- Make normal pull-request and push workflows read-only. They must never target
  a release tag, create a release, or upload release assets.
- Keep tag and release publication as a distinct, explicit, owner-authorized
  action outside routine validation.

### 4. Compatibility evidence

- Exercise the current supported dependency stack and the important known
  boundary around `httr2` 1.2.0 and `curl` 6.4.0/capability availability.
- Test valid stacks as well as a known invalid stack; do not rely only on helper
  arguments that simulate version strings.
- Preserve R >= 4.1 if it can be supported with a small, reproducible validation
  job. A large cross-platform or release matrix is not required for this goal.
- If R 4.1 cannot be maintained cleanly without disproportionate complexity,
  stop, record the evidence, and request the smallest owner decision. Do not
  silently raise the R floor.

### 5. Documentation hygiene necessary for this goal

- Align README, troubleshooting guidance, and NEWS with dependency installation,
  loaded-namespace mismatch behavior, and actionable remediation.
- Resolve generated documentation drift only where necessary to establish a
  clean and intentional source of truth for this goal.
- Do not undertake broad editorial work, architecture rewriting, or pkgdown
  redesign.

### 6. Completion output

- Do not bump the version, create a tag or GitHub Release, submit to CRAN, or
  publish any artifact.
- At completion, update `docs/CODEX_STATUS.md` with exact stack versions,
  commands, results, skipped evidence, and remaining blockers, and provide a
  release-readiness assessment rather than performing a release.

## Explicitly deferred

- new package features or exports;
- cache architecture redesign;
- broad timeout or retry policy changes;
- broad live ARAD audits;
- CRAN submission work beyond useful package-check hygiene;
- large multi-OS matrices unless evidence proves they are necessary;
- old branch cleanup; and
- versioning, tags, assets, or release publication.

## Definition of done

- Known invalid `httr2`/`curl` stacks either cannot install under declared
  constraints where feasible or fail before a request with a clear, actionable
  diagnostic.
- Valid supported stacks install, load, and pass the relevant offline tests.
- `curl` remains a justified direct dependency and `rlang` remains transitive
  unless direct code use is introduced and documented.
- One documented routine command/path runs offline unit tests, source build,
  clean install/load smoke, and appropriate package checks successfully.
- Normal CI is read-only and cannot target tags or publish release assets; live
  validation remains visibly separate and opt-in.
- README, troubleshooting, NEWS, and necessary generated documentation accurately
  describe dependency constraints and remediation.
- The exported API, return contracts, defaults, condition classes, and established
  package behavior remain unchanged.
- No version, tag, GitHub Release, CRAN submission, or other release is created.
- `docs/CODEX_STATUS.md` records exact evidence and remaining release blockers.
