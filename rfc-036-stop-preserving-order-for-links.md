## Problem

A links hash in a content item looks like this:

`"links": {`  
`  "lead_organisation": ['ORG-CONTENT-ID'],`  
`  "organisations": ['ORG-CONTENT-ID', 'ANOTHER-ORG-CONTENT-ID'],`  
`  "topics": ['TOPIC-CONTENT-ID'],`  
`  "available_translations": [... automatically generated ...]`  
`}`

The array of links is currently guaranteed to preserve its order when sent to the publishing-api. From the content-store documentation:

> The list\_of\_links is an array of content items, order is preserved.
> 
> [https://github.com/alphagov/content-store/blob/4b4a82a279de11a2af27b05dfc61d5f18a250c75/doc/content\_item\_fields.md#links](https://github.com/alphagov/content-store/blob/4b4a82a279de11a2af27b05dfc61d5f18a250c75/doc/content_item_fields.md#links)

The order preserving complicates the following things:

1. **Complicates tagging tools**. We are building a generic tagging tool that defines the relationships between content items. It shouldn't be concerned with how these relationships are presented on the site.
2. **Complicates implementation.** &nbsp;The publishing-api currently saves the links array and forwards it without manipulating it. To build a more flexible system, the links are being extracted into it's own table ([https://trello.com/c/zppxFP6p](https://trello.com/c/zppxFP6p)). We'll lose the "free" preservation with that change and will have to add code specifically to preserve the ordering.
3. In most cases, the ordering of the links should be a **presentation concern** anyway. For example, the [collections-publisher app sorts the related topics by title](https://github.com/alphagov/collections-publisher/blob/37830fd561b9cd8c212a9c63b126ed93bb655dc1/app/presenters/mainstream_browse_page_presenter.rb#L15) before sending the links to the publishing-api, which effectively reserves the `related_topics` for this use. Contrived example: if we were to use the related\_topics on a prototype sorted chronologically, it would need to "override" the ordering specified in collections-publisher. It would be confusing that sometimes the ordering is defined on the frontend, and sometimes by the publisher.
4. It's **easily abused to add meaning**. We use the first item in the `sections` tag in govuk\_content\_models for the breadcrumb ([code](https://github.com/alphagov/govuk_content_models/blob/master/app/traits/taggable.rb#L29-L48)). This means we can't easily query "pages that have x as their breadcrumb".  
5. It may make&nbsp; **bulk tagging** &nbsp;more difficult. (we don't have a specific plan for that, but I can imagine a case where a bulk-action of "remove mainstream browse page tag x from these content items" would change the breadcrumb for some items, but not others)  
  

## Proposal

- We stop guaranteeing the order of the links.
- During the tagging migration we get rid of the usage of the first item as breadcrumb. &nbsp;

## Impact

- Add a&nbsp;`breadcrumb` tag-type and populate it&nbsp;[during the tagging migration](https://github.com/alphagov/panopticon/blob/8d0c3bf8fe013ad06a61a6adb4f773ee6b3e60f5/lib/tagging_migrator.rb#L31).&nbsp;Make sure this tag is merged back into the section tags ([in the TagUpdater](https://github.com/alphagov/panopticon/blob/893857e2eb7c1f21e7382f761dde806fdd2cd8b0/app/queue_consumers/tagging_updater.rb#L46)) to keep current breadcrumbs intact.
- Audit pages using links to make sure nothing is using it.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

