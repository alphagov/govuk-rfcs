# Custom configuration for Dependabot

## Summary

Introduce stricter configuration for Dependabot to reduced number of open PRs, number of deployments and effort required to ensure apps always use the latest version of libraries that we care about.

## Problem

Dependabot was enabled across all our applications in 2018. Due to the number of applications we have and libraries we use, keeping on top of the number of PRs raised by Dependabot has been difficult.

A few solutions have been implemented in the past to make this better:

- [govuk-dependencies] shows the list of open PRs grouped by application, team or gem.
- [govuk-dependencies] has a Slack bot which automatically messages in each team's channel with a list of open PRs.
- We [allowed merging Dependabot PRs without requiring two approvals][rfc-103].
- [Sharing the responsibility for Dependabot PRs across multiple times][dependencies-team].
- We've configured Dependabot to [only update top-level dependencies in some repos][top-level-dependencies].

[govuk-dependencies]: http://govuk-dependencies.herokuapp.com/
[rfc-103]: https://github.com/alphagov/govuk-rfcs/blob/master/rfc-103-merge-dependabot-pull-requests-with-a-single-review.md
[dependencies-team]: https://github.com/alphagov/govuk-developer-docs/pull/2168
[top-level-dependencies]: https://github.com/alphagov/govuk-rfcs/pull/126#discussion_r439333182

Although these have made improvements to the process, the number of open PRs remains unmanageable. At the time of writing, there are 135 open PRs, of which there are [8 labelled as security fixes][security-prs], the oldest being 21 days old. Dependabot is currently configured to have at most 5 open PRs per repo, which means this number is not the true number and often new PRs will open the moment existing ones are closed down.

[security-prs]: https://github.com/pulls?q=is%3Apr+author%3Aapp%2Fdependabot-preview+user%3Aalphagov+archived%3Afalse+is%3Aopen+label%3Asecurity

This high number of open PRs is felt particularly hard by the Platform Health team, as they currently [own 55 out of 73 applications][application-owners].

[application-owners]: https://docs.publishing.service.gov.uk/apps/by-team.html

