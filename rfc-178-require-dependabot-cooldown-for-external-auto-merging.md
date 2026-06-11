---
status: accepted
implementation: done
status_last_reviewed: 2026-06-11
---

# Require Dependabot cooldown for external dependency auto-merging

## Summary

[RFC-167][] allowed repositories to opt into auto-merging external dependencies via [govuk-dependabot-merger][]. [PR #131][pr-131] removed that ability as a supply chain hardening measure. This RFC brings it back, with one new rule: the repository's `.github/dependabot.yml` MUST configure a [cooldown][] of at least 3 days (`default-days: 3` or higher).

## Problem

Removing external auto-merging was the right call at the time. But it shifted the burden back onto teams who now have to manually review and merge low-risk external updates that CI, security scanning, and test suites already validate.

The original argument in RFC-167 still stands: human review of dependency PRs is largely theatre. Over 90% of engineers weren't following the review guidance anyway, and even those who did couldn't meaningfully catch a determined supply chain attack by reading a changelog.

What's changed since PR #131 is that Dependabot now supports [cooldown][]. Cooldown holds off raising a PR until a package version has been publicly available for a configurable number of days. Malicious or broken releases tend to get flagged within hours. A 3-day window catches the vast majority of these before a PR ever gets opened.

## Proposal

Bring back `update_external_dependencies` in govuk-dependabot-merger. Add one gate: govuk-dependabot-merger checks the repo's `.github/dependabot.yml` for a `cooldown` setting with `default-days` >= 3. If that's missing or too low, external PRs don't get merged and a warning gets logged.

Repos that never set `update_external_dependencies` won't notice any change. The default stays `false`.

### Why 3 days?

Most malicious packages get pulled within hours. Three days is conservative enough to catch stragglers while still being useful. It also matches what we already use on [govuk-dependabot-merger itself][own-dependabot-yml].

### Configuration

Two files need to agree. In `.govuk_dependabot_merger.yml`:

```yaml
api_version: 2
defaults:
  update_external_dependencies: true
  auto_merge: true
  allowed_semver_bumps:
    - patch
    - minor
```

And in `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: bundler
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 3
```

Per-dependency overrides still work:

```yaml
api_version: 2
defaults:
  update_external_dependencies: false
  auto_merge: true
overrides:
  - dependency: some-special-external-dependency
    update_external_dependencies: true
```

### Conditions

Everything from [RFC-167][] still applies. On top of that:

- Repositories MUST have `cooldown` in `.github/dependabot.yml` with `default-days` >= 3
- Repositories MUST explicitly set `update_external_dependencies: true` (default remains `false`)

If a repo opts in but doesn't meet the cooldown requirement, govuk-dependabot-merger blocks external merges and logs a warning explaining why.

### Implementation

Changes to [govuk-dependabot-merger][]:

1. Restore `update_external_dependencies` (reverts [PR #131][pr-131])
2. Fetch the repo's `.github/dependabot.yml` and check cooldown `default-days` >= 3
3. Log a warning when cooldown is missing or insufficient
4. Update docs and tests

One extra GitHub API call per repo per run.

[RFC-167]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-167-auto-patch-dependencies.md
[govuk-dependabot-merger]: https://github.com/alphagov/govuk-dependabot-merger
[pr-131]: https://github.com/alphagov/govuk-dependabot-merger/pull/131
[cooldown]: https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-
[own-dependabot-yml]: https://github.com/alphagov/govuk-dependabot-merger/blob/main/.github/.dependabot.yml
