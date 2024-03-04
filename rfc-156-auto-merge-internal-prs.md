---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# Allow auto-merging of 'internal' Dependabot PRs

## Summary

GOV.UK should permit the automatic merging of some Dependabot PRs, under strict conditions, and on an opt-in basis.

## Problem

GOV.UK uses Dependabot to automatically open PRs for each of our repos, whenever a newer version of one of its dependencies is available.
These are currently manually reviewed and merged by GOV.UK developers.

Historically, as an organisation we've found the quantity of Dependabot PRs to be an issue. [RFC-126][] was an attempt to reduce the developer burden by narrowing the list of applicable dependencies that should be updated, but it had to be undone in [RFC-153][] because it was preventing some security PRs from being raised.

Our repositories are now better shared amongst teams, and a wider rollout of continuous deployment has lessened the burden of seeing dependency updates through to production. However, in early 2023, we ran a [survey][] of GOV.UK developers, to gauge the effort levels required in merging Dependabot PRs. The [survey results][survey-results] show that 25% of respondents feel they struggle with the quantity of Dependabot PRs they have to review, and 75% feel that they process "lots" of Dependabot PRs, all of which eat into developer time.

A secondary issue is that our dependencies are often on outdated versions for at least a couple of days. The [analysis in RFC-153][rfc-153-analysis] showed that it takes developers an average of 2-5 days to merge Dependabot PRs for "internal libraries" (i.e. any dependency maintained by GOV.UK, usually beginning `govuk_` or ending `-govuk`). 

[reviewing-dependabot-prs]: https://docs.publishing.service.gov.uk/manual/manage-ruby-dependencies.html#reviewing-dependabot-prs
[RFC-126]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-126-custom-configuration-for-dependabot.md
[RFC-153]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-153-remove-allowlists-from-dependabot-configs.md
[rfc-153-analysis]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-153-remove-allowlists-from-dependabot-configs.md#did-the-rfc-result-in-apps-always-using-the-latest-version-of-libraries-we-care-about
[survey]: https://docs.google.com/forms/d/e/1FAIpQLSde3T2iWTglZ_wVamErhb4LXUlstaN2XEgyDXR5F0eUKtUgzw/viewform
[survey-results]: https://docs.google.com/forms/d/1NGhUKTPAJu3aA0NjuVLAIHDYTxs8oN67GcEABL5CgE4/edit#responses

## Proposal

Automate the merging of certain Dependabot PRs, to reduce the number of PRs that require developer intervention.
As a side benefit, it will also decrease the amount of time those dependencies remain out of date.
Read the auto-merge criteria below.

### Auto-merge criteria

We propose a strict rule that Dependabot PRs must only be auto-merged if:

1. Dependency is internal
2. App is continuously deployed
3. CI build passes
4. Version increase is patch or minor
5. During office hours

#### 1. Dependency is internal

We must not auto-merge external dependencies, as this introduces unacceptable security risk. A bad actor who manages to get their dependency included in a GOV.UK repository could release a malicious new version that would automatically make its way to production and could do considerable harm.

Internal dependencies are different. We already have controls over [who can merge code changes to a GOV.UK repository][production-deploy-access]: only GDS employees are able to do so. Accidental 'bad releases' due to unexpected effect of code change should be mitigated by the rule that [code changes are subject to review][code-review] from a second developer.

Should a GitHub account have sufficient administrative privileges that it can disable the mandatory code review process, and should that GitHub account get compromised, then we already have problems bigger than the scope of this RFC, as the bad actor could commit malicious code directly to the application, with no need to infect the supply chain.

Note that security is touched upon in the [documented guidance for how to review Dependabot PRs][reviewing-dependabot-prs], which has some checks, such as checking the history of recent contributors, that we're not proposing to automate here as we already know the identities of contributors to our internal dependencies. Moreover, a documented security process is of little use if it is not followed: over 90% of our survey respondents do not follow the guidance fully, and 58.3% weren't even aware the guidance existed.

