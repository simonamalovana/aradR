# Codex status

## Current authorization

The product owner has explicitly decided that `aradR 0.2.0` is the **external/public package only** and should be completed and released before any organization-internal ARAD integration work.

Internal endpoint support, integrated Windows/Negotiate authentication, proxy-specific private-network behavior, and related diagnostics are out of scope for this repository's 0.2.0 release path. They should be developed separately as a thin internal package or integration layer that depends on the public `aradR` core rather than duplicating it.

## Current implementation state

The `external-only-0.2.0` branch removes the prerelease internal endpoint mode from the public package:

- the public CNB ARAD API is the only default endpoint;
- the legacy `aradR.base_url` option no longer redirects the default endpoint;
- `arad_use_internal()` and `arad_use_external()` are removed from the exported API;
- integrated Negotiate authentication and proxy-bypass transport are removed;
- endpoint-mode tests and generated reference documentation are removed/reworked;
- README, NEWS, troubleshooting, vignette, DESCRIPTION and pkgdown are aligned to the public-only scope.

Explicit `base_url` function arguments remain available as low-level testing/advanced request hooks; they do not enable integrated internal authentication.

## What remains before final 0.2.0 release

Continue only on the external package. Verify the branch with deterministic package tests/checks and release-readiness CI, then address any remaining external-only defects or documentation inconsistencies. Do not reintroduce internal authentication or let internal endpoint work block the public release.

No final release, tag, CRAN submission, or publication action is authorized merely by this status file; those remain separate owner decisions.
