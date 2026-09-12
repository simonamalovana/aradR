# aradR reliability and release-readiness plan

Audit date: 12 September 2026. Baseline revision: `7d67dca`.

## Current package state

- The checked-out `work` branch, remote `main`, and audit baseline all identify
  commit `7d67dca`. `DESCRIPTION` declares aradR 0.2.0 and R >= 4.1.0; README,
  NEWS, and pkgdown still describe that version as unreleased/release candidate.
- Public API: discovery (`arad_catalog`, `arad_find`, `arad_info`,
  `arad_search`, `arad_indicators`, `arad_dimensions`, `arad_tree`,
  `arad_snapshots`), retrieval (`arad_get`, `arad_updates`), reshaping
  (`arad_wide`), endpoint mode (`arad_use_internal`, `arad_use_external`), and
  cache clearing (`arad_cache_clear`). The `NAMESPACE` exports match these names.
- Architecture is layered around query validation, httr2 transport,
  character-first parsing, deterministic chunked retrieval, scoped discovery,
  explicit raw caching, and snapshot-aware reshaping. Loading the package has no
  `.onLoad`/`.onAttach` hook and therefore no designed startup network or option
  side effects.
- Direct imports are `curl`, `httr2 (>= 0.2.2)`, `readr`, and `tibble`.
  `rlang` is not called directly: the `!!!` expression is passed into httr2's
  dynamic-dots interface, and httr2 supplies its rlang dependency. On current
  evidence rlang is a transitive concern, not an aradR direct dependency.
- Requests use a 30-second per-attempt timeout and httr2 retry policy with three
  tries. HTTP status errors are handled after disabling httr2's default status
  abort; 400, 401, and other errors receive package condition classes. Transport
  messages and bodies are bounded and API-key-redacted.
- Auto retrieval resolves missing bounds via `/updates` and uses non-overlapping
  inclusive chunks (default 3650 days). Parsers preserve genuine missing values,
  reject malformed values/schema and conflicting keys, and collapse identical
  duplicates. Retrieval diagnostics record strategy/range/request count.
- Offline tests use synthetic raw responses and an injected request function.
  One live regression test is opt-in. Separate live UX and staged audit tools
  exist and require `ARAD_API_KEY` in Actions.
- Two prereleases exist (`v0.2.0-rc1`, `v0.2.0-rc2`). There is no evidence of a
  final v0.2.0 release even though the package version lacks a development/RC
  suffix. No version, tag, or release was changed during this audit.

## Branch reconstruction and work outside main

The repository uses squash merges, so topic-branch commits are generally not
ancestors of `main` even when their resulting changes landed. Patch ancestry
alone is misleading; PR records and current-tree content were compared.

- `fix/http-dependency-compatibility` was closed through PR #18 and its change is
  on `main`: direct `curl` declaration, pre-request stack check, actionable
  error, tests, README/NEWS guidance, and Windows workflow adjustment.
- `release/0.2.0-rc` was closed through PR #14 and its ranking, availability,
  RC validation, docs, and tests are on `main`.
- Discovery UX, prerelease UX, internal endpoint/Windows SSO, base-code schema,
  cache/audit, chunk-overlap, attribution, and reliability branches correspond
  to closed PRs whose substantive results are present on `main`.
