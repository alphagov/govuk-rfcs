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

Desired behaviour: error is sent to Sentry, developers are notified and fix the error.

### Expected intermittent errors

Frontend applications often see timeouts when talking to the content-store or rummager.

Desired behaviour: error is not sent to Sentry. Instead, we rely on Smokey and Icinga checks to make sure we the site functions.

### Expected environment-based errors

MySQL errors on staging while data sync happens.

Desired behaviour: our environment is set up such that these errors do not occur.

### Bad request errors

User makes a request the application can't handle ([example][bad-request]).

Often happens in [security checks](https://sentry.io/govuk/app-frontend/issues/400074979).

Desired behaviour: user gets feedback, error is not reported to Sentry

[bad-request]: https://sentry.io/govuk/app-service-manual-frontend/issues/400074003

### Incorrect bubbling up of errors

Rummager crashes on date parsing, returns 500, which is passed on directly in finder-frontend.

Desired behaviour: backing app returns a 4XX status code, response is fed back to user. Nothing is ever logged or sent to Sentry.

### Manually logged errors

Something goes wrong and we need to let developers know.

Desired behaviour: developers do not use Sentry for logging.

### Intermittent retryable errors

Sidekiq worker sends something to the publishing-api, which times out. Sidekiq retries, the next time it works.

Desired behaviour: errors are not reported to Sentry until retries are exhausted. See [this PR for an example](https://github.com/alphagov/content-performance-manager/pull/353).

### IP spoof errors

Rails reports `ActionDispatch::RemoteIp::IpSpoofAttackError`.

[Example](https://sentry.io/govuk/app-service-manual-frontend/issues/365951370)

Desired behaviour: HTTP 400 is returned, error is not reported to Sentry.