Note that we did consider tightening the proposal further to only auto-merge dependencies which don't bump subdependencies. For example, if there is an internal dependency 'foo' which pulls in a new version of an external dependency 'bar', we could consider not auto merging 'foo' even if it otherwise satisfies all the auto-merge criteria. However, 'bar' should already have been thoroughly assessed prior to it being merged into 'foo', so introducing such a rule would give minimal security benefits and would negate the entire purpose of this RFC. A new version of [rubocop-govuk often only contains updates for subdependencies][rubocop-govuk-changelog], and we would want this to auto-merge.

[code-review]: https://docs.publishing.service.gov.uk/manual/merge-pr.html
[production-deploy-access]: https://docs.publishing.service.gov.uk/manual/rules-for-getting-production-access.html#production-deploy-access
[rubocop-govuk-changelog]: https://github.com/alphagov/rubocop-govuk/blob/main/CHANGELOG.md#490

#### 2. App is continuously deployed

A dependency must not be automatically merged if is a 'manually deployed' app.

It may seem counter-intuitive to allow automatic merges for apps that deploy straight to production. However, there are two good reasons to do so:

1) Apps need to pass a high bar before they can have continuous deployment enabled: [RFC-128][] recommends that such apps should have code coverage exceeding 95%. These are our best tested apps, so are the most likely apps to see a failing CI build should a dependency break something.
2) If there is an issue with a dependency for a continuously deployed app, it is likely to be spotted very quickly. If there is an issue with a dependency that's been merged but not deployed, there is no knowing when it will be deployed and it may become difficult to unpick.

Note that the '95% code coverage' figure is a guide, which is not programmatically enforced. It is also not necessarily actively monitored after continuous deployment is enabled for an app, so could degrade over time. Approving this RFC means accepting that it is ever more important to maintain high automated testing standards.

[RFC-128]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-128-continuous-deployment.md

#### 3. CI build passes

A dependency must not be automatically merged if an associated CI build fails.

This follows on from the criterion above: continuously deployed apps have good test coverage, so it makes sense to check the outcome of the CI build, only merging the PR if all tests pass.

#### 4. Version increase is patch or minor

A 'major' version increase must not be automatically merged, even if the PR checks pass, as it could require some additional manual configuration before merging. This risk is lower with patch or minor versions.

One could argue that, so long as the tests pass, even major version upgrades should be automatically merged. But these often have nuances and recommendations that are not necessarily covered by unit tests. To illustrate the point - even though it's not an internal dependency - a classic example is Rails, where [manual steps are required][rails-major-upgrade], even if the CI build passes. It is not worth risking automatic merging, versus the time it would take for a developer to manually process the changes. It could be argued that developers should be fully aware whenever their app is moved to a major new dependency version.

Note that this does put extra onus on getting our [semantic versioning][semver] right. Before, it was just semantics, but if this RFC is approved, a developer's choice of versioning will determine whether or not a dependency will be automatically rolled out. That said, we do have existing [guidance on versioning our ruby gems][govuk-semver-guidance].

[govuk-semver-guidance]: https://docs.publishing.service.gov.uk/manual/publishing-a-ruby-gem.html#versioning
[rails-major-upgrade]: https://docs.publishing.service.gov.uk/manual/keeping-software-current.html#rails
[semver]: https://semver.org/

#### 5. During office hours

We want to limit the times at which auto-merging can take place, to typical office hours only. If a gem with a bug were to be released at 5pm on a Friday, this wouldn't be deployed into the apps until after most people have stopped working for the week, potentially creating work for those on-call if there is a user-facing impact.

We propose that auto-merging should happen around 9:30am, Monday to Friday, for reasons outlined below.

We considered a [number of different ways][different-ways-to-defer-merging] of limiting the window during which auto-merging should happen. After [investigating][schedule-merge-investigation], there doesn't seem to be a reliable way auto-approving a Dependabot PR and then scheduling the merging of that PR to happen during office hours.

Comparatively, it's trivial to [configure Dependabot to run at certain times][dependabot-configure-timing]. Currently, we set no such preference, so Dependabot often [raises PRs outside of office hours][example-dependabot-pr-out-of-hours]. We therefore propose configuring Dependabot to check for new versions at 9:30am, Monday to Friday. The proposed auto-merge implementation relies on triggering a webhook whenever a Dependabot PR is opened, so this should comfortably restrict auto-merging to happen only in office hours.

