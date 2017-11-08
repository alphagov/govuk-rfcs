# Dealing with errors

## Summary

This describes how we treat errors on GOV.UK

## Problem

We've recently migrated to a new error tracking service, Sentry. This provides us an opportunity to rethink how we treat errors.

## Proposal

There are 2 principles:

### 1. When something goes wrong, we should be notified

Applications should report exceptions to Sentry. Applications must not swallow errors.

### 2. Applications should not error

The goal of GOV.UK is that applications should not error. When something goes wrong it should be fixed.

## Classifying errors

### Bug

A code change makes the application crash.

Desired behaviour: error is sent to Sentry, developers are notified and fix the error. Developers mark the error in Sentry as `Resolved`. This means a recurrence of the error will alert developers again.

### Intermittent errors without user impact

Frontend applications often see timeouts when talking to the content-store or rummager.

Example: <https://sentry.io/govuk/app-finder-frontend/issues/352985400>

Desired behaviour: error is not sent to Sentry. Instead, we rely on Smokey and Icinga checks to make sure we the site functions.

### Intermittent errors with user impact

Publishing applications sometimes see timeouts when talking to publishing-api. This results in the publisher seeing an error page and possibly losing data.

Example: <https://sentry.io/govuk/app-content-tagger/issues/367277928>

Desired behaviour: TBD

### Intermittent retryable errors

Sidekiq worker sends something to the publishing-api, which times out. Sidekiq retries, the next time it works.

Desired behaviour: errors are not reported to Sentry until retries are exhausted. See [this PR for an example](https://github.com/alphagov/content-performance-manager/pull/353).

Relevant: https://github.com/getsentry/raven-ruby/pull/784

### Expected environment-based errors

MySQL errors on staging while data sync happens.

Example: <https://sentry.io/govuk/app-whitehall/issues/343619055>

Desired behaviour: our environment is set up such that these errors do not occur.

### Bad request errors

User makes a request the application can't handle ([example][bad-request]).

Often happens in [security checks](https://sentry.io/govuk/app-frontend/issues/400074979).

Example: <https://sentry.io/govuk/app-frontend/issues/400074979>

Desired behaviour: user gets feedback, error is not reported to Sentry

[bad-request]: https://sentry.io/govuk/app-service-manual-frontend/issues/400074003

### Incorrect bubbling up of errors

Rummager crashes on date parsing, returns 500, which is passed on directly in finder-frontend.

Example: <https://sentry.io/govuk/app-finder-frontend/issues/400074507>

Desired behaviour: backing app returns a 4XX status code, response is fed back to user. Nothing is ever logged or sent to Sentry.

### Manually logged errors

Something goes wrong and we need to let developers know.

Example: [Slimmer's old behaviour](https://github.com/alphagov/slimmer/pull/203/files#diff-e5615a250f587cf4e2147f6163616a1a)

Desired behaviour: developers do not use Sentry for logging. The app either raises the actual error (which causes the user to see the error) or logs the error to Kibana.

### IP spoof errors

Rails reports `ActionDispatch::RemoteIp::IpSpoofAttackError`.

Example: <https://sentry.io/govuk/app-service-manual-frontend/issues/365951370>

Desired behaviour: HTTP 400 is returned, error is not reported to Sentry.

### Database entry not found

Often a controller will do something like `Thing.find(params[:id])` and rely on Rails to show a 404 page for the `ActiveRecord::RecordNotFound` it raises ([context](https://stackoverflow.com/questions/27925282/activerecordrecordnotfound-raises-404-instead-of-500)).

Desired behaviour: errors are not reported to Sentry
