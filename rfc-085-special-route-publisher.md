# Special Route Publisher app

## Summary

This RFC proposes the creation of a Special Route Publisher app to cater for routes that require registration but have no content.

## Problem

There are examples of certain routes that have no direct content and therefore do not live in any particular publishing but still require a route to be registered via the the Publishing-Api -> Content Store. Examples of these can be seen in [Frontend](https://github.com/alphagov/frontend/blob/master/lib/special_route_publisher.rb) and [Rummager](https://github.com/alphagov/rummager/blob/master/lib/tasks/publishing_api.rake) where the former publishes many routes, such as site search, and the latter the site map. Each app then has a rake task which is triggered on deploy and updates the routes via the Publishing API.

This creates some inconsistencies/issues:

1. Frontend apps should ideally not talk directly to the Publishing API.
   This has become more relevant recently whilst moving site search into Finder Frontend.

2. No central location for the administration of special routes.

3. No consensus as to which app should take responsibility for
   publishing any future special routes.

4. Each app that publishes these routes does so in slightly different ways.

## Proposal

Create a Special Route Publisher app to handle the administration of any
special routes that have no direct pieces of content and therefore
cannot obviously live in any other publishing app.

The app could be used to publish other types of content items in the
future, but this is out of scope for now. For example, external links
are not currently sent to the Publishing API but are sent to search.
Tracking them as content items would allow them to be used elsewhere.
