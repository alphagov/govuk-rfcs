# Revert RFC 126

## Summary

[RFC-126][] was agreed and merged in June 2020 and implemented between July and September. Its aim was to reduce the "number of open PRs, number of deployments and effort required to ensure apps always use the latest version of libraries that we care about". The RFC was subject to a [review period][rfc-126-review-period] to determine whether or not it resulted in a "reduction in workflow as anticipated", and "whether the process of manually maintaining the configuration files is workable".

That review has now been completed, concluding that RFC-126 inadvertently stopped Dependabot from raising security updates. It succeeded in reducing the number of PRs raised, but made little difference to the velocity at which teams merge PRs. It also made no noticable difference to the effort required, which has been far more directly influenced by the new team structure and the roll-out of Continuous Deployment.

This RFC proposes reverting most of the configuration introduced in RFC-126, recognising that it will lead to a moderate increase in PRs raised, but with the benefits of receiving all security updates, keeping more dependencies up to date, and simplifying our configs.

## Problem

Platform Reliability's [report][] found that RFC-126:

- Succeeded in reducing the number of PRs
- Did not lead to dependencies being merged any faster
- Inadvertently configured Dependabot to ignore security updates for libraries not explicitly on the allow list

### Did the RFC reduce the number of open PRs?

Yes, by around 36%. This is based on a rough estimate of a rolling average of 550 PRs pre-RFC, down to around 350 PRs post-RFC.

### Did the RFC result in apps always using the latest version of libraries we care about?

The 'time to merge' metric suggests that teams haven't found it any easier to keep their dependencies up to date, despite fewer PRs being raised and despite RFC-126 identifying these dependencies as important.

Merge times for internal libraries have grown from 1-2 days to around 2-5 days, and merge times for framework libraries remains about the same as before. We can therefore presume that the RFC did not help "ensure apps always use the latest version of libraries that we care about".

### Did the RFC reduce the effort required?

Since summer 2020, the state of ownership and deployment processes on GOV.UK has changed significantly.

Much of the pain in dependency management is in the deployment of the newly updated applications; this pain largely disappears when an application has [continuous deployment][] enabled. At the time of the RFC, only [around half of applications were continuously deployed][cd-spreadsheet]. The figure is now almost 80%.

Another barrier to keeping on top of dependencies was the disproportionate burden on certain teams. The Platform Health team referenced by the RFC as owning "55 out of 73 applications" no longer exists. In late 2021, GOV.UK moved to a service team model, with repositories now spread more evenly amongst [several teams][].

Finally, the number of repos with `dependabot.yml` files has continued to grow. It is therefore difficult to quantitatively measure whether effort around dependency management has reduced as a direct result of RFC-126.

We know that teams have had to reprioritise work at short notice to deal with security vulnerabilities, and anecdotally we know that the effort required was much greater when Dependabot did not raise the PRs for them. Therefore even if RFC-126 succeeded in reducing effort required generally, it has led to an increase in effort required for some of the most time-sensitive updates, and is probably a net increase of effort overall.

### Is it workable to maintain so many configuration files?

Since the RFC was implemented, we've not made any significant changes to the Dependabot configuration. In the few cases we've made changes en-masse (e.g. the [stylelint-config-gds rollout][]), it does not appear to have been a hindrance.

However, configurations are now spread across [over a hundred repositories][github-search], which does make policy changes difficult to apply globally.

### Impact of RFC-126 on security

There wasn't a specific security-related goal for RFC-126, but security updates were highlighted as important in the [proposal][rfc-126-proposal], and care was taken to [avoid options that lose security updates][rfc-126-lockfile]. Despite this, the Dependabot config arrived at in RFC-126 now prevents any security updates being raised for libraries not on the allow list.

Our configs make use of 'allow lists', which [only allow direct updates to each named dependency, e.g. Rails][dependabot-config-example]. If there is an update to a subdependency, then no Dependabot PR is raised for that. There was recently a [vulnerability in Active Record][CVE-2022-32224], a subdependency of Rails, and no Dependabot PR was raised to fix it until a day later, when the [fixed version happened to be bundled into a new version of Rails][CVE-2022-32224-auto-fix]. In many cases, we [fixed the vulnerability manually][CVE-2022-32224-manual-fix] the day it was disclosed.

### Statistics

RFC-126 included [statistics][rfc-126-statistics] describing the Dependabot PRs raised up until June 2020. We've collected some updated statistics as part of this RFC.

A total of 16,208 Dependabot PRs were opened before 11th of June 2020:

- 7,980 (~49%) were from our own internal libraries (for example `govuk_publishing_components`)
- 929 (~6%) were core requirements for our apps (for example `rails`)
- 6,733 (~42%) were other libraries

