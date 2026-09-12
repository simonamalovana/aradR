# Proposed next long-running goal

## Proposal: establish a reproducible release-readiness reliability gate

Without changing the public API or releasing a version, make `main` produce a
repeatable, evidence-backed release-readiness verdict across supported install
and HTTP dependency stacks.

### Why this should be first

The package already has a substantial retrieval/discovery feature set and prior
live calibration. The immediate risks are operational: current `main` has not
completed a post-HTTP-fix full release matrix, an ordinary push accidentally
invokes a tag-dependent artifact workflow, the declared dependency ranges do not
fully encode the conditional `httr2`/`curl` compatibility rule, and legacy R
4.1 coverage is coupled to mutable repository binaries and release upload.
Improving this evidence is higher value than adding features.

### In scope (subject to approval)

1. Split pure validation from release artifact publication so pushes and PRs
   cannot attempt nonexistent tags or upload releases.
2. Add deterministic compatibility-matrix tests for the minimum supported stack
   and current stack, including loaded/installed `curl` diagnostics and package
   load/install smoke tests.
3. Confirm whether the dependency declaration and runtime guard form a sound
   install strategy; propose (but do not autonomously impose) any raised floor.
4. Strengthen offline tests for timeout/retry classification, retry boundaries,
   redaction, status/body handling, and endpoint-mode scoping without changing
   established behavior.
5. Reconcile documentation/release metadata and produce a release checklist.
6. After offline gates pass and the owner authorizes the request budget, run one
   bounded public-endpoint smoke/UX validation and the justified live audit.

### Explicitly out of scope

- new user features or exports;
- silent changes to timeout, retry, chunking, caching, returned schemas, or
  condition classes;
- changing R/dependency floors without a product decision;
- version bumps, tags, assets, CRAN submission, or any release publication;
- embedding credentials or private endpoints.

### Definition of done

- Source installation and offline `R CMD check --as-cran` are clean on current
  R and a reproducible R 4.1/minimum-stack job.
- Current-stack and legacy-stack HTTP compatibility cases are installed and
  exercised rather than only simulated by helper arguments.
- Unit tests cover transport failures and prove secrets are absent from surfaced
  conditions and artifacts.
- Routine CI is read-only and never targets a release tag; publication requires
  an explicit, validated tag and approval.
- Documentation, NEWS status, release notes, workflow defaults, and the proposed
  release checklist agree.
- Authorized live evidence is recent, bounded, recorded, and clearly separated
  from offline checks.
- No public behavior or version changes occur unless separately approved.
