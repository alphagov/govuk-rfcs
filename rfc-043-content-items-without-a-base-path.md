## Problem

There's a need for "unadressable content" on GOV.UK. These are content items without a URL (base path) that won't be visible on GOV.UK. They would be used in the links hash and for dependency resolution.

The need for having these first surfaced when talking about modelling governments in the publishing-api. Having content-items of document type "government" in the publishing-api would allow us to use the links hash to specify to which government a piece of content belongs. With dependency resolution we can then put everything related to one government in history mode.

Other use cases for this are:

- **The tags for the new single taxonomy**. Linking to things without a base path means we don't need a page for each "tag", but we can have a more flexible architecture where we display multiple tags on one page.
- **Adding external links to the search index**. These currently live in [recommended links repo](https://github.com/alphagov/recommended-links) and are put directly into rummager. In the future we'll populate the search index from the message queue exclusively. This means that everything that should be in search also needs to be in the publishing-api.
- **Councils** &nbsp;may be added as part of the work the Custom team is doing to [rebuild local transactions](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+33+Local+transactions+migration+approach).

There has been some work done on this:&nbsp;[https://trello.com/c/b77KFGgc/523-add-support-for-nil-base-paths-in-publishing-api](https://trello.com/c/b77KFGgc/523-add-support-for-nil-base-paths-in-publishing-api).&nbsp;

This RFC is intended to give us the opportunity to really think this through, as this is a important architectural feature.

## Proposed requirements

1. Publishing API&nbsp;should support these content items without knowing about the formats. Instead, whether or not the format is adressable or not should be set in the content-schemas.
2. The content item needs testable with [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas) (the current build process assumes that all schemas will have a required `base_path`)
3. Publishing API validates that the items don't have a `base_path`, `rendering_app`, `redirects` and `routes` when writing
4. Publishing API&nbsp;doesn't include `base_path`, `rendering_app`, `redirects` and `routes` in the GET responses and message queue payload  
  

Open questions

- Do we add a explicit attribute on the presented content item that it's addressable/non-addressable?
- Can all message queue consumers cope with non-addressable content?
- Are there any other places where we assume that content items have a base path?

&nbsp;

&nbsp;

&nbsp;

