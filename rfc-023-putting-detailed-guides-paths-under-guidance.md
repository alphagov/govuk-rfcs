# Problem

Currently detailed guides live at urls like: [https://www.gov.uk/british-forces-overseas-posting-cyprus](https://www.gov.uk/british-forces-overseas-posting-cyprus)  
This can cause problems because editors are able to create documents and claim high-profile slugs which shouldn't really be used for guidance  
Instead they should be published as https://www.gov.uk/guidance/[thing]

Note that currently manuals are also published under `/guidance` so we will need to check using url arbiter or equivalent to ensure the path can be claimed.

# Proposal

1. 

Ensuring new detailed guides are served under guidance/

  1. 

in Whitehall, adding 'guidance/' in front of the detailed\_guides#show route in routes.rb. However keeping the old route live to cover deploy time (to be removed 30mn+ after deploy). It will be the same as the current route,&nbsp;without 'as:detailed\_guides'.

  2. in Whitehall, update&nbsp;the [presenter](https://github.com/alphagov/whitehall/blob/master/app/models/registerable_edition.rb#L26-L32)for sending the paths to panopticon to reflect the changes in the paths
  3. In Panopticon, we&nbsp;might also need to [update the slug validation code](https://github.com/alphagov/govuk_content_models/blob/master/app/validators/slug_validator.rb) as it may not accept detailed\_guide artefacts with a `/` in the slug  
  
2. Ensuring the existing detailed guides are served under guidance/
  1. Panopticon migration to reslug all detailed guides and avoid creating duplicates
  2. 

We need to create a rake task to republish to publishing-api.&nbsp;There is already a&nbsp;[PublishingApiRepublisher](https://github.com/alphagov/whitehall/blob/master/lib/data_hygiene/publishing_api_republisher.rb)&nbsp;class in&nbsp;lib/data\_hygiene that takes an edition scope (eg DetailedGuide.published) and republishes them - we would need to call that from the rake task.

  3. 

In Whitehall, run the [rummager::reset::detailed](https://github.com/alphagov/whitehall/blob/master/lib/tasks/rummager.rake#L44) rake task to reindex the detailed guides in search.

  4. 

In collections-publisher, run a data migration to update all api-urls for when detailed guidance is curated into topics

3. Redirecting old paths of existing detailed guides
  1. Several options:
    1. extract the URLs to a CSV and add them into router-data
    2. in Whitehall, add a "was\_previously\_under\_root" boolean attribute to the DetailedGuide model; for&nbsp;each detailed guide which has this attribute as true,&nbsp;push a redirect to the Publishing API
    3. add redirects as a model so that a detailed guide has a redirects association, and the redirects are pushed to the Publishing API when a detailed guide is published.

# To do

Arrange the above steps in such a way that nothing breaks.

