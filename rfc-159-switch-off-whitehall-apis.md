---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# Switch off Whitehall's public APIs

## Summary

Whitehall has a number of public APIs, as listed below:

- `/api/governments`
- `/api/governments/{slug}`
- `/api/world-locations`
- `/api/world-locations/{slug}`
- `/api/world-locations/{slug}/organisations`
- `/api/worldwide-organisations/{slug}`

These APIs are not advertised publicly, except in [some documentation in Whitehall’s repository](https://docs.publishing.service.gov.uk/repos/whitehall/api.html) and in an [‘alpha’ API catalogue](https://www.api.gov.uk/gds/gov-uk-governments/#gov-uk-governments). Only one of these endpoints (`/api/world-locations`) is used internally by GOV.UK applications (via. the `gds-api-adapters` gem).

Usage is low, with the vast majority of traffic from robots. Over a 14 day period in April/May 2023, the number of hits to origin machines was as follows (after excluding those from our team whilst investigating these APIs):

- `/api/governments`: 114 hits on index page
- `/api/government/{slug}`: 0 hits
- `/api/world-locations`: 290 hits (excluding requests from other GOV.UK apps)
- `/api/world-locations/{slug}/organisations`: 0 hits
- `/api/worldwide-organisations/{slug}`: 34 hits

## Problem

Publishing Platform are aiming to switch off Whitehall Frontend (and remove all of the associated rendering code from the application) before the end of Q1 2023. The rendering of these APIs would need to be migrated into other applications, which would involve development cost. The traffic is very low, therefore the development cost would outweigh the benefit of migrating these to another application.

However users are already able to retrieve the same data through alternative means, except for one of these endpoints:

- `/api/governments` → not available (we could probably add this into a content item, if there’s a user need to maintain this without having a specific API for it)
- `/api/government/{slug}` → `/api/content/government/{slug}`
- `/api/world-locations` → `/api/content/world` (available soon, once we’ve migrated the page out of Whitehall)
- `/api/world-locations/{slug}` → `/api/content/world/{slug}`
- `/api/world-locations/{slug}/organisations` → `/api/search.json?filter_format=worldwide_organisation&fields=title,format,updated_at,link,slug,world_locations` (although this doesn’t filter by World Location, so the user will need to filter this themselves once they’ve got the results)

## Proposal

Update gds-api-adapters to not need the `/api/world-locations` endpoint of the Whitehall API and return the world locations (and their organisations) by using the relevant alternatives listed above instead. This will end our internal reliance on these APIs.

Switch off the APIs without migrating to another application in a two-step process:

1. Replace the existing APIs with a ‘gone’ response and provide content that states how users are able to access the same information (as detailed in the ‘Problem’ section above).  This will be in place for one month.
2. After one month, switch off the APIs and return a ‘gone’ response to any requests with no content.
