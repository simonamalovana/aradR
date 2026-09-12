# Codex status

## Current authorization

Repository audit, release/reliability assessment, persistent instructions, and
planning are complete as a baseline exercise. **No implementation goal is
approved yet. No release goal is approved yet.** `docs/NEXT_GOAL.md` is a
proposal only and must not be treated as authorization to change package
behavior, versions, tags, release assets, or publication state.

The proposed first goal has been narrowed to: **Make aradR installation, HTTP
dependency compatibility, and routine validation reliably release-ready without
publishing a release.** Its scope is limited to dependency constraints and
runtime mismatch diagnostics, one reproducible offline validation path, safe
read-only routine CI, focused compatibility evidence, and only the documentation
hygiene necessary for those outcomes. Implementation remains unapproved until
this planning pull request is reviewed and merged and the product owner
explicitly authorizes it.

## Baseline

- Audited revision: `7d67dca` (the checked-out `work` branch and remote `main`
  pointed to the same commit on 12 September 2026).
- Declared package version: `0.2.0`, while README and NEWS still call it a
  release candidate.
- Published prereleases found: `v0.2.0-rc1` and `v0.2.0-rc2`; no final release
  was created by this audit.
- All closed feature/fix/release PRs examined were squash-merged into `main`.
  The only open PR was a historical live-audit trigger branch; it contains no
  package implementation needed by `main`.
- The most recent `main` workflow run failed because an ordinary push invoked
  the Windows binary release workflow with default tag `v0.2.0-rc3`, which did
  not exist. This is a release-process defect, not a package-test result.

## Guardrail

Before autonomous implementation starts, the product owner should explicitly
approve the proposed goal. Until then, work is limited to review and planning:
no package source, tests, workflows, release metadata, versions, tags, assets,
or publication state may be changed.

If approved, completion must record exact offline validation commands, actual
`httr2`/`curl`/R versions and results, any R 4.1 limitation, skipped live or
platform evidence, and remaining release blockers here. Completion produces a
release-readiness assessment only; it does not authorize or perform a release.
