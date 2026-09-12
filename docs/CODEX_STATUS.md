# Codex status

## Current authorization

Repository audit, release/reliability assessment, persistent instructions, and
planning are complete as a baseline exercise. **No implementation goal is
approved yet. No release goal is approved yet.** `docs/NEXT_GOAL.md` is a
proposal only and must not be treated as authorization to change package
behavior, versions, tags, release assets, or publication state.

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
approve a goal, its compatibility constraints, whether CI-only fixes are in
scope, and the live-test budget. Until then, work is limited to review and
planning.