<details>
    <summary>Dependabot PRs prior to 11th June 2020</summary>

```
Internal libraries:
Mean time to merge: 1 day, 16:02:30
Max time to merge: 154 days, 6:12:55

Top 5 slowest libraries to merge:
- govuk_message_queue_consumer (9 days, 8:11:00)
- govuk_ab_testing (9 days, 5:11:36)
- govuk_document_types (8 days, 5:22:27)
- plek (6 days, 10:31:16)
- gds-api-adapters (3 days, 16:27:39)

Top 5 fastest libraries to merge:
- gds-sso (3:13:31)
- govuk_app_config (2:21:45)
- govspeak (2:07:33)
- rails_translation_manager (0:40:57)
- miller-columns-element (0:05:36)

Core libraries:
Mean time to merge: 5 days, 13:47:34
Max time to merge: 189 days, 5:50:39

Merge times for all:
- sass-rails (12 days, 20:24:49)
- rails (6 days, 22:56:51)
- rspec-rails (5 days, 21:50:59)
- factory_bot_rails (2 days, 13:22:01)
- jasmine (8:22:27)

Other libraries:
Mean time to merge: 3 days, 17:34:30
Max time to merge: 146 days, 3:40:01

Top 5 slowest libraries to merge:
- acts-as-taggable-on (146 days, 3:40:01)
- responders (92 days, 2:50:32)
- addressable (67 days, 10:45:56)
- mongo (62 days, 11:15:46)
- six (59 days, 22:45:39)

Top 5 fastest libraries to merge:
- pact_broker (0:13:28)
- docker-compose (0:12:51)
- loofah (0:11:10)
- puma (0:09:55)
- faraday_middleware (0:03:30)
```
</details>

A total of 9,137 Dependabot PRs were opened between 11th June 2020 and 18th July 2022:

- 6,127 (~67%) were from our own internal libraries
- 855 (~9%) were core requirements for our apps
- 2,079 (~23%) were other libraries

<details>
    <summary>Dependabot PRs between June 2020 and July 2022</summary>

```
Internal libraries:
Mean time to merge: 3 days, 12:56:00
Max time to merge: 120 days, 9:17:22

Top 5 slowest libraries to merge:
- govuk_test (31 days, 11:12:36)
- plek (24 days, 8:55:07)
- gds_zendesk (14 days, 2:35:41)
- stylelint-config-gds (7 days, 3:49:34)
- govuk_app_config (4 days, 6:15:11)

Top 5 fastest libraries to merge:
- govuk_publishing_components (1:25:30)
- gds-api-adapters (0:44:26)
- govuk_ab_testing (0:40:23)
- miller-columns-element (0:20:59)
- govuk_document_types (0:19:04)

Core libraries:
Mean time to merge: 5 days, 19:02:05
Max time to merge: 130 days, 9:06:13

Merge times:
- rspec-rails (14 days, 23:11:42)
- rails (4:38:04)
- jasmine (3:33:27)
- factory_bot_rails (0:59:47)

Other libraries:
Mean time to merge: 8 days, 4:08:29
Max time to merge: 419 days, 18:37:27

Top 5 slowest libraries to merge:
- middleman-gh-pages (419 days, 18:37:27)
- raven (192 days, 21:14:44)
- uk-postcode-utils (187 days, 4:58:09)
- shapely (159 days, 5:03:52)
- github.com/getsentry/sentry-go (107 days, 2:59:59)

Top 5 fastest libraries to merge:
- rake (0:03:27)
- aws-sdk-s3 (0:03:23)
- lodash (0:02:34)
- commonmarker (0:02:17)
- tar (0:01:51)
```
</details>

We can conclude that RFC-126 succeeded in reducing the number of Dependabot PRs that did not count as internal or framework dependencies.

## Proposal

Remove all `allow` lists from the `dependabot.yml` file on every GOV.UK repository. This will enable Dependabot PRs [on all dependencies in the lock file][dependabot-docs] of the corresponding [package ecosystem][dependabot-package-ecosystem], including security related PRs.

This is a reversal of RFC-126 as it means every dependency is given equal weighting, rather than us prioritising framework and internal libraries; a key part of the RFC. However, aspects of RFC-126 would remain, namely the Dependabot configuration files that have now been committed to each repository. Without these files, we would [lose all non-security-related version updates][dependabot-docs-delete].

Whilst this proposal will lead to a moderate increase in the number of PRs raised, the increase in continuously deployed apps and the new service teams model should lessen the resulting burden compared with how things were prior to RFC-126. Crucially, we would now receive all security updates as soon as they are available.

