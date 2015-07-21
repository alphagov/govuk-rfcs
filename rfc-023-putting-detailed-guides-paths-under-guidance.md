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
  1. 

Republish - run [rake task](https://github.com/alphagov/whitehall/blob/master/lib/tasks/panopticon.rake#L24)&nbsp;to republish the content items of existing detailed guides. Because of 1.b, we expect this republish to add another slug under the new url guidance/existing-detailed-guide-slug, and the publishing-api to get the updated slug through the republish and 1.a.

3. Redirecting old paths of existing detailed guides
  1. In Whitehall, create and run a script that will create a [redirect item](https://github.com/alphagov/content-store/blob/master/doc/redirect_item.md) for each existing detailed-guide (from /slug to guidance/slug). We hope that this will inform the router about the new route.

&nbsp;

