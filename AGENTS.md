# aradR autonomous development instructions

These instructions apply to the entire repository. More specific `AGENTS.md`
files may refine them for a subtree.

## Package purpose and architecture

- `aradR` is an independent, reliability-first R client for discovering,
  retrieving, validating, caching, and reshaping Czech National Bank ARAD data.
- Treat `R/query.R` as input/query construction, `R/http.R` and `R/config.R` as
  transport and endpoint policy, `R/parse.R` and `R/metadata.R` as strict
  response parsing, `R/retrieve.R` as retrieval orchestration, `R/discovery.R`
  as the high-level discovery workflow, `R/cache.R` as explicit raw-response
  caching, and `R/reshape.R` as post-retrieval presentation. `R/audit.R` and
  `tools/` support reliability validation rather than the ordinary user path.
- Preserve the reliability model in `docs/architecture.md`: character-first
  parsing, explicit schema and key validation, genuine-`NA` preservation,
  deterministic bounded retrieval, conservative duplicate handling, redacted
  diagnostics, and caching that is off by default.

## Public API and compatibility

- The exported API is the contract recorded in `NAMESPACE` and the matching
  `man/` pages. Do not add, remove, rename, or alter an exported function,
  argument/default, returned column/type/order, condition class, cache default,
  endpoint default, or diagnostics attribute without explicit product-owner
  approval and migration documentation.
- Do not silently change public behavior. A bug fix that changes observable
  results needs a regression test, `NEWS.md` entry, documentation review, and a
  clear compatibility assessment.
- Preserve the stable long-form retrieval schema and the public `base_id`
  representation even when upstream ARAD field names vary. Continue accepting
  already-supported legacy and current upstream schemas unless removal is
  explicitly approved.
- Prefer internal helpers over new exports. New features and convenience APIs
  are product decisions, not autonomous maintenance decisions.

## Dependency strategy

- Keep `DESCRIPTION` accurate and minimal. Do not introduce a dependency merely
  for a small operation that base R or an existing dependency can perform.
- A package used directly through `pkg::fun`, imported symbols, or required at
  runtime must be declared. Do not promote a transitive dependency to a direct
  dependency without a demonstrated direct contract.
- Support the declared floor of R 4.1.0 and `httr2 >= 0.2.2` until the product
  owner approves raising it. Validate both the workplace-compatible legacy HTTP
  stack and the current HTTP stack. `curl` is direct because transport capability
  is inspected/configured; `rlang` is currently transitive through `httr2`, and
  must remain transitive unless aradR starts calling its API directly.
- HTTP compatibility checks must test capability as well as version, fail before
  a network call, identify loaded versus installed package state correctly, and
  give safe, actionable remediation. Never work around incompatibility by
  mutating a user's library or loading packages at package startup.

## Errors, startup, and secrets

- Package load/attach must be quiet and must not contact ARAD, inspect
  credentials, write caches, change options, or eagerly reject dependency
  combinations. Validate only when the relevant operation is invoked.
- Fail loudly on malformed input, invalid schemas/dates/non-missing numerics,
  unexpected indicators, and conflicting observation keys. Preserve genuine
  missing values and safely collapse only demonstrably identical duplicates.
- Use stable `arad_*_error` condition classes and actionable messages. Retain
  useful endpoint/status/context while redacting API keys, query-string secrets,
  internal addresses when appropriate, and oversized/untrusted response bodies.
- Never commit API keys, credentials, internal endpoint addresses, `.Renviron`,
  live response artifacts containing secrets, or realistic secret placeholders.

## Tests and live-network rules

- Every behavior change needs deterministic `testthat` coverage. Use the
  injectable request function and synthetic raw fixtures for unit tests; keep
  offline tests independent of DNS, ARAD availability, credentials, time, and
  mutable upstream data.
- Ordinary tests and `R CMD check` must remain offline. Live tests must be
  explicitly opted in with the existing environment flags/workflows, require a
  repository secret rather than an embedded key, use bounded/rate-limited
  requests, and produce redacted artifacts.
- Do not broaden live matrices, reduce delays, add retries, or repeatedly rerun
  ARAD calls autonomously. A retrieval/transport change may justify one bounded
  live validation after offline checks; broad stress/calibration runs and their
  request budgets require product-owner approval.
- A skipped live test is not evidence that live access works. Record the tested
  endpoint, date, stack, scope, and result for every release-relevant live run.

## Commands and validation

Run from the repository root. Keep build/check artifacts outside the source tree.

- Unit tests: `Rscript -e 'testthat::test_local(".")'`
- Regenerate documentation when roxygen comments change:
  `Rscript -e 'roxygen2::roxygenise(".")'`, then inspect all generated diffs.
- Build: `R CMD build . --no-manual --no-build-vignettes`
- Source-package check: `R CMD check --no-manual --as-cran <tarball>`
- Documentation/site validation when relevant:
  `Rscript -e 'pkgdown::build_site(new_process = FALSE)'`
- Optional static checks, when configured/available, supplement rather than
  replace `R CMD check`. Do not make unrelated cleanup changes just to satisfy a
  new tool.

Before declaring a release candidate ready, validate offline tests and checks on
the declared minimum R/dependency stack and current R/dependencies, the supported
OS matrix, installation from a source tarball, documentation generation/site,
and the separately authorized bounded live smoke/audit workflows.

## Documentation

- Keep roxygen sources, generated `man/*.Rd`, `NAMESPACE`, README examples,
  vignette, architecture/troubleshooting guidance, `_pkgdown.yml`, and `NEWS.md`
  synchronized with user-visible behavior. Never hand-edit generated files when
  a roxygen source exists.
- Examples used by package checks must be offline, deterministic, or explicitly
  `\dontrun{}` when credentials/network are intrinsically required. Never imply
  that ARAD-reported availability horizons are necessarily observed-data dates.
- Document supported versions as tested compatibility claims, not assumptions.

## Version and release discipline

- Do not change `DESCRIPTION` version, create/push a tag, create/upload a release
  asset, publish a release, submit to CRAN, or trigger a workflow with write-side
  release effects unless the product owner explicitly approves that exact
  release action.
- Release readiness work does not itself authorize a release. Keep prerelease
  labels, `NEWS.md`, release notes, tags, workflow defaults, and binary artifact
  expectations consistent before seeking approval.
- Never reuse or move a published tag. Record known failures and rerun the full
  relevant matrix after the final release commit, not merely on an earlier RC.

## Git and workflow rules

- Start from current `main`; fetch and inspect active topic/RC/audit branches
  before implementing so already-landed or still-useful work is not duplicated.
- Use a focused branch and commits. Do not rewrite shared history, force-push,
  delete remote branches/tags, or commit generated check/build/cache artifacts.
- Inspect `git status` before and after checks. Do not discard user changes.
  Commit only task-relevant files, with tests/docs alongside implementation.
- CI must be least-privilege. Routine pushes must not accidentally attempt a
  release, attach assets, require unavailable secrets, or target a nonexistent
  tag. Keep live/release workflows manually gated unless explicitly designed
  otherwise.

## Autonomous versus product-owner decisions

Autonomous maintenance may investigate, write plans, improve deterministic
tests, correct documentation to match established behavior, fix narrowly proven
internal defects without compatibility impact, and harden read-only CI checks.
Escalate before changing public behavior/API/schema, compatibility floors,
dependency policy, authentication/endpoint/security policy, default timeout,
retry/chunk/cache behavior, live request volume, supported platforms, package
ownership/positioning, release scope/version/channel, tags, artifacts, or CRAN
submission. When evidence is ambiguous, document options and ask rather than
silently choosing a product policy.