As an aside: setting the `schedule.day` and/or `schedule.time` configs [does not prevent security PRs from being raised][schedule-security] outside of those times. This is a good thing, and regardless, an external dependency update would not be auto-merged, even if it were a security one (that's perhaps a discussion for another RFC!).

There is one last consideration: Bank Holidays. We want to avoid auto-merging on Bank Holidays as these would be outside of office hours.

Bank Holidays are typically Mondays or Fridays, so we could restrict Dependabot's configuration further, to only raise Dependabot PRs between Tuesday and Thursday. However, this would introduce unnecessary delays for sometimes very important (security) fixes, and also glosses over the fact that some Bank Holidays around Christmas might fall on a different weekday.

Therefore, we propose writing an additional "validate this is not a bank holiday" step into the auto-merge process, which will use [GOV.UK's Bank Holidays API][bank-holidays-api] to ensure that the current date is not a bank holiday. If, for example, Dependabot runs on a Monday that happens to also be a Bank Holiday, the auto-merge would not happen and a developer would need to merge the PR manually at a later date.

[bank-holidays-api]: https://www.gov.uk/bank-holidays.json
[dependabot-configure-timing]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#scheduletime
[different-ways-to-defer-merging]: https://github.com/alphagov/govuk-rfcs/pull/156#issuecomment-1427552572
[example-dependabot-pr-out-of-hours]: https://github.com/alphagov/content-data-admin/pull/1176
[schedule-merge-investigation]: https://github.com/alphagov/govuk-rfcs/pull/156#issuecomment-1431282282
[schedule-security]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#configuration-options-for-the-dependabotyml-file

### Auto-merge implementation

Platform Reliability completed a [spike][] enabling the automatic merging of patch releases of `govuk_publishing_components`, for the `govuk-developer-docs` repository only. It successfully [auto-approved and auto-merged a qualifying PR][example-pr]. The automation relied on three steps:

1. [Check that the PR matches the criteria above][step-1]
2. [Approve the PR][step-2]
3. [Merge the PR][step-3]

There are some nuances to step 2. There is an [org-wide setting][] to "Allow GitHub Actions reviews to count towards required approval", so it should be possible for the GitHub Actions bot to approve these PRs. However, we currently have that setting disabled, following a [GDS-wide RFC][]. For the spike, we passed a personal access token to the `hmarr/auto-approve-action` instead, which is not subject to the org-wide setting. It therefore looks as though a developer manually approved the example PR, but in reality it was entirely automated.

Whilst we could enable the org wide setting, or follow the spike approach creating a personal access token (this time for a shared CI account), both of these are [vulnerable to privilege escalation][privilege-escalation]. Consider a developer who does not have admin access to GitHub repositories, thus can't override the mandatory review requirement. A sufficiently motivated developer (or bad actor who has compromised said developer's account) could craft a PR with a GitHub Action workflow that uses the GitHub Actions bot (or shared personal access token) to auto-approve their own PR, giving them free rein to merge malicious code.

For production, it would be safer to use an external mechanism for auto-approving and auto-merging PRs. See the proposed actions below.

[example-pr]: https://github.com/alphagov/govuk-developer-docs/pull/3825
[GDS-wide RFC]: https://docs.google.com/document/d/1IFz7E4DcWJ09giNB38fxfccU6fdW4TrQi722zztmSxs/edit#heading=h.au70tiw6t1oo
[org-wide setting]: https://github.blog/changelog/2022-01-14-github-actions-prevent-github-actions-from-approving-pull-requests/
[privilege-escalation]: https://medium.com/cider-sec/bypassing-required-reviews-using-github-actions-6e1b29135cc7
[spike]: https://github.com/alphagov/govuk-developer-docs/blob/68146cbddadb6adbf96fe3caaf15a3210ca66a37/.github/workflows/dependabot-auto-merge.yml
[step-1]: https://github.com/alphagov/govuk-developer-docs/blob/68146cbddadb6adbf96fe3caaf15a3210ca66a37/.github/workflows/dependabot-auto-merge.yml#L9-L43
[step-2]: https://github.com/alphagov/govuk-developer-docs/blob/68146cbddadb6adbf96fe3caaf15a3210ca66a37/.github/workflows/dependabot-auto-merge.yml#L48-L51
[step-3]: https://github.com/alphagov/govuk-developer-docs/blob/68146cbddadb6adbf96fe3caaf15a3210ca66a37/.github/workflows/dependabot-auto-merge.yml#L52-L56

## Actions

This RFC proposes the following actions.

### Build an auto-merge service

Platform Reliability will build an auto-merge service, which is called via webhooks configured on every GOV.UK repository. These webhooks can be automatically configured using the [existing govuk-saas-config method for defining webhooks][govuk-saas-config-webhooks]. The webhook would be triggered via pull request.

The service would retrieve the pull request details and fetch a configuration file from the repo in question to determine which internal dependencies are candidates for auto merge (see below), or exit early if no such file exists. It would then follow the same validation steps that were in the spike, i.e. validate that the auto-merge criteria are all met. If the criteria are met, the service would use an access token (associated with a CI account) to approve and merge the PR.

Defining where the service is hosted, and how the keys are stored and accessed, are out of scope for this RFC.

[govuk-saas-config-webhooks]: https://github.com/alphagov/govuk-saas-config/blob/8cfb23db6a200214411fc1de150d3c8582950588/github/lib/configure_repo.rb#L55

### Trial the auto-merge service on one repo

For one repository, Platform Reliability will create the auto merge configuration file and also configure Dependabot to raise PRs during office hours. They will trial it for a number of weeks to ensure that the auto merge service works as intended.

The configuration will be expanded from the initial spike, to include both patch and minor version bumps, of the following internal dependencies (but only where those dependencies are present in the repo):

- `govuk_publishing_components` (18 versions - not including 3 major increases - between October 2022 and January 2023, across 32 apps)
- `govuk_app_config` (6 versions - not including 1 major release - between October 2022 and January 2023)
- `gds-api-adapters` (3 major versions between October 2022 and January 2023. 0 minor/patch ones. However, between July and August 2022 there were 4 qualifying patch increases we could have automated.)
- `rubocop-govuk` (2 versions - 0 major ones - between October 2022 and January 2023, across a large number of repositories)

For `govuk_publishing_components` alone, we've had 576 PRs between October 2022 and January 2023, all of which could have been auto mergeable. If we estimate a minute of due diligence per PR, that amounts to almost 10 hours of wasted dev time.

A possible implementation of the configuration file is below, but this is subject to change:

```yaml
# /.govuk_auto_merge_pr.yml
auto_approve_and_merge:
  version: 1
  merge_dependencies:
    - govuk_publishing_components
    - rubocop-govuk
  merge_versions:
    - patch
    - minor
```

### Raise initial config PRs

Following a successful trial, Platform Reliability will raise PRs for all applicable GOV.UK repos. Each PR will configure Dependabot to run during office hours, and create the auto-merge configuration file.

Whilst Platform Reliability would create the initial PRs, it would be up to the owning teams to decide whether or not to merge, and to what extent they'd want to reconfigure the repo and version scopes. We will stipulate that teams must not include external dependencies on the auto-merge list, and must not enable auto-merging without also restricting the Dependabot schedule times.

### Review in 3 months

3 months after raising the auto-merge configurations, Platform Reliability will review the success of the trial, noting any related incidents and also quantifying a rough figure of PRs that have been auto-merged and a reasonable estimate of the resulting time saved.

If the trial is deemed successful, we will keep the configurations and the auto-merge service, and update several pieces of documentation:

1) Update [The GDS Way][] to highlight GOV.UK's policy on auto-merging. Auto-merging goes against the current guidance in The GDS Way, introduced in [gds-way#428][gds-way#428] to document the consensus at the time, though with no reasoning provided.
2) Update [Manage Ruby Dependencies][] (internal doc) to reference the auto-merging.

[gds-way#428]: https://github.com/alphagov/gds-way/pull/428
[Manage Ruby Dependencies]: https://docs.publishing.service.gov.uk/manual/manage-ruby-dependencies.html
[The GDS Way]: https://gds-way.cloudapps.digital/standards/tracking-dependencies.html#update-dependencies-frequently

If the trial is unsuccessful, we will remove all the configurations, terminate the auto-merge service, and add an updated note to the top of this RFC.
