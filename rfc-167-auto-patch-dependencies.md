# Allow automatic patching of all dependencies

## Summary

This is a continuation of [RFC-156](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-156-auto-merge-internal-prs.md), which successfully proposed automatic patching of 'internal' dependencies (maintained by GOV.UK), under strict conditions. RFC-167 proposes extending this policy to external dependencies.

Note that the actual mechanism for patching, whether via PRs that are automatically opened, approved and merged, or whether via direct pushes to 'main', is of little consequence and is implementation detail not in scope for this RFC.

## Problem

Keeping dependencies up to date is [one of our core values](https://docs.publishing.service.gov.uk/manual/keeping-software-current.html). Dependency update PRs are raised automatically by Dependabot or Renovate, but a human is required to approve and merge the PR. This is problematic for two reasons:

1. It is unnecessary toil for the human, and comes with opportunity cost
2. When security updates are raised, they aren't applied until a human takes affirmative action, leaving us potentially vulnerable in the meantime

## Proposal

This RFC proposes formally allowing automatic patching of dependencies, [under certain conditions](#conditions-required-for-automatic-patching).

It also proposes how the Platform teams will help to enable implementation. This will focus on iterating the existing govuk-dependabot-merger service, but in theory other automatic patching systems will be allowable too, provided the aforementioned conditions are met.

### Justification

There are three main risks associated with updating a dependency:

1. A dependency has a behavioural change that breaks the application.
2. A dependency has an unintentional (known or as yet unknown) vulnerability.
3. A dependency has been deliberately crafted to include a vulnerability that the dependency maintainer is hoping to exploit on GOV.UK.

These are risks that *we're currently living with*. The human review step offers a false sense of security. In every case, what we should be relying on instead is comprehensive test coverage and security scanning.

We know [from an early 2023 survey](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-156-auto-merge-internal-prs.md#1-dependency-is-internal) that over 90% of engineers at the time were not following our internal [guidance on manually reviewing Dependabot PRs](https://docs.publishing.service.gov.uk/manual/manage-ruby-dependencies.html#reviewing-dependabot-prs). Over half didn't even know it existed. But even if they follow the guidance to the letter, the review would be ineffective for numerous reasons:

- It is up to the reviewer to consider which dependencies warrant anything more than a cursory look at the changelog. This is open to interpretation.
- In the case of risk number 3 above, the dependency maintainer may disguise the nature of the change, by writing an innocent looking changelog update and/or marketing the update as a 'patch'.
- If a reviewer does go to the effort of looking at a code diff, they may not have the expertise to spot dangerous code, or they may not do a particularly thorough review (especially if the diff is hundreds of lines long).
- In any case, we cannot guarantee that the code the reviewer is looking at in GitHub is even the same code that has actually been packaged and published. Again, as in risk number 3, the dependency maintainer could make any arbitrary changes to their package locally prior to publishing it.

The best measures we can currently utilise against the three identified risks are: a thorough test suite, and security scanning, both of which can be executed without the need for human oversight. These safeguards are echoed by the industry, which is heading in the direction of automatic patching. In September 2023, [Thoughtworks published a "Tech Radar" endorsing automatic merging of dependency update PRs](https://www.thoughtworks.com/en-gb/radar/techniques/automatic-merging-of-dependency-update-prs):

> Under the right circumstances we now advocate for automatic merging of dependency update PRs. This requires that the system has extensive test coverage — not only unit tests but also functional and performance tests. The build pipeline must run all of these tests, and it must include security scanning. In short, the team must have full confidence that when the pipeline runs successfully the software is ready to go into production. In such cases, dependency update PRs, even when they include major version updates in indirect dependencies, should be merged automatically.

Finally, it's worth noting that *GOV.UK already has automatic patching for some external dependencies*. [govuk-dependabot-merger](https://github.com/alphagov/govuk-dependabot-merger) is an in-house service, built as an outcome of RFC-156. The strict criteria set out in RFC-156 were softened slightly in [ADR 4](https://github.com/alphagov/govuk-dependabot-merger/blob/main/docs/adr/04-ignore-subdependencies.md), allowing the bumping of transient (external) dependencies that are included with the internal dependency bump (even if the internal dependency did not explicitly update those dependencies). At time of writing, [the service has now merged almost 200 PRs](https://github.com/search?q=org%3Aalphagov+This+PR+has+been+scanned+and+automatically+approved+by&type=pullrequests), all without incident, and almost all bumping at least one external dependency.

### Conditions required for automatic patching

Any repository wishing to opt into automatic patching:

- MUST ensure it has [sufficient security scanning](#sufficient-security-scanning)
- MUST only be applied where there is [no manual deployment step](#no-manual-deployment-step)
- MUST ensure that [branch protection rules are in place](#branch-protection-rules) that prevent pushes to main if required status checks fail
- SHOULD ensure it has [sufficient test coverage](#sufficient-test-coverage)
- SHOULD only automatically patch [where the dependency version bump is patch or minor](#version-increase-is-patch-or-minor)

#### Sufficient security scanning

This is important to ensure that the dependency bump is not introducing a security vulnerability.

As a minimum, repositories must have a [Software Composition Analysis (SCA)](https://snyk.io/series/open-source-security/software-composition-analysis-sca/) scan as part of their CI pipeline. This will flag dependencies (or the transient dependencies thereof) that are known to have vulnerabilities, so seems a sensible pre-requisite for auto-merging. The Platform Security & Reliability (PSR) team have [evaluated multiple SCA tools](https://docs.google.com/document/d/1roFOxf_Juu0xw0Sho1OJ9jk22XhiP3bWcjst1pODm48/edit) and recommend using Snyk. They've since [rolled out Snyk SCA scans](https://trello.com/c/RPICx1Qm/3366-add-snyk-sast-and-sca-scans-to-all-govuk-repos-2) - see "[Further reading on GOV.UK security scans](#further-reading-on-govuk-security-scans)".

Repositories should also have [Static Application Security Testing (SAST)](https://snyk.io/learn/application-security/static-application-security-testing/) in their CI pipeline, but this is outside of the scope of the RFC. As established earlier, GOV.UK is under no additional risk by enabling automating patching, so the implementation of SAST scanning should not be a blocker for the RFC. Moreover, current SAST tools only scan application source code - not the code of dependencies - for vulnerability signatures, so would not be very effective at catching dependency-related vulnerabilities. Finally, SAST tooling needs careful rollout, due to the high degree of false positives. As stated in a PSR [evaluation of SAST tools](https://docs.google.com/document/d/1oh2yK1fp2c38d7vPE3SUoIGRvJ09pWkhsLSxaUIiiG8/edit):

> Before there was SAST scanning, these vulnerabilities would have made it to production anyway. Failing builds whilst the SAST process is still immature risks failing the build every time a false positive is found. [Therefore SAST scans should be non-blocking, for now].

[Sonar's "Deeper SAST"](https://www.sonarsource.com/solutions/security/) tool promises to scan the code of dependencies, but currently lacks support for Ruby. [CodeQL SAST scans, which are already in place on GOV.UK](https://github.com/alphagov/govuk-infrastructure/blob/74f3960e14fb223984406562983e2f233ea11b91/.github/workflows/codeql-analysis.yml), may have the capacity to scan the source code of dependencies, but most of CodeQL's queries are [designed to 'guess' which APIs are called without looking at the source code](https://github.blog/2023-06-15-codeql-zero-to-hero-part-2-getting-started-with-codeql/#:~:text=For%20successfully%20creating,of%20those%20APIs).

In short, SAST tooling may one day be a useful safeguard against malicious dependency bumps, but it isn't there yet, and thus is not a requirement imposed by this RFC.

#### No manual deployment step

This is important to ensure that any regressions introduced by automatic patching are spotted quickly.

As per RFC-156, a dependency must not be automatically merged if it is a 'manually deployed' app. If there is an issue with a dependency for a continuously deployed app, it is likely to be spotted very quickly, whereas if there is an issue with a dependency that's been merged but not deployed, there is no knowing when it will be deployed and it may become difficult to unpick.

Some repos have no concept of deployment (e.g. utility scripts). There is no manual deployment step for these, so they satisfy this requirement.

#### Branch protection rules

This is important to minimise the risk that a dependency update PR might get accidentally merged.

Repos must have branch protection enabled on their default branch (likely `main`), requiring status checks to pass before merging. As a minimum, this must include the security scan described earlier, and must also include any CI test suite as described below.

#### Sufficient test coverage

This is important to ensure that a legitimate dependency update doesn't break the behaviour of the application. Applications should have comprehensive test coverage [as per our test guidance](https://docs.publishing.service.gov.uk/manual/testing.html), including:

- Unit tests and integration tests (covering a minimum of 95% of the code: the de facto definition of "good enough" as outlined in [RFC-128](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-128-continuous-deployment.md))
- [Smokey tests for site-wide config, app-to-app data transfer and critical functionality](https://github.com/alphagov/smokey/blob/main/docs/writing-tests.md)
- [Probe healthchecks](https://github.com/alphagov/govuk-helm-charts/blob/80c188d06652aa37e1218b28a15481be93f0018c/charts/generic-govuk-app/templates/deployment.yaml#L106-L117)
- [Contract/Pact tests for APIs](https://docs.publishing.service.gov.uk/manual/testing.html#contract-tests)

Any application that does not have sufficient test coverage should only have automatic patching enabled if the owning team accepts the risk that the application could break (which may be acceptable for things like internal utilities).

#### Version increase is patch or minor

This is important to minimise the risk of larger updates.

As per RFC-156, we should [avoid automatically merging major updates](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-156-auto-merge-internal-prs.md#4-version-increase-is-patch-or-minor), as these may require some careful manual steps before merging.

The language has been softened from "must" to "should", as some repositories may have sufficient test coverage, sufficiently simple dependencies, or the owning team may be sufficiently comfortable with the risk of breakage, to allow for automatic major patching of dependencies.

## Implementation plan

The Platform teams will take the following actions to enable this RFC:

### 1. Change GitHub repository configuration

Since the [GOV.UK convention on GitHub Actions changed](https://github.com/alphagov/govuk-developer-docs/pull/4340) from a single `test` "job" to a wider `CI` "workflow" (made up of multiple jobs), it's harder to programmatically enforce branch protection. There are [branch protection rules configured in govuk-saas-config](https://github.com/alphagov/govuk-saas-config/blob/23fc44244488be135a6074a7c8b798227401452d/github/lib/configure_repo.rb#L16), but this entirely [relies on each CI job being explicitly listed in an overrides file](https://github.com/alphagov/govuk-saas-config/blob/23fc44244488be135a6074a7c8b798227401452d/github/repo_overrides.yml#L321-L326), so there is significant risk that this will fall out of sync with the latest list of job names. There is additional complexity around [some checks being legitimately 'skipped'](https://github.com/alphagov/support-api/actions/runs/7293511321/job/19876707509), which should not block the auto-merge.

The Platform teams will reconsider how to automate branch protection, as part of a general move to [retire govuk-saas-config](https://trello.com/c/mojlsebq/3074-kill-off-govuk-saas-config). There are a few different approaches we could take, which need not be decided in this RFC, but suffice to say that we commit to ensuring that security scans are automatically set as required/blocking checks. We hope to make it as easy as practically possible for teams to adhere to the constraints outlined in this RFC, but the onus will still be on teams to self-certify whether or not a given repo or dependency update should be eligible for auto-merging.

Note that this is an additional layer of defence. govuk-dependabot-merger [already checks that the `CI` workflow exists and all its jobs have succeeded](https://github.com/alphagov/govuk-dependabot-merger/pull/30), and will not attempt to approve and merge PRs that do not satisfy this condition. So, in theory, it should already be impossible for Dependabot PRs to be merged if a test suite or security scan fails.

### 2. Change govuk-dependabot-merger

The Platform teams will create a configuration option for govuk-dependabot-merger, allowing downstream repos to 'opt in' to external dependency patching. The current "internal only" behaviour will continue to be a supported option.

The config for an opted in repository currently looks like:

```yaml
api_version: 1
auto_merge:
  - dependency: govuk_publishing_components
    allowed_semver_bumps:
      - patch
      - minor
  - dependency: rubocop-govuk
    allowed_semver_bumps:
      - patch
      - minor
```

This RFC proposes a breaking change to the API as follows:

```yaml
api_version: 2
defaults:
  update_external_dependencies: true # default: `false`
  auto_merge: true # default: `true`
  allowed_semver_bumps: # default: `[patch, minor]`
    - patch
    - minor
  # each of the above properties can be overridden on a per-dependency basis
overrides: # suitably renamed from `auto_merge`.
  # Now we only need to specify `allowed_semver_bumps` if we're overriding the default behaviour:
  - dependency: rubocop-govuk
    allowed_semver_bumps:
      - patch
  # We can also opt a specific dependency out of automatic patching as follows:
  - dependency: foo
    auto_merge: false
```

This configuration structure allows for a high degree of configurability - see [Appendix](#appendix).

As part of the breaking change, we would also detect any continued uses where `api_version: 1`, and skip over the affected repos, outputting a log message saying that this version is no longer supported. Teams can easily check the logs in the [daily govuk-dependabot-merger runs](https://github.com/alphagov/govuk-dependabot-merger/actions/workflows/merge-dependabot-prs.yml) to see which repos are affected, and update accordingly. The Platform teams would do some outreach work here too.

Note that there are no changes proposed to the timing of the daily runs. As per RFC-156, govuk-dependabot-merger [only auto-merges during office hours (and accounts for bank holidays)](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-156-auto-merge-internal-prs.md#5-during-office-hours) - this is already in place and is not yet configurable. We may one day want to revisit this (for example, to enable automatic patching of security issues if they occur out of hours), but that can be revisited once our auto-merging service is more mature, and is not in scope for this RFC.

### 3. Phased roll-out for select repositories

The Platform teams will trial updating the configurations of a select number of repositories, enabling automatic patching of external dependencies. They will monitor the impact of so doing, before a wider roll-out is considered. Comms will be put out to affected teams, as the previous "version 1" of the service will no longer be in operation, so teams will have to manually merge PRs while we trial the new version.

If the trial is not successful, this RFC will be revisited. If it is successful, we'll move onto the next step.

### 4. Update documentation and roll out across GOV.UK repositories

Following a successful trial, we can roll out the change more widely, updating the documentation in tandem.

Platform teams will engage with teams to publicise the new capabilities of govuk-dependabot-merger, and support teams in enabling automatic external dependency updates if they wish. No team and no single repository will have the change forced upon it.

Documentation that will need updating:

- govuk-dependabot-merger README (with comprehensive config documentation)
- The [sparse guidance in The GDS Way](https://gds-way.cloudapps.digital/standards/tracking-dependencies.html#update-dependencies-frequently), where we'll want to highlight GOV.UK's updated policy on auto-merging. The old guidance was introduced in [gds-way#428](https://github.com/alphagov/gds-way/pull/428), documenting the consensus at the time, but with little reasoning provided.
- Update [Manage Ruby dependencies with Dependabot](https://docs.publishing.service.gov.uk/manual/manage-ruby-dependencies.html)

# Status

Proposed

# Appendix

## Examples govuk-dependabot-merger configs

A policy that enables automatic patch/minor patching of all dependencies:

```yaml
api_version: 2
defaults:
  update_external_dependencies: true
  auto_merge: true
```

A policy that enables automatic patch/minor patching of all internal dependencies:

```yaml
api_version: 2
defaults:
  update_external_dependencies: false
  auto_merge: true
```

A policy that enables automatic patch/minor patching of all internal dependencies, and one specific external dependency:

```yaml
api_version: 2
defaults:
  update_external_dependencies: false
  auto_merge: true
overrides:
  - dependency: some-special-external-dependency
    update_external_dependencies: true
```

A policy that retains the (old) internal-only, allow-list only patching behaviour:

```yaml
api_version: 2
defaults:
  auto_merge: false
overrides:
  - dependency: rubocop-govuk
    auto_merge: true
  - dependency: govuk_app_config
    auto_merge: true
  # etc...
```

## Further reading on GOV.UK security scans

- [Definition of the CodeQL SCA workflow](https://github.com/alphagov/govuk-infrastructure/blob/main/.github/workflows/dependency-review.yml)
- [Definition of the CodeQL SAST workflow](https://github.com/alphagov/govuk-infrastructure/blob/main/.github/workflows/codeql-analysis.yml)
- [Definition of Snyk SCA and SAST workflow](https://github.com/alphagov/govuk-infrastructure/blob/main/.github/workflows/snyk-security.yml)
- [Example of calling the reusable workflows from another repo](https://github.com/alphagov/seal/blob/fe4b3492b195ad751736606281cbd9a6688745f7/.github/workflows/tests.yml#L5-L18)
- [Monitoring we have in place](https://github.com/alphagov/seal/blob/fe4b3492b195ad751736606281cbd9a6688745f7/lib/github_fetcher.rb#L41-L43) to alert on repos that don't have the workflows configured