- `audit/live-run-20260824` remains an open PR (#5). Its net topic content is an
  obsolete `.github/live-audit-trigger` history used to request runs; it does not
  contain an unmerged package fix. It should not be merged as implementation.
- Accordingly, no important package behavior fix was found living only outside
  `main`. Old branches should nevertheless be retained/deleted only by owner
  decision, not automatically replayed.

## Reliability issues

1. **Post-fix release evidence is incomplete.** The HTTP compatibility PR passed
   its Ubuntu PR check, but the latest `main` event did not execute a meaningful
   package/release matrix because the Windows job failed at checkout.
2. **Retry policy is under-specified.** `req_retry(max_tries = 3)` delegates
   transient-status/backoff behavior to the installed httr2 version. There are
   no request-level tests proving which statuses/method failures retry, honoring
   `Retry-After`, or whether timeout semantics are acceptable on long ARAD calls.
3. **Timeout/retry are internal constants.** Thirty seconds and three tries may
   be reasonable but were not tied to recorded acceptance criteria, especially
   across slow public/internal endpoints. Changing them is a product decision.
4. **Redaction is targeted, not comprehensive.** API-key values and common
   `api_key=` text are covered; tests do not exercise encoded secrets, unusual
   server bodies, redirect/location diagnostics, or generated live artifacts.
5. **Internal endpoint support has a narrow evidence base.** It is documented as
   Windows-validated and dependent elsewhere on local libcurl/Kerberos. CI does
   not and realistically cannot validate an organization-private endpoint.
6. **Live fixtures are mutable.** Hard-coded scopes/indicators and current ARAD
   schema can drift. Dynamic fallback exists for one higher-frequency target,
   but results are not a durable release manifest and skipped secret-dependent
   jobs cannot establish service health.
7. **Caching reliability boundaries need explicit tests.** Cache corruption is
   treated as a miss, but concurrency/atomic writes, permissions, credential-hash
   threat assumptions, and cross-version/schema invalidation are not covered.

## Dependency and installation issues

- `httr2 >= 0.2.2` has no upper bound while compatibility is conditional:
  httr2 >= 1.2.0 requires curl >= 6.4.0 plus exported `curl_modify_url()`.
  `DESCRIPTION` only declares unversioned `curl`, so a normal dependency solver
  may accept an install that aradR rejects at first request. The runtime check is
  a useful diagnostic but does not itself make installation reliable.
- The check distinguishes a loaded namespace version from installed metadata,
  correctly recommending restart after update. However its thresholds are
  hard-coded from one compatibility incident and require matrix validation
  against actual old/current installations, not only injected version strings.
- The legacy Windows R 4.1 workflow installs exact versions indirectly from a
  mutable CRAN mirror snapshot/current binary availability, then asserts them.
  This is not a reproducible minimum-stack specification and can fail as the
  mirror changes.
- `curl` is justifiably direct: aradR inspects its namespace/capability and sets
  libcurl options via httr2. `rlang` should not be added solely because httr2's
  dynamic dots interpret `!!!`; aradR has no direct `rlang::` call today.
- Current `R CMD check` reports `curl` as an unused Import because the capability
  probe uses string-based namespace loading/export inspection rather than a
  statically visible `curl::` call. Dependency correctness and CRAN hygiene need
  to be reconciled without weakening the runtime diagnostic.
- README installation points to the moving repository default rather than an RC
  tag/release asset. This may be intended for development but is ambiguous for a
  frozen release candidate.
- Minimum versions for readr/tibble/curl are undeclared despite a stated R 4.1
  compatibility promise. Evidence is needed before deciding whether floors are
  necessary; avoid speculative constraints.

## Testing gaps

- No deterministic HTTP integration harness exercises actual httr2 retry,
  timeout, status, redirect, response-body, and redaction behavior.
- Compatibility helper unit tests simulate versions/capabilities but do not
  install and load both supported dependency stacks.
- Routine PR CI is Ubuntu release only and path-filtered. README, vignette,
  DESCRIPTION-adjacent release metadata, cache, and workflow-only changes can
  evade the checks most relevant to them; direct pushes have no normal package
  check.
- Full multi-OS checks and pkgdown checks are manual/RC-trigger based. There is no
  current-R devel/oldrel matrix, and R 4.1 is tested only in the artifact workflow.
- Live regression in `tests/testthat` skips unless several environment variables
  and a key are present. This separation is good, but there is no small standard
  public-endpoint smoke manifest with recorded freshness and expected invariants.
- No coverage report or explicit API contract snapshots are configured. Return
  schemas, attributes, ordering, and error-class compatibility are covered
  unevenly across exports.
- Disk-cache concurrency/atomicity, stale schema/version data, and permissions
  failures lack tests. Encoding and locale tests are useful but could include
  more real schema variants without using live calls.

## CI and release gaps

- `.github/workflows/windows-r41-binary.yaml` runs on a push to `main` when that
  workflow changes, defaults to `v0.2.0-rc3`, checks out that tag, requests
  `contents: write`, and uploads to a GitHub release. The 2 September 2026 push
  therefore failed immediately because rc3 did not exist. Validation and
  publication are dangerously coupled, and an ordinary push can have write-side
  release intent.
- The last successful release-candidate matrix predates the internal-mode and
  HTTP dependency changes. A successful topic PR check is not a final multi-OS,
  source-install, docs, legacy-stack, and live release gate for current `main`.
- There is no explicit automated release checklist verifying tag/version/NEWS
  alignment, clean tree, artifact provenance/checksums, or that a tag points to
  the fully validated commit.
- `R CMD check` uses `--no-manual`; no PDF/manual validation is recorded. CRAN
  submission may not be planned, but CRAN-style URL, incoming-feasibility,
  spelling, and reverse/compatibility checks are not established.
- Release state is inconsistent: version 0.2.0, NEWS/README “release candidate,”
  RC1-specific notes that omit RC2/HTTP changes, workflow default rc3, and only
  rc1/rc2 published tags.

## Documentation and examples gaps

- README and vignette provide a coherent browse/find/info/get/wide flow and keep
  keys outside code; examples are not executed in the vignette, avoiding live
  check failures.
- `docs/architecture.md` predates high-level discovery and internal endpoint
  exports in its API inventory and onboarding sequence. It does not describe the
  new dependency compatibility gate.
- The single release-notes file is RC1-specific while RC2 and the subsequent HTTP
  fix exist. There is no consolidated current release-readiness note.
- Man pages exist for exports, but generated-doc drift must be checked against
  roxygen sources. Some inherited parameter prose calls `base_url` primarily a
  testing facility even though custom/internal endpoints are now public UX.
- A clean-copy roxygen run with the available 7.3.1 (older than the recorded
  7.3.2) exposed material drift: many manual pages identify themselves as
  manually maintained/skipped, `aradR-package.Rd` is missing, and generated
  `arad_use_internal.Rd`/`arad_wide.Rd` would differ. Establish the intended
  source-of-truth before regenerating anything.
- pkgdown automatically considered root markdown including the new `AGENTS.md`
  as home-page content in the local tool version. Exclude internal contributor
  instructions from a published site when the website pipeline is hardened.
- Network examples are broadly `\dontrun`, but README's date/indicator examples
  and availability statements should be freshness-checked before release.
- Troubleshooting is strong for keys, HTTP 400, internal proxy/auth, empty data,
  NA, duplicates, wide output, cache, and suspicious requests; it does not yet
  distinguish dependency *installation* failure from runtime loaded-namespace
  mismatch in depth or provide a structured diagnostic command.

## Backward compatibility and technical debt

- The release-candidate API is described as frozen. Treat function signatures,
  exact-one-selector rules, long tibble columns/order/types, ranked result fields,
  stable `base_id`, diagnostic attributes, error classes, caching default, public
  endpoint default, and 3650-day chunk default as compatibility-sensitive.
- The `options(aradR.request_fn=...)` seam is undocumented and global; it is
  effective for tests but creates hidden process state and signature coupling.
- Request building, caching, and API-key validation occur on multiple paths;
  compatibility checks currently run only in the real raw request, not injected
  tests. This is appropriate for unit isolation but makes end-to-end coverage
  especially important.
- `R/audit.R` defines `arad_data_key()` also defined in `R/parse.R`; source load
  order currently masks one identical-purpose definition. Remove/consolidate
  only after confirming behavior and tests.
- Base-R row binding and repeated table assembly are acceptable at current
  scale, but schema/type preservation depends on careful tests. Do not refactor
  for style during reliability work.
- Release/audit trigger sentinel files and long-lived merged branches obscure
  current intent. Cleanup is repository governance, not package functionality.

## Prioritized milestones

### M0 — approve scope and freeze claims

Agree on release channel, supported R/dependency floors, public/internal endpoint
support claim, live request budget, and whether CRAN readiness is an objective.

**Acceptance:** decisions are written down; no release action is implied.

### M1 — make validation safe and reproducible

Decouple binary/package validation from tag checkout and release upload; make
routine CI read-only; add current and minimum-stack install/load/test jobs with
pinned/reconstructable inputs; add metadata consistency checks.

**Acceptance:** a normal push/PR cannot create or upload a release, both stacks
run offline, and failures identify validation rather than missing release state.

### M2 — close deterministic reliability gaps

Add a local HTTP test server or equivalent deterministic harness for retries,
timeouts, statuses, error classes, redaction, and response limits; add cache and
public-schema contract tests. Preserve existing behavior unless a separately
approved change is required.

**Acceptance:** tests prove the documented behavior without credentials/network,
including actual httr2 paths on each supported stack.

### M3 — reconcile docs and release materials

Synchronize architecture, README/vignette/man pages, NEWS, current RC notes, and
workflow/checklist language. Regenerate roxygen outputs and validate pkgdown.

**Acceptance:** no stale API inventory or conflicting version/channel claim;
source and generated docs are clean and reproducible.

### M4 — bounded external validation

After owner authorization, run one current public-endpoint UX smoke and the
smallest justified calibration audit. Record date, commit, dependency/session
information, scopes, request budget, and redacted results. Validate Windows R
4.1 separately if it remains supported.

**Acceptance:** all chosen invariants pass on the exact candidate commit; skips
or unavailable secrets are reported as missing evidence, not success.

### M5 — release decision (not authorization to release)

Review the complete evidence and remaining known issues. Produce a go/no-go
recommendation. Actual version/tag/artifact/publication work requires a new,
explicit product-owner instruction.

## Validation matrix

- `testthat::test_local()` offline on current R and R 4.1/minimum dependencies.
- Build source tarball, install it into a clean library, and load without network,
  key, messages, option mutations, or cache writes.
- `R CMD check --as-cran` from the tarball on Ubuntu, Windows, and macOS; include
  current R and the approved minimum/oldrel coverage.
- Run roxygen in a clean tree and require no unexplained `NAMESPACE`/`man` diff.
- Build pkgdown and check links/anchors; validate README/vignette code syntax.
- Exercise actual old/current httr2+curl combinations and incompatible-stack
  remediation in isolated libraries.
- Keep live UX/audit separate, secret-gated, bounded, redacted, and manual.

## Audit baseline results

These are observations, not fixes. The audit intentionally did not run live ARAD
requests because no API key or live request budget was supplied.

- `Rscript -e 'testthat::test_local(".")'`: passed 193 assertions with zero
  failures/warnings; the one live regression test skipped by design.
- `R CMD build /workspace/aradR --no-manual`: succeeded and built the vignette
  and source tarball under `/tmp/aradR-audit`.
- `R CMD check --as-cran --no-manual <tarball>` on Ubuntu with R 4.3.3,
  httr2 1.0.0, curl 5.2.0, and rlang 1.1.3 completed with one WARNING and three
  NOTEs: missing `qpdf`; CRAN/Bioconductor index access and current-time
  verification unavailable in the environment; non-standard top-level
  `AUTHORS.md` (the first run also saw `AGENTS.md`, which is now correctly build
  ignored because this audit introduced it); and statically unused `curl`
  Import. The package installed, loaded, examples, tests, and vignettes passed.
- Clean-copy `roxygen2::roxygenise()` was not clean for the drift described
  above and warned that installed roxygen2 7.3.1 is older than required 7.3.2.
  No generated changes were copied back.
- Clean-copy `pkgdown::build_site(new_process = FALSE)` started successfully but
  failed when its external fetch hit the environment's HTTP 403 proxy. It also
  revealed that internal root markdown would be considered website content.
- No live test, Windows R 4.1 job, macOS job, current httr2 >= 1.2/curl >= 6.4
  job, PDF manual, or release publication was run locally.

## Release prerequisites

1. Product owner approves target version/channel and compatibility policy.
2. Clean source tree and reviewed changelog/release notes match the candidate.
3. All M1–M3 offline gates pass on the exact candidate commit.
4. No unresolved high-severity secret, install, data-integrity, or accidental
   publication issue remains.
5. Authorized live checks pass recently enough for the agreed freshness window.
6. Artifact workflow validates tag existence/version/commit before building and
   separates validation from upload; permissions are least-privilege.
7. Source/binary artifacts are reproducible enough for the intended channel,
   installed in clean libraries, and accompanied by provenance/checksums.
8. Release approval is explicit. No checklist completion substitutes for it.

## Decisions needed (maximum five)

1. Is the next target a final 0.2.0, another RC, or reliability hardening with no
   release target?
2. Must R 4.1 plus httr2 0.2.2 remain a supported production floor, and for how
   long, or may floors be raised after measured compatibility evidence?
3. Is CRAN submission/readiness in scope, or only GitHub source and Windows
   binary distribution?
4. What public/internal endpoint platforms are officially supported versus
   best-effort, especially non-Windows Negotiate authentication?
5. What live ARAD request budget and evidence freshness are approved for the
   first implementation goal and future release gates?
