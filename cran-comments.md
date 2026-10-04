## Test environments

* Ubuntu 24.04, R-devel, GitHub Actions: `R CMD check --as-cran` on the built source tarball.
* Windows, R-devel, GitHub Actions: `R CMD check --as-cran` on the built source tarball.
* Ubuntu, R-release, GitHub Actions: routine `R CMD check`.
* macOS, R-release, GitHub Actions: release-candidate validation.
* Windows, R-release, GitHub Actions: release-candidate validation.
* Windows, R 4.1.0, GitHub Actions: compatibility build/install with the legacy supported HTTP dependency stack.

## R CMD check results

0 errors | 0 warnings | 1 note

The remaining note is the expected incoming-feasibility note for a new CRAN submission (`New submission`).

## Internet access

`aradR` is a client for the public Czech National Bank ARAD API. Routine tests, examples and vignettes do not require network access or an API key during package checks. Live API regression tests are explicit opt-in tests and are skipped by default. Network, proxy and authentication failures are converted into bounded, informative package-specific errors.

## Additional notes

This is the first CRAN submission of `aradR`.

`aradR` is an independent personal open-source project and is not official Czech National Bank software. The package documentation states this explicitly.

The package was informed during early development by the MIT-licensed `cnbrrr` package by Petr Bouchal. Petr Bouchal is credited as a contributor (`ctb`) and the upstream MIT attribution is retained in the distributed `inst/NOTICE` file.

There are no reverse dependencies because this is a new package.
