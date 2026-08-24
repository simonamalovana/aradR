# aradR

Modern R client and toolkit for the Czech National Bank ARAD API.

`aradR` is being developed as an independent, reliability-first R package for discovering, retrieving, validating, and working with data from the Czech National Bank's ARAD database.

## Project status

Early development. The package API is not yet stable and the repository is currently private.

## Design goals

- reliable retrieval of long and complex time series
- explicit validation of parsed data and missing values
- clear, actionable error messages
- convenient discovery of ARAD indicators and metadata
- reproducible caching and downloads
- support for snapshots and update workflows
- comprehensive automated tests and continuous integration
- concise documentation for both occasional and advanced R users

## Provenance

The project is independent from `cnbrrr`, but its initial design review and selected implementation ideas are informed by the MIT-licensed [`petrbouchal/cnbrrr`](https://github.com/petrbouchal/cnbrrr) package by Petr Bouchal. Any code adapted from that project will retain the attribution required by its MIT license. See `NOTICE.md`.

## License

MIT. See `LICENSE.md`.
