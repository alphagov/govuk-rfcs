## Problem

The Publishing Platform team is currently working on adding request tracing to all apps that use the Publishing API in an asynchronous way via Sidekiq - [https://github.com/alphagov/collections-publisher/pull/194](https://github.com/alphagov/collections-publisher/pull/194)&nbsp;and&nbsp;[https://github.com/alphagov/whitehall/pull/2567](https://github.com/alphagov/whitehall/pull/2567). This will need repeating across many apps. The implementation is sufficiently complex that a mass-change of all apps in the future is not unlikely.

A previous shotgun surgery on apps with Sidekiq was the adding of sidekiq-statsd -&nbsp;[https://trello.com/c/z2aHqwS8/48-add-sidekiq-statsd-to-apps-that-use-sidekiq](https://trello.com/c/z2aHqwS8/48-add-sidekiq-statsd-to-apps-that-use-sidekiq)&nbsp;which needed ~10 PRs.

There are ~15 GOV.UK apps that use Sidekiq, and they all use slightly different versions, logging and configuration.

## Proposal

Introduce a `govuk-sidekiq` gem that consolidates all GOV.UK Sidekiq conventions:

- Use automatic request tracing (based on&nbsp;[https://github.com/alphagov/whitehall/pull/2567](https://github.com/alphagov/whitehall/pull/2567))
- Use sidekiq-statsd (like [https://github.com/alphagov/imminence/pull/117](https://github.com/alphagov/imminence/pull/117))
- Use logging (`sidekiq-logging-json` is used very&nbsp;inconsistently)
- Perhaps setup & configuration

This will make all our apps easier to manage and upgrade.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

