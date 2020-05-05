# RFC-123: Use GitHub Actions for CI

## Summary

This proposes using [GitHub Actions](https://github.com/features/actions) as our preferred CI tool where applicable.

CI in this case is scoped as follows:

1. Running branch and PR builds for tests and linting, including the `master` branch.
2. Pushing `release` tags on successful master builds.

This does not include gem publishing or DockerHub pushes, because we feel we need to talk to IA before this decision can be made.

TechOps [started a discovery into CI tooling](https://github.com/alphagov/reliability-engineering/pull/106) a while ago, but it's not reached a conclusion yet. Now we've procured GitHub Enterprise Cloud, making use of the tools available there reduces platform complexity.

## Problem

We currently have many solutions for running branch builds in GOV.UK, including:

- Jenkins CI (self-hosted, behind IP and GitHub team membership restrictions)
- Travis CI (hosted, paid on a GPC card)
- Concourse CI (self-hosted in TechOps, behind IP and GitHub team membership restrictions)
- GitHub Actions CI (hosted, paid through GDS' GitHub Enterprise Cloud subscription)

## Proposal

To switch to GitHub Actions CI for continuous integration (that is, branch and PR builds for tests/linting) as the preferred approach where we do not need the wider platform integration of Jenkins.

This would involve working towards:

 - GOV.UK projects *only* using either GitHub Actions or Jenkins for CI
 - No projects should use Concourse, Travis or another tool for CI without reasons to justify an exception

This would be a gradual process, because we have many repos, but this decision would deem the usage of Concourse CI and Travis CI as a legacy approach to CI for GOV.UK.

### Examples of existing uses of GitHub Actions

- [GOV.UK Coronavirus Business Volunteer Form][business-volunteer-form], a Rails app with a Postgres database.
- [GOV.UK AWS linting checks][govuk-aws].
- [GOV.UK Coronavirus Content YAML validation][govuk-coronavirus-content].

### Pros

- A simpler, more modern approach compared to Jenkins.
- Using Actions would make it easier to get rid of the CI Jenkins, which would be a huge cost saving - our CI environment is in Carrenza and currently costs ~£6k a month + VAT.
- GDS as a whole pays for GitHub Enterprise Cloud, which entitles us to unlimited minutes on public repos (both Linux and macOS runners), and 50,000 minutes per month of Actions on private repos.
- Supported by GitHub, from whom we get Enterprise support via our GitHub Enterprise Cloud subscription.
- We don't have to host any of our own CI infrastructure.
- Well documented, easy to [get started][actions-get-started] building a new pipeline. Easier than Concourse for CI as PR builds are built-in to GitHub rather than needing to use [third-party code](https://github.com/telia-oss/github-pr-resource).
- Doesn't require access to the VPN like our Jenkins does, or membership of any GitHub teams, in order to see logs for public repos.
- External contributors can see their changes and why they failed, without us having to [push branches][merge-a-pull-request] and paste build logs from Jenkins. This fits more readily with our "code in the open" ethos, and saves on internal developer time.
- Already in use across some of our production applications. Examples: [business volunteer form][business-volunteer-form], [find support form][find-support-form], [vulnerable people form][vulnerable-people-form]
- In the future, we can make our internal GitHub Actions into libraries so we’re not duplicating “set up Rails apps” steps across 50 apps and can update them in one place (perhaps `alphagov/actions`?). We already do something similar with `alphagov/govuk-jenkinslib`. See [Homebrew/actions](https://github.com/Homebrew/actions) for an example.

### Cons

- We have less control over what software is on the runners. But most of the time we only need a database, a version of Ruby and some gems. And updating our Jenkins CI instances with new packages is a massive pain.
- Another system to learn, as well as the replatforming work already ongoing.
- Duplication of build parameters and steps between all our apps, as they’re all Rails apps. This can be mitigated if we use a shared actions library as proposed earlier.

### Findings from some initial explorations into using GitHub Actions

#### `push` vs `pull_request` build triggers

We considered the following options:

1. Running `on: [pull_request, push]`. This means that internal devs get feedback on their commits when they push them, even if they haven't opened a PR yet (via `push`). External contributors can also get CI feedback on their PRs (via `pull_request`). It does mean that pushing commits to an open PR will waste compute power, time and the planet's precious natural resources, since we'll be running things twice (via `push` and `pull_request`).

2. Running `on: push`. This would persist a current problem we have with running tests on PRs from external contributors. When [a PR is raised from a fork](https://github.com/alphagov/govuk-docker/pull/337), the tests won't run (needs `pull_request`). Actions also [don't run on forked PRs](https://github.com/alphagov/govuk-docker/pull/337). So we'd be back to the annoying state that is [our current process for forked PRs][merge-a-pull-request].

3. Running `on: pull_request`. This has the advantage that it's consistent behaviour for internal and external contributors. Internally we'd have to put up with not having tests run on branches, prior to raising a PR. This would mean changing developer workflows to run more tests locally, or being less worried about "exposing to the world" our force-pushes to get things right on the PR. (Irrespective of this decision, we should always build the `master` branch when merge commits are `push`ed.)

In a [poll of all interested RFC respondents](https://github.com/alphagov/govuk-rfcs/pull/123#issuecomment-620028907), option 1 - running builds on both `pull_request` and `push` events - was the most popular. In that case, going forward, all Actions CI builds will run `on: [push, pull_request]`.

#### `release` tagging via GitHub Actions

Currently, our release tags are pushed [at the end of a Jenkins `master` build](https://github.com/alphagov/govuk-jenkinslib/blob/master/vars/govuk.groovy#L705-L727). The numbers auto-increment each time. These have been reset to 0 on a few occasions during Jenkins upgrades. A consequence of tagging releases on successful master builds via GitHub Actions is that our `release` tags would be reset to 0 once again.

### The state of our repos at the moment

Currently we have:

- The vast majority of our repos run CI checks on Jenkins.
- The new apps we built recently (the coronavirus forms), and the Seal (as it's not an "app" per-se, it's deployed to Heroku), use GitHub Actions.
- Some of them (DGU) run CI on Travis.
- Some GOV.UK Data Labs projects use Concourse for PR checks.

## Outcome and next steps

We will gradually migrate all of the GOV.UK repos to run CI builds with GitHub Actions. To start with, these could be the [`skipDeployToIntegration`][] repos, or tooling. We need to [make `govuk-saas-config` set GitHub Actions checks to "required"][govuk-saas-config].

Gems - or other things that aren't deployed apps on our infrastructure that may currently live on CI Jenkins - will not be migrated to GitHub Actions as part of this RFC. We will address these in a future RFC, potentially along with the GOV.UK replatforming.

[actions-get-started]: https://help.github.com/en/actions/getting-started-with-github-actions
[business-volunteer-form]: https://github.com/alphagov/govuk-coronavirus-business-volunteer-form/blob/master/.github/workflows/tests.yml
[find-support-form]: https://github.com/alphagov/govuk-coronavirus-find-support/blob/master/.github/workflows/tests.yml
[govuk-aws]: https://github.com/alphagov/govuk-aws/blob/master/.github/workflows/ci.yml
[govuk-coronavirus-content]: https://github.com/alphagov/govuk-coronavirus-content/blob/master/.github/workflows/tests.yml
[govuk-saas-config]: https://github.com/alphagov/govuk-saas-config/issues/42
[merge-a-pull-request]: https://docs.publishing.service.gov.uk/manual/merge-pr.html#a-change-from-an-external-contributor
[skipDeployToIntegration]: https://github.com/search?q=org%3Aalphagov+skipDeployToIntegration&type=Code
[vulnerable-people-form]: https://github.com/alphagov/govuk-coronavirus-vulnerable-people-form/blob/master/.github/workflows/tests.yml
