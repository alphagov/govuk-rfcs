---
status: accepted
implementation: done
status_last_reviewed: 2024-03-06
---

# Putting Detailed Guide paths under /guidance

## Problem

Currently detailed guides live at urls like: [https://www.gov.uk/british-forces-overseas-posting-cyprus](https://www.gov.uk/british-forces-overseas-posting-cyprus)  
This can cause problems because editors are able to create documents and claim high-profile slugs which shouldn't really be used for guidance  
Instead they should be published as https://www.gov.uk/guidance/[thing]

Note that currently manuals are also published under `/guidance` so we will need to check using url arbiter or equivalent to ensure the path can be claimed.

## Proposal

### Ensuring new detailed guides are served under guidance/

in Whitehall, adding 'guidance/' in front of the detailed\_guides#show route in routes.rb. However keeping the old route live to cover deploy time (to be removed 30mn+ after deploy). It will be the same as the current route,&nbsp;without 'as:detailed\_guides'.

in Whitehall, update&nbsp;the [presenter](https://github.com/alphagov/whitehall/blob/master/app/models/registerable_edition.rb#L26-L32)for sending the paths to panopticon to reflect the changes in the paths

In Panopticon, we&nbsp;might also need to [update the slug validation code](https://github.com/alphagov/govuk_content_models/blob/master/app/validators/slug_validator.rb) as it may not accept detailed\_guide artefacts with a `/` in the slug  

NB: in the routes, /specialist/detailed-guide-slug redirects to root/detailed-guide-slug, so as another story we should make it redirect to /guidance/detailed-guide-slug directly.  
NB: also, in govuk\_content\_models, we will need to disallow URLs at the root once the migration of old guides is complete  
  
### Ensuring the existing detailed guides are served under guidance/

Panopticon migration to reslug all detailed guides and avoid creating duplicates

We need to create a rake task to republish to publishing-api.&nbsp;There is already a&nbsp;[PublishingApiRepublisher](https://github.com/alphagov/whitehall/blob/master/lib/data_hygiene/publishing_api_republisher.rb)&nbsp;class in&nbsp;lib/data\_hygiene that takes an edition scope (eg DetailedGuide.published) and republishes them - we would need to call that from the rake task.

In Whitehall, run the [rummager::reset::detailed](https://github.com/alphagov/whitehall/blob/master/lib/tasks/rummager.rake#L44) rake task to reindex the detailed guides in search.

In collections-publisher, run a data migration to update all api-urls for when detailed guidance is curated into topics

### Redirecting old paths of existing detailed guides

Several options:

- extract the URLs to a CSV and add them into router-data
- in Whitehall, add a "was\_previously\_under\_root" boolean attribute to the DetailedGuide model; for&nbsp;each detailed guide which has this attribute as true,&nbsp;push a redirect to the Publishing API
- add redirects as a model so that a detailed guide has a redirects association, and the redirects are pushed to the Publishing API when a detailed guide is published.

## To do

Arrange the above steps in such a way that nothing breaks.
