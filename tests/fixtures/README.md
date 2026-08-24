# Reliability regression fixtures

This directory is reserved for reproducible ARAD regression cases.

The first required live regression case comes from an internal review of the predecessor package: for some long indicator downloads, a request over the full period can contain `NA` values even though splitting the same request into smaller time ranges returns valid values for those dates.

A production regression fixture should therefore record, at minimum:

- indicator ID
- expected frequency
- full request start and end dates
- one or more split points
- dates where the full request and split requests differ
- whether an `NA` is known to be a genuine source-data missing value

Do not store API keys or other credentials in this repository.

Live API tests must use the `ARAD_API_KEY` environment variable or a GitHub Actions secret and should be separated from deterministic unit tests.