Platform Reliability plans to investigate other ways of reducing the effort associated with dependency upgrades, e.g. automatically merging certain PRs, but those ideas for future optimisations are out of scope for this RFC.

## Alternatives considered

### Do nothing

Continue to rely on our current configuration, and step in to fix vulnerabilities manually where required.

Doing nothing leaves us open to unnecessary risk, so this alternative was ruled out.

### Removing dependabot.yml files altogether

Removing the dependabot.yml files would disable version updates for all dependencies, though would [enable security updates][dependabot-docs-security]. We want to continue receiving version updates for a number of important dependencies, so this alternative was ruled out.

### Enable security updates through Dependabot configuration

A [spike to change the Dependabot config to allow security updates][dependabot-config-spike] showed that Dependabot is not flexible or powerful enough to allow us to retain our existing allow-lists and also enable security updates globally.

Instead, we would need to remove the `allow` list and introduce an `ignore` list, which treats security PRs differently.

Given the number of dependencies and subdependencies for each app, we would need to automate this. The approach would involve going into every repository and writing a script that:

1. compares all 'allowed' bundler dependencies (defined elsewhere, e.g. in a file called `dependabot.template.yml`) with all dependencies in `Gemfile.lock`, retrieving the subset of dependencies that are not allowed.
1. generates a `dependabot.yml` (by taking the `dependabot.template.yml`, removing the 'allow list' and then adding the other dependencies to an 'ignore list'), whilst leaving the rest of the template untouched (e.g. properties such as 'interval').
1. does the same thing above but for the 'pip' package manager
1. does the same thing above but for the 'npm' package manager
1. potentially does the same thing above but for the 'docker' and 'github-actions' package managers
1. NB: each of the implementations above would have to be slightly different, due to the way lockfiles/manifests differ between programming languages.

We'd then need to automatically call this script whenever a dependency changes, such as after a `bundle install` or `npm update`. That might mean packaging the script up as a bundler plugin, and another plugin for every other package manager, but it would probably be more efficient to make this a pre-commit hook, or even a GitHub Actions action that runs nightly and pushes an updated `dependabot.yml` file to `main`.

This route is a lot of work, with a lot of moving parts that could go wrong. There's also no guarantee GitHub won't tweak how the 'ignore list' works and have that disallow security PRs too. For all the effort and risk involved, this alternative was ruled out.

[cd-spreadsheet]: https://docs.google.com/spreadsheets/d/1SvSiMUCbpZNe2Bc_k9uZTZipKY-eigaGnVPL9eOIX6o/edit#gid=804888136
[continuous deployment]: https://insidegovuk.blog.gov.uk/2021/08/05/how-and-why-we-switched-to-continuous-deployment-on-gov-uk/
[CVE-2022-32224]: https://github.com/advisories/GHSA-3hhc-qp5v-9p2j
[CVE-2022-32224-auto-fix]: https://github.com/alphagov/content-publisher/pull/2541
[CVE-2022-32224-manual-fix]: https://github.com/alphagov/smokey/pull/1000
[dependabot-config-example]: https://github.com/alphagov/content-publisher/blob/eec05b0156d8e37f9cee022f6dac4e38dbab7b58/.github/dependabot.yml#L27-L28
[dependabot-config-spike]: https://github.com/alphagov/content-data-admin/pull/1071
[dependabot-docs]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#allow
[dependabot-docs-delete]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates#disabling-dependabot-version-updates
[dependabot-docs-security]: https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/configuring-dependabot-security-updates
[dependabot-package-ecosystem]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem
[github-search]: https://github.com/search?l=&p=1&q=org%3Aalphagov+%22updates%22+path%3A.github+filename%3Adependabot.yml&ref=advsearch&type=Code
[report]: https://docs.google.com/document/d/1FHwg_V-JT_CVICkrtz-ESeQJ2Dz8ECdG42uIzSsNP4c/edit
[RFC-126]: https://github.com/alphagov/govuk-rfcs/pull/126
[rfc-126-lockfile]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-126-custom-configuration-for-dependabot.md#limit-updates-to-lockfile
[rfc-126-proposal]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-126-custom-configuration-for-dependabot.md#proposal
[rfc-126-review-period]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-126-custom-configuration-for-dependabot.md#review-period
[rfc-126-statistics]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-126-custom-configuration-for-dependabot.md#statistics
[several teams]: https://docs.publishing.service.gov.uk/repos.html#repos-by-team
[stylelint-config-gds rollout]: https://trello.com/c/MeG1zc2m/195-roll-out-stylelint-config-gds-across-govuk
