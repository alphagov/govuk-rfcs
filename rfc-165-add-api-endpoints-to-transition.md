# Add API endpoints to Transition for consumption by Bouncer

## Summary

This proposes that the Bouncer application should access transition data via
API endpoints on Transition instead of via direct database access.

## Problem

The [Transition
System](https://docs.publishing.service.gov.uk/manual/transition-architecture.html)
is built to transition government websites to GOV.UK. It includes:
- Transition - Ruby on Rails application used by admins to create mappings from
  old URLs to pages on GOV.UK.
- Bouncer - Rack-based application that uses the mappings created by Transition
  and handles requests to those old domains.

Currently, Bouncer retrieves the mappings written by Transition through direct
read-only access to the database shared by the two applications.

This is problematic as any code related to database access must be kept in sync
between Transition and Bouncer.
This includes the use of ActiveRecord; we must take the effort to keep
ActiveRecord subclasses and dependency versions consistent.

As this approach is unusual in the wider context of GOV.UK, this also has the
potential to make working with this system more difficult to grasp and process
for software developers. The additional cognitive load that this places on
individuals and teams may hurt productivity and make tasks such as onboarding
new developers more difficult.

## Proposal

Bouncer should retrieve data from Transition via an API. This involves:
- Adding API endpoints that allow us to retrieve the minimum amount of data for
  Bouncer to function.
- Adding adapters to GDS API Adapters.
- Removing database dependencies from Bouncer.

There has been a push recently to fully separate our frontend and backend apps.
This approach would fit in well with this theme, essentially turning Transition
into a publishing app and Bouncer into a platform concern.

This approach is an alternative to merging to the Bouncer codebase into
Transition entirely. Merging the applications is a more complex task that
involves:
- Rewriting large parts of Bouncer as it's currently not a Rails app.
- Handling of routes that are the same in Bouncer and Transition.
- Dealing with infrastructure complexity - references to Bouncer are littered 
  through the infrastructure.

The documentation in the Transition and Bouncer repositories must be updated to
reflect these changes.

## Consequences

- Bouncer's dependency on the database shared with Transition is removed.
- Bouncer's codebase will be less complex.
- This approach will likely be less performant than the current approach. We
  plan to take this into consideration during development by identifying and
  measuring relevant performance metrics.
- Bouncer depends on the availability of Transition's API.