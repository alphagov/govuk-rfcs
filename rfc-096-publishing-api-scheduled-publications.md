# Scheduled publication functionality in Publishing API

## Summary

Add scheduled publication functionality to the Publishing API.

## Problem

We have certain scheduled publication formats that we must represent live on GOV.UK within a minute of the scheduled publication time (such as statistical publications).

Scheduled publications are not currently a feature supported by the Publishing API. This means each publishing application that wishes to implement scheduled publishing must do so independently. This leads to duplicate functionality being developed in each publishing application that required the functionality. At the same time, although conceptually each application would develop similar functionality, the code surrounding scheduled publications might vary between applications.

This has several drawbacks:

  * Developers must become familiar with multiple implementations that solve the same problem.
  * Duplicate functionality across multiple applications violates a Don't Repeat Yourself philosophy.
  * Debugging problems with scheduled publications across multiple micro service layers is difficult.
  * There are multiple places where content may get "stuck" and debugging requires knowledge of individual publishing apps.

Whitehall is one of the publishing applications that implements scheduled publishing. In Whitehall's case, the code that interacts with the Publishing API is often difficult to reason about and hard to debug.

## Proposal

Create scheduled publishing functionality in the Publishing API.

- Publishing API MUST provide the ability for publishing apps to schedule a publish of draft content.
- Publishing API MAY provide a `/v2/content/:content_id/schedule` endpoint.
- Publishing API MAY introduce a 'scheduled at' date field to editions.
- Publishing API MAY implement callbacks or push on to message queue.
- Publishing API MAY implement an endpoint to poll for an item's state (e.g. when in Whitehall admin, as you hit an edition, it polls the Publishing API to check whether it's been published).
- Publishing API MUST implement a queue of scheduled content (probably use Sidekiq `perform_at` ? as in Whitehall).
- Publishing API MUST provide the ability to cancel a scheduled publish.
- Publishing API SHOULD store scheduled requests in the actions log (e.g. `Schedule` and `CancelSchedule`).
- Publishing API SHOULD allow subsequent requests to overwrite existing scheduled publish requests.
- Publishing API MUST cancel any scheduled publish requests if the draft edition is discarded.
- Publishing API MUST cancel any scheduled publish requests if the draft edition is published directly.
- Whitehall MUST be migrated to use the new Publishing API functionality.
- Publisher MUST be migrated to use the new Publishing API functionality.
- Specialist Publisher MAY get scheduled publishing functionality added using the Publishing API.

Whitehall currently doesn't store the full state history of content that has been published automatically after being scheduled. We also think it won't be necessary to store this in the Publishing API. A piece of content that has a draft edition can be scheduled for publish, and that same edition may continue to be updated up until it gets published. Whether or not an edition has a scheduled publish request attached to it, doesn't affect the state of the edition until it gets published.

With data in the Publishing API, we might be able to improve the [Scheduled Publishing dashboard][dashboard] to include visibility on the queues, the number of items scheduled for publishing and when the content is going to be published.

[dashboard]: https://grafana.publishing.service.gov.uk/dashboard/file/scheduled_publishing.json?orgId=1
