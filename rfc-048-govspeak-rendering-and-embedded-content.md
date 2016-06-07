## Related RFCs

- 
- 
- 

## Related Discussions

- [https://github.com/alphagov/publishing-api/pull/332](https://github.com/alphagov/publishing-api/pull/332)
- [https://github.com/alphagov/publishing-api/blob/9295bd3de3b6b5395d39784daae0f6cac4f6862b/doc/arch/embedded-content-in-govspeak.md](https://github.com/alphagov/publishing-api/blob/9295bd3de3b6b5395d39784daae0f6cac4f6862b/doc/arch/embedded-content-in-govspeak.md)

## Context

The problem was originally discussed in [RFC 39](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+39%3A+Embedded+relational+content+in+govspeak), agreeing on a [rough proposed solution](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+39%3A+Embedded+relational+content+in+govspeak?focusedCommentId=44761325#comment-44761325)&nbsp;but became dormant for ~6 months. This was partly due to dependencies on [dependency resolution](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+40%3A+Dependency+Resolution) and [supporting content items without URLs](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+43%3A+Content+items+without+a+base+path), which did not exist at the time.&nbsp;

Although this document attempts to summarise the issue, it's highly recommended that you&nbsp;[read the original RFC](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+39%3A+Embedded+relational+content+in+govspeak)&nbsp;for context, before commenting on this one.

The work was [picked up again recently](https://github.com/alphagov/publishing-api/blob/9295bd3de3b6b5395d39784daae0f6cac4f6862b/doc/arch/embedded-content-in-govspeak.md), starting from the previously agreed solution, where concerns were raised and we decided to re-evaluate the proposed solution -&nbsp;It's been a long time this the last discussion:

- Team turnover: many people involved in that discussion are no longer, and some&nbsp;who've joined since.
- Through migration we've learnt a lot about new architecture and hopefully have a better understanding of it.

## Qualities of an ideal solution

- Minimal logic in Frontend applications, with the long-term goal of static frontends
- Content store is a useful API to 3rd Parties without additional work
- Content items can be consumed/processed by search
- When an embedded dependency changes any documents containing it are automatically updated in a timely fashion
- The embed content templates and their CSS/JS stay in sync with each other

Each of the proposals describes where the responsibilities sit within the architecture, and what happens in each of the scenarios where something changes.

The scenarios are ordered from most to least frequent

- embedded dependency changed: a embeddable piece of content (eg, a contact or attachment) is updated in a publishing app by an editor.
  - This happens literally all the time, especially for things like contacts
- embedded content layout changed: the template for rendering an embeddedable piece of content (eg, contact.html.erb) is updated/deployed by a developer
  - This happens occasionally, as part of design iteration
- govspeak rendering output changes:&nbsp;the output of regular govspeak changes eg,&nbsp;[change of markup of our extensions](https://github.com/alphagov/govspeak#extensions)
  - This happens rarely - significant, and backwards-compatible changes haven't happened very often in my experience, but this may be down to it being _very hard_ in the current sytem, so we've not bothered.

## Proposals

It's assumed that the govspeak going in to publishing-api, from publishing apps, would have a standardised format for embedded content, that includes

- a unique identifier for the embedded content
- the type of embedded content

### 1. 100% Publishing: Govspeak rendering, and embedded content, is done by publishing-api&nbsp;(or shared service)

- content-store returns fully rendered HTML, including embedded content
- publishing-api responsible for converting govspeak to HTML
- publishing-api responsible for converting embedded dependencies to HTML
- publishing api responsible for tracking changes to embedded dependencies and re-generating HTML
- frontend apps receive content item with plain HTML - no dependencies in links hash

When...

- embedded dependency changed: publishing api needs to track when an embedded dependency has changed, re-render the HTML, and update content-store
- embedded content layout changed: all content items with an embedded dependency of that layout type are re-rendered and updated in content-store
- govspeak rendering output changes: all content items are re-rendered and updated in content-store

Pros

- complexity limited to publishing api
- frontend apps and publishing api are easier to reason about
- best perfomance for users - rendering is done once and cached in content store
- publishing apps don't have to send embedded dependencies in links hash

Cons

- changes to embedded dependency template will require re-rendering a lot of content (eg, all publishings)
- changes to govspeak rendering will require re-rendering all content with govspeak
- govspeak HTML can be out of sync with CSS/JS
- embedded dependency template HTML can be out of sync with&nbsp;CSS/JS

### 2. Hybrid: Govspeak rendering&nbsp;

- content-store returns partially rendered HTML, with embedded placeholders (eg, SSI-style syntax)
- publishing-api responsible for converting govspeak to HTML with embed placeholders
- publishing-api responsible for exposing embedded depencency data in links hash
- publishing api responsible for embedded dependencies links hash being up to date
- frontend receives content item HTML with embedded placeholders
- frontend parses HTML for placeholders and renders&nbsp;embedded dependency templates with data from links hash

When...

- embedded dependency changed: dependency resolution will update the content item, and frontend will automatically reflect
- embedded content layout changed:&nbsp;frontend will automatically reflect
- govspeak rendering output changes: all content items need to be re-rendered and updated in content-store

Pros

- Common updated case, embedded dependencys changing, doesn't require re-rendering
- embedded dependency templates HTML can be kept in sync with&nbsp;CSS/JS
- publishing apps don't have to send embedded dependencies in links hash (can be infered while processing govspeak to placeholders)

Cons

- Complexity is spread across publishing-api and frontend apps, harder to reason about
- Possible additional microservice dependencies for frontends to avoid duplicating embedding logic
- govspeak HTML can be out of sync with it's CSS/JS
- Makes content store a less useful API for 3rd parties (but not in an obvious way)

### 3. 100% Frontend:&nbsp;Govspeak rendering, and embedded content, is done by Frontends (or shared service)

- content-store returns raw govspeak, no HTML
- embedded dependency data is included in links hash
- frontend renders govspeak to HTML

When...

- embedded dependency changed: dependency resolution will update the content item, and frontend will automatically reflect
- embedded content layout changed:&nbsp;frontends will automatically reflect
- govspeak rendering output changes: frontends will automatically reflect

Pros

- embedded dependency template HTML kept in sync with&nbsp;CSS/JS
- govspeak HTML kept in sync with it's CSS/JS
- govspeak complexity is limited to frontend only

Cons

- Publishing apps have to explicitly include dependent content in its links hash (as publishing api is unaware of govspeak)
- Rendering of govspeak is done repeatedly - could be performance issue
- Increases complexity in frontends
- Makes content store a less useful API for 3rd parties

&nbsp;

&nbsp;

