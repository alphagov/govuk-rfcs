# Next steps with local development data

## Summary

Update the way we manage local development data, promote using the
`govuk data` tool, and setup the automation to make this possible.

## Problem

Presently, many developers on GOV.UK copy data from the S3 database
backups bucket on to there local machine, and use this for local
development.

This use of realistic data can aid local development, but the data
used in the real services and local development are different use
cases, and there are aspects of the process that make local
development more difficult.

Particularly, you don't necessarily need to have near-exact copies of
data for all services on GOV.UK for local development. Downloading
data for all services takes significant time and uses large amounts of
storage space.

The [`govuk data` tool][govuk-data-docs] can help with these problems,
but currently keeping the data up to date requires some regular manual
work, and the govuk-puppet tooling is still the standard way of
getting local development data.

[govuk-data-docs]: https://github.com/alphagov/govuk-guix/blob/master/doc/local-data.md

## Proposal

Automate the process of populating a S3 bucket with the data used by
the `govuk data` tool.

### Action Plan

The process of populating a S3 bucket with data is [mostly
automatic][govuk-update-development-data], however currently it
requires manually starting, and the AWS credentials have to be
provided manually. To resolve this, a nightly job would be setup to
run either in the current CI environment, or in any new CI
environment.

[govuk-update-development-data]: https://github.com/alphagov/govuk-guix/blob/master/bin/govuk-update-development-data

Additionally, the S3 bucket, and associated policies would be managed
through Terraform in govuk-aws/govuk-aws-data.
