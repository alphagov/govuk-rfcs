# External routes

## Summary

Create an `external_route` document type to represent pages that aren't part
of GOV.UK but are relavent to our users.

## Problem

Not everything government related is on GOV.UK.

Search admin stores "External links", which can be returned for certain search terms.

For example:
- searches for "mp" can return the parliament.uk page http://www.parliament.uk/mps-lords-and-offices/mps/
- searches for "fit for work" can return http://fitforwork.org/
- searches for council names can return the council website

We are currently changing search indexing to source all its content from the publishing API, but external links
have never been part of the publishing API.

## Proposal

Create an `external_route` document type so we can store these links in the publishing API.

Create an `external_route` schema.

The schema MUST store in the details hash:
- `hidden_search_terms` - a set of search keywords/phrases that should route users to the page. [This field has already been added for smart answers](https://github.com/alphagov/govuk-content-schemas/pull/685/files).
-  `url` - a URL for the external resource
- `comment` - an internal description of why the link is relevant to GOV.UK users

The schema MAY store information about change history.

The standard fields `title` and `description` MUST be set.
The `base_path` MUST NOT be set.

## Consequences

- External resources can be defined centrally and reused across the platform
- The standard `links` hash can be used to refer to external resources. The platform does not make any distinction between internal and external resources.

This means that `external_related_links` in the details hash is technically redundant, and external links could be managed independently of the publishing workflow (for example, through content tagger).

This RFC acknowledges but does not address this duplication. The intention is only to move the search admin concept of an external link into the publishing API.