By having so many open PRs, it becomes difficult to be able to prioritise important updates (bug fixes, security fixes, internal updates) over new versions which simply adds new features (which our apps don't necessarily use anyway). This leads to important updates being left for long periods of time and our desire to close down all the PRs means developers spend time investigating and fixing complex problems without any benefit.

### Statistics

I pulled together [some statistics on our Dependabot usage][dependabot-stats]:

A total of 17,526 PRs have been opened since we started using Dependabot. Of which, 7,378 would be considered external libraries (not security fixes, not our own libraries and not core requirements, for example Rails).

The majority of PRs are merged within a few days (on average 2.5 days). However, the PRs that require manual intervention (for example, failing tests) tend to take a significant amount of time to be merged (on order of months). Because of this talking in terms of averages tends to be less representative of the actual situation, but it can be useful to make comparisons.

The libraries that take the longest time to merge are `acts-as-taggable-on`, `paper_trail`, `rails-controller-testing`, `mini_magick` and `gds-sso`. Our own libraries are merged in on average after 1.5 days, whereas third party libraries are merged in after 4 days.

The most problematic libraries (ones where there is a higher proportion of PRs taking a long time to be merged in) tend to be those that are not owned by us and not a core requirement of the app (for example `acts-as-taggable-on`, `paper_trail`, `rails-controller-testing`, `mini_magick` and `excon`.

[dependabot-stats]: https://github.com/thomasleese/dependabot-stats

<details>
    <summary>Full results</summary>

```
All PRs
=======
Total PRs: 17526
Mean time to merge: 2 days, 15:35:42.556088
Max time to merge: 189 days, 5:50:39
Top 5 longest libraries to merge: acts-as-taggable-on (146 days, 3:40:01), paper_trail (85 days, 7:45:33), rails-controller-testing (84 days, 3:29:26), mini_magick (41 days, 4:15:20), gds-sso (38 days, 17:12:39)
Top 5 quickest libraries to merge: actionview (0:05:42), miller-columns-element (0:05:36), faraday_middleware (0:03:30), webrick (0:01:17), nltk (0:01:14)

Security PRs
============
Total PRs: 675
Mean time to merge: 1 day, 22:01:29.564444
Max time to merge: 40 days, 18:54:18
Top 5 longest libraries to merge: secure_headers (28 days, 4:50:14), doorkeeper (19 days, 7:14:41), excon (15 days, 7:26:22), jquery-rails (13 days, 9:40:30), rack (11 days, 14:55:34)
Top 5 quickest libraries to merge: json (0:52:52), sprockets (0:38:34), rack-protection (0:19:10), actionview (0:05:42), webrick (0:01:17)

Non-security PRs
================
Total PRs: 16851
Mean time to merge: 2 days, 16:17:56.279271
Max time to merge: 189 days, 5:50:39
Top 5 longest libraries to merge: acts-as-taggable-on (146 days, 3:40:01), paper_trail (85 days, 7:45:33), rails-controller-testing (84 days, 3:29:26), mini_magick (41 days, 4:15:20), excon (41 days, 0:57:48)
Top 5 quickest libraries to merge: docker-compose (0:12:51), vcr (0:10:44), miller-columns-element (0:05:36), faraday_middleware (0:03:30), nltk (0:01:14)

Security Libraries
==================
Total PRs: 675
Mean time to merge: 1 day, 22:01:29.564444
Max time to merge: 40 days, 18:54:18
Top 5 longest libraries to merge: secure_headers (28 days, 4:50:14), doorkeeper (19 days, 7:14:41), excon (15 days, 7:26:22), jquery-rails (13 days, 9:40:30), rack (11 days, 14:55:34)
Top 5 quickest libraries to merge: json (0:52:52), sprockets (0:38:34), rack-protection (0:19:10), actionview (0:05:42), webrick (0:01:17)

Internal Libraries
==================
Total PRs: 8528
Mean time to merge: 1 day, 12:06:12.839822
Max time to merge: 154 days, 6:12:55
Top 5 longest libraries to merge: gds-sso (38 days, 17:12:39), govuk_app_config (13 days, 17:41:26), govuk_test (5 days, 0:17:42), plek (2 days, 8:29:52), govspeak (1 day, 9:19:06)
Top 5 quickest libraries to merge: gds-api-adapters (1 day, 9:03:58), govuk_schemas (6:57:43), rubocop-govuk (1:35:22), govuk_sidekiq (1:09:51), govuk_publishing_components (0:42:20)

Framework Libraries
===================
Total PRs: 1013
Mean time to merge: 5 days, 13:10:44.532083
Max time to merge: 189 days, 5:50:39
Top 5 longest libraries to merge: factory_bot_rails (23 days, 4:31:45), sass-rails (13 days, 20:36:55), rails (8 days, 1:23:13.750000), jasmine (4 days, 13:56:06.500000), rspec-rails (1 day, 2:18:37)
Top 5 quickest libraries to merge: factory_bot_rails (23 days, 4:31:45), sass-rails (13 days, 20:36:55), rails (8 days, 1:23:13.750000), jasmine (4 days, 13:56:06.500000), rspec-rails (1 day, 2:18:37)

Third Party Libraries (Framework + Ignored)
===========================================
Total PRs: 8391
Mean time to merge: 3 days, 20:52:04.355023
Max time to merge: 189 days, 5:50:39
Top 5 longest libraries to merge: acts-as-taggable-on (146 days, 3:40:01), paper_trail (85 days, 7:45:33), rails-controller-testing (84 days, 3:29:26), mini_magick (41 days, 4:15:20), excon (41 days, 0:57:48)
Top 5 quickest libraries to merge: docker-compose (0:12:51), vcr (0:10:44), miller-columns-element (0:05:36), faraday_middleware (0:03:30), nltk (0:01:14)

All Allowed Libraries (Security + Internal + Framework)
=======================================================
Total PRs: 10216
Mean time to merge: 1 day, 22:23:05.722886
Max time to merge: 189 days, 5:50:39
Top 5 longest libraries to merge: gds-sso (38 days, 17:12:39), secure_headers (28 days, 4:50:14), factory_bot_rails (23 days, 4:31:45), doorkeeper (19 days, 7:14:41), excon (15 days, 7:26:22)
Top 5 quickest libraries to merge: govuk_publishing_components (0:42:20), sprockets (0:38:34), rack-protection (0:19:10), actionview (0:05:42), webrick (0:01:17)

Ignored Libraries
=================
Total PRs: 7378
Mean time to merge: 3 days, 15:19:59.342911
Max time to merge: 146 days, 3:40:01
Top 5 longest libraries to merge: acts-as-taggable-on (146 days, 3:40:01), paper_trail (85 days, 7:45:33), rails-controller-testing (84 days, 3:29:26), mini_magick (41 days, 4:15:20), excon (41 days, 0:57:48)
Top 5 quickest libraries to merge: docker-compose (0:12:51), vcr (0:10:44), miller-columns-element (0:05:36), faraday_middleware (0:03:30), nltk (0:01:14)
```
</details>

## Proposal

We will configure Dependabot to only raise PRs against libraries that fit within one of three categories. Any updates to libraries which don't fit into one of these categories will be ignored and PRs won't be raised for them.

The three categories are:

- [Security updates]
- Internal libraries - these are libraries written by us (for example `gds-api-adapters`, `govuk_publishing_components`)
- Framework libraries - these are libraries which our apps heavily rely on to work (for example `rails`, `rspec-rails`)

These categories have been chosen to ensure we stay up to date on libraries which are important to us while also reducing the number of unnecessary version bumps.

[Security updates]: https://help.github.com/en/github/managing-security-vulnerabilities/configuring-github-dependabot-security-updates#about-github-dependabot-security-updates

### Custom configuration

Dependabot [supports configuration files][dependabot-config] stored in each repo to customise its behaviour. This RFC proposes using a configuration file like the one detailed below in each of our repos.

We've already been trialing this out in [Content Publisher] and [govuk_publishing_components], based on some initial experiements in [Signon].

[dependabot-config]: https://dependabot.com/docs/config-file/
[Content Publisher]: https://github.com/alphagov/content-publisher/pull/2062
[govuk_publishing_components]: https://github.com/alphagov/govuk_publishing_components/pull/1564
[Signon]: https://github.com/alphagov/signon/pull/1426

```yaml
version: 1
update_configs:
  - package_manager: ruby:bundler
    directory: /
    update_schedule: daily
    allowed_updates:
      # Security updates
      - match: { update_type: security }
      - match: { dependency_name: brakeman }
      # Internal gems
      - match: { dependency_name: gds-api-adapters }
      - match: { dependency_name: gds-sso }
      - match: { dependency_name: govspeak }
      - match: { dependency_name: govuk* }
      - match: { dependency_name: rubocop-govuk }
      - match: { dependency_name: plek }
      - match: { dependency_name: scss_lint-govuk }
      # Framework gems
      - match: { dependency_name: factory_bot_rails }
      - match: { dependency_name: jasmine }
      - match: { dependency_name: rails }
      - match: { dependency_name: rspec-rails }
      - match: { dependency_name: sass-rails }
  - package_manager: javascript
    directory: /
    update_schedule: daily
    allowed_updates:
      # Security updates
      - match: { update_type: security }
      # Internal packages
      - match: { dependency_name: accessible-autocomplete }
      - match: { dependency_name: markdown-toolbar-element }
      - match: { dependency_name: miller-columns-element }
      - match: { dependency_name: paste-html-to-govspeak }
```

### Keeping the configuration up to date

Most of our applications use the same internal and framework libraries, so we'll want a single global configuration across all our apps. At the same time, there might be some libraries used by particular apps which fit within one of the three categories.

Maintaining this file across each of our apps has the potential for it to become out of date with our global configuration. To solve this problem, this RFC proposes that we add functionality to [govuk-saas-config] which ensures the configuration file in each repo is up to date with a single global configuration file. Keeping up to date means ensuring that the individual repo configuration file contains at least the global configuration options plus any extra custom configuration for the app itself.

Due to the fact that the configuration file is stored in the Git repo, [govuk-saas-config] will need to raise a PR to keep the configuration in sync rather than writing to the repo directly. This is similar to a script we have for [upgrading Ruby].

[govuk-saas-config]: https://github.com/alphagov/govuk-saas-config
[upgrading Ruby]: https://github.com/thomasleese/upgrade-ruby-version/blob/7d43077a10c732fc285e0bd6daad2d2c5740e352/main.py#L203-L207

### Possible alternatives

#### Auto-merge

The proposal in this RFC [came from an earlier discussion of enabling auto-merge on our PRs][auto-merge-discussion]. Auto-merge is a feature which means [version bump PRs will automatically be merged][auto-merge] by Dependabot provided the tests are passing and the necessary approvals have been received.

The idea is that by auto-merging our PRs, we wouldn't have to spend so much time dealing with them. However, there are a few reasons why this isn't possible at the moment:

- We require approvals for all our PRs. Merging in the PR isn't what takes up the time, so having them merge automatically would only shave off a small amount of time.
- The auto-merge functionality has to be enabled across the entire Dependabot account. We use a shared account across GDS. For this reason, and others, we [weren't able to turn it on][auto-merge-gds-way].

[auto-merge]: https://dependabot.com/blog/automatic-pull-request-merging/
[auto-merge-discussion]: https://docs.google.com/document/d/18P86EFSZdG8Uv5scbGzVoO8KhA3hkKp80UlzNoIctNE/edit
[auto-merge-gds-way]: https://github.com/alphagov/gds-way/pull/428#discussion_r426502446

#### Limit updates to lockfile

Another option might be to limit Dependabot to only raise PRs against the `Gemfile.lock` file. The lockfile is used to pin a specific version, whereas the `Gemfile` can contain a wider version range (for example `~> 1.0` means `1.0 all the way up to but not including 2.0`). The way this would be set up is that Gems we would want to update would have little to no restriction, whereas Gems we'd prefer to be left would have a more precise version specification.

Unfortunately applying this would mean [we lose the security updates that do require an update to the `Gemfile`][dependabot-security-lockfile].

[dependabot-security-lockfile]: https://github.com/dependabot/feedback/issues/937

#### Major/minor/patch

This solution proposed above ignores all updates for libraries not in one of the three categories, regardless of whether the update is a major, minor or patch update. An alternative might be to include PRs for major updates for other libraries.

Looking through the Dependabot config docs, [it doesn't seem to be possible to enable major updates][dependabot-allowed-updates]. Regardless, major updates tend to be the ones that take the longest time to merge, so enabling them wouldn't reduce much of the workload.

[dependabot-allowed-updates]: https://dependabot.com/docs/config-file/#allowed_updates

#### Opt-out rather than opt-in

Rather than having a list of libraries we allow updating, we could instead [maintain a list of libraries we ignore updates for][dependabot-ignored-updates].

This would allow us to remove the hardest PRs from updates, but it would require us to be more on top of maintaining the list. I'm also not sure how it would work with enabling security updates regardless.

[dependabot-ignored-updates]: https://dependabot.com/docs/config-file/#ignored_updates

## Consequences and measuring success

Using [the statistics from above](#Statistics), we can make some estimates on what affect this would have had if it had been enabled from the beginning:

- 7378 PRs wouldn't have been raised (10216 rather than the 17526 we've had so far).
- The mean time to merge would have decreased from almost 3 days to just under 2 days.
- The ignored libraries alone would have taken on average 3.5 days to merge.

In theory, by limiting the number of libraries that get updated by Dependabot, our applications would end up less up to date. However, by prioritising certain libraries over others, we should end up in a situation where our applications are actually _more_ up to date in the areas we care about (security, frameworks, internal libraries).

We should expect to see the average time for PRs to be merged in (and in particular security PRs) to reduce. We should also expect to see a reduction in the number of open PRs, and also a reduction in the number of deployments.

A less measurable metric is that we would expect developers to be spending less time fixing issues in Dependabot PRs.

If we see a situation where most days we don't have any new Dependabot PRs, we could think about losening these restrictions and opening up the number of libraries we want to received updates on.

This RFC proposes that we review the situation six months after the deployment of the global Dependabot configuration to ensure that this has made a difference to the workload. This will be achieved by talking to developers and using some updated statistics. This review will be owned by the Platform Health team.
