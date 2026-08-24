# Contributing to aradR

Thanks for helping improve `aradR`. The project prioritises correctness, reproducibility, and respectful use of the Czech National Bank ARAD API.

## Before opening a change

- Keep API keys and other credentials out of code, tests, logs, screenshots, and issues.
- Prefer deterministic unit tests over live API calls.
- Do not add retries or stress tests that increase ARAD request volume without a clear reliability reason.
- Preserve genuine source missing values; never treat every `NA` as corruption.
- Keep public API changes small and documented.

## Development workflow

1. Create a focused branch from `main`.
2. Add or update tests for behavioural changes.
3. Update documentation and `NEWS.md` for user-visible changes.
4. Open a pull request.
5. Let the normal Ubuntu R CMD check validate package changes.
6. Use the broader live ARAD audit or multi-OS check only when the change justifies it (for example retrieval-core or release changes).

## Reporting bugs

A useful report includes:

- `packageVersion("aradR")`;
- the indicator ID(s), period, and snapshot choice;
- a minimal function call with the API key removed;
- the error class/message;
- `attr(result, "arad_diagnostics")` when available.

Do not include the API key itself.

## Scope

Package issues include request construction, parsing, validation, caching, reshaping, and client ergonomics. Questions about the official meaning or publication status of an ARAD series belong with the Czech National Bank's ARAD data support channels.
