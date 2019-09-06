# 111: Standardise on one CLI tool

## Summary

There are currently 4 different CLI tools in use for performing day to
day tasks relating to connecting to machines and accessing AWS. Three
of these are maintained by GOV.UK and one by RE.

This RFC seeks to determine which one GOV.UK should standardise on.

## Problem

There exist 4 different internally-developed CLI tools within GDS,
three of which are maintained by members of GOV.UK and in daily use.
The sections below summarise what each of these tools are capable of
doing and how easily installable they are.

### `govuk` and associated scripts from [alphagov/govuk-guix](https://github.com/alphagov/govuk-guix)

- Allows people to connect to machines and services in AWS and Carrenza with `govuk connect`.
- Contains `govuk aws` for connecting to services and accounts in AWS with a specific `--profile` argument.
- Contains `govuk data` for replicating data. It requires `govuk-guix` to be set up in some capacity.
- Written in Ruby.
- Installable by copying or symlinking the scripts from `bin/` to `$PATH`.

### `govuk` and associated scripts from [alphagov/govuk-cli](https://github.com/alphagov/govuk-cli)

- Contains `govuk connect` and `govuk config`, copied from the above `alphagov/govuk-guix` repo.
- The migration between `govuk-guix` and `govuk-cli` repos is [ongoing](https://github.com/alphagov/govuk-guix/issues/36), so the two might not be in sync.
- Written in Ruby.
- Installable with `brew install alphagov/gds/govuk-cli`.

### `govukcli` from [alphagov/govuk-aws](https://github.com/alphagov/govuk-aws/tree/master/tools/govukcli)

- Allows people to assume role into AWS with `govukcli aws`.
- Allows people to SSH into machines with `govukcli ssh`.
- Access is available to all GOV.UK environments due to the `govukcli set-context` command - it is not AWS-specific.
- Written in Bash.
- Installable by following [these instructions in the Developer Docs](https://docs.publishing.service.gov.uk/manual/howto-ssh-to-machines-in-aws.html#setup).

### `gds-cli` from [alphagov/gds-cli](https://github.com/alphagov/gds-cli)

- Allows users to assume role into AWS with `gds aws govuk-<environment>`. Can also open links to common tools that teams use (ie team manual, Trello, etc).
- Deals with MFA transparently using `aws-vault` under the hood.
- Written in Go.
- Installable with `brew install alphagov/gds/gds-cli`.

## Proposal

Embrace `gds-cli` as a tool and deprecate any other command-line tools
that duplicate or have significant convergeance with the functionality
`gds-cli` supports (ie, assuming roles in AWS).

Don't attempt to have a single unified govuk cli, these are a point of
confusion and should only be considered if there is a programme level
commitment to maintain such a thing, broad agreement amongst gov.uk
developers what the scope of the unified CLI would be and agreements
on interfaces/practices.

For govuk CLI scripts: continue the existing convention of having
scripts that define their purpose in their name e.g no govuk or
govukcli, instead specific ones like `govuk-docker`, `govuk-connect`
which don't need to be considered as part of a consistent collective.
If these need to do similar functionality to gds-cli have them wrap
around that rather than re-write it.

Pros:

- We standardise on the GDS-wide CLI tool, `gds-cli`, while maintaining GOV.UK specific things elsewhere that depend on `gds-cli` for core functionality, thus avoiding bloating the `gds-cli`.
- We can still write our own scripts in Ruby?
- We're more explicit about what the scripts do, if they're named for the thing they do and not generic `govuk`.

### Context

There has been prior discussion in
[gds-cli repo issues](https://github.com/alphagov/gds-cli/pull/140)
about converging the _n_ CLI tools into the gds-cli, but this was
decided against at the time. There have also been previous thoughts in
[govuk-guix issue 36](https://github.com/alphagov/govuk-guix/issues/36).

This RFC is an attempt to center that discussion in one place and come
out with an agreement to standardize or not on one tool.

From the summaries above of what each of these CLI tools do, `govuk`
and `govukcli` seem very similar. The naming has caused confusion
recently too, with some people knowing about `govuk` but not
remembering how they installed it, and some people knowing about
`govukcli`.

Is the effort of maintaining both tools worth it?

### Other considered solutions

#### Potential solution 1

We converge on `govuk` via `alphagov/govuk-cli`, installable via
Homebrew or symlinks from `alphagov/govuk-connect`, distinct from
`alphagov/govuk-guix`.

Pros:

- Supports all the existing environments as well as legacy ones, with `govuk connect` and subcommands.
- Supports connecting to `sidekiq-monitoring` instances, for which there are [long instructions in the developer docs](https://docs.publishing.service.gov.uk/manual/sidekiq.html#sidekiq-web) otherwise.
- It's [already in some documentation](https://docs.publishing.service.gov.uk/manual/nagstamon.html).
- Written in Ruby, which is GOV.UK's core programming language.
- Standalone, once it's split out of `govuk-guix`.

Cons:

- Needs work to get all the constituent parts out of `govuk-guix`.
- Needs versioning to be easily installable (at the moment it's symlinks from the cloned repo or `brew reinstall govuk-cli` due to Homebrew reading from `master`).

#### Potential solution 2

We converge on `govukcli`, which is the oldest solution but written in
a less accessible language.

Pros:

- It's already in [lots of documentation](https://github.com/alphagov/govuk-developer-docs/search?q=govukcli&unscoped_q=govukcli) as it's the longest serving tool.
- Supports all the environments, even existing legacy ones.
- Standalone.

Cons:

- Built originally by people who have since left GDS and [doesn't receive many updates](https://github.com/alphagov/govuk-aws/commits/master/tools/govukcli).
- Requires separate AWS credential management for which we have [many](https://docs.publishing.service.gov.uk/manual/aws-cli-access.html) [pages](https://docs.publishing.service.gov.uk/manual/aws-console-access.html) of [documentation](https://docs.publishing.service.gov.uk/manual/set-up-aws-account.html).

#### Potential solution 3 (Issy's preference)

We converge on the centrally maintained (but open to everyone to
contribute) GDS CLI and move everything GOV.UK-specific in there as
either subcommands or extensions (as `gds govuk connect` exists
currently).

Pros:

- Users can run `gds govuk connect` to access the `connect` functionality from `govuk-cli`, so it's two tools in one.
- In developing it to add GOV.UK stuff, developers get more Go experience which is valuable for working on Go-based apps in GOV.UK (eg Router).
- An existing versioned release pipeline, and a predictable and easy install method via [the GDS Homebrew tap](https://github.com/alphagov/homebrew-gds).

Cons:

- A new language to learn if developers want to add features.
- It's already quite large and maybe "one tool to rule them all" for every team isn't great?

#### Other solutions are welcome to be explored in the comments. :-)

