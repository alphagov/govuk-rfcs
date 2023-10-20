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

## Proposal

We should add API endpoints to Transition that will enable us to retrieve the
data required for Bouncer to function.

This approach is an alternative to merging to the Bouncer codebase into
Transition entirely. Merging the applications is a more complex task that
involves:
- Rewriting large parts of Bouncer as it's currently not a Rails app.
- Handling of routes that are the same in Bouncer and Transition.
- Dealing with infrastructure complexity - references to Bouncer are littered 
  through the infrastructure.

The documentation in the Transition and Bouncer repositories must be updated to
reflect these changes.