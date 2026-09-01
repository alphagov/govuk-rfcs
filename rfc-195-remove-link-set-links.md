---
status: proposed
implementation: proposed
status_last_reviewed: 2026-09-01
---

# Remove Link Set Links from Publishing API and publishing applications

## Summary

[Publishing API](https://github.com/alphagov/publishing-api) sits at the heart of the publishing infrastructure. It allows documents to link to others, to enable related links or other similar content to be displayed alongside each other on the public website.

Each document can have multiple editions, so it is possible to have both a live edition and a draft edition (which is used to preview the document). Publishing apps send the content as a `PUT content` request, which makes the content appear on the draft site. They then make a `POST publish` request to make that content live.

All links target a Content ID (i.e. all editions and all translations of a document) but they vary in what they link from. There are two different types of link, with a different source:

- One of these is called "Edition Links", and these work like the rest of the content and are sent in the same payload, so they only go live when the publisher clicks publish. Edition Links are only associated with the locale of the edition.
- The other is called "Link Set Links". These are associated with the Content ID, not the edition, so go live as soon as a publisher adds them (not when they publish the draft). Since these are associated with a Content ID instead of a document, a Link Set Link applies to all locales of the document.

Further details of the two link types are given in [Publishing API's documentation](https://github.com/alphagov/publishing-api/blob/main/docs/link-expansion.md#link-lifecycles).

## Problem

The existence of two types of links has multiple consequences:

- It's a bad user experience: publishers think they are adding content to a draft document, but it appears live on the site immediately. This has partly been mitigated by changing the UI in the publishing apps to make this clear, but it's far from ideal.
- Some links cannot be added in publishing applications and instead have to be tagged in Content Tagger. This means users have to switch between two applications to set links.
- It makes the link expansion code in Publishing API very complicated and difficult to understand. Developers are not keen on making changes because of the complexity. This became a prominent issue when we attempted to implement a GraphQL API, as we needed to support both types of link, again, making this code very complicated.
- The difference in features between the two types of links makes onboarding difficult as the difference is hard to conceptualise, for both developers and other roles.
- Edition Links behave differently to Link Set Links, because they do not support multiple levels of links. This functionality was not needed at the time the code was originally written. This means things like the [taxonomy](https://www.gov.uk/government/publications/govuk-topic-taxonomy-principles/govuk-taxonomy-principles) cannot be represented using Edition Links, as only one level will be expanded. This caused issues when the Whitehall team wanted to do that, as they needed to find a way of working around this limitation. See [RFC-188](https://github.com/alphagov/govuk-rfcs/pull/188).

This has been recorded as [tech debt](https://gov-uk.atlassian.net/browse/PTD-164).

Link Set Links are used by the following publishing applications:

- [Collections Publisher](https://github.com/alphagov/collections-publisher)
- [Content Tagger](https://github.com/alphagov/content-tagger)
- [HMRC Manuals API](https://github.com/alphagov/hmrc-manuals-api)
- [Mainstream Publisher](https://github.com/alphagov/publisher)
- [Manuals Publisher](https://github.com/alphagov/manuals-publisher)
- [Search API](https://github.com/alphagov/search-api) (limited only to a rake task that publishes static content related to search)
- [Service Manual Publisher](https://github.com/alphagov/service-manual-publisher)
- [Specialist Publisher](https://github.com/alphagov/specialist-publisher)
- [Travel Advice Publisher](https://github.com/alphagov/travel-advice-publisher)
- [Whitehall](https://github.com/alphagov/whitehall)

## Proposal

We propose removing Link Set Links from Publishing API and migrating all publishing applications to use Edition Links.

This requires:

- completing support for multi-level Edition Links
- migrating publishing applications and content schemas to use only Edition Links
- moving the relevant Content Tagger functionality into publishing applications
- removing the remaining Link Set Link endpoints, link expansion code and database tables from Publishing API

This proposal is therefore not simply a migration of how links are stored in Publishing API. It also standardises where links are owned and managed: link creation and maintenance would solely exist in the publishing workflow, alongside content drafting. This would give publishing applications ownership of both the content and the links that form part of that content.

## Work required to support this RFC

### Support multiple levels of Edition Links

As stated above in 'Problem', Publishing API does not currently support multi-level Edition Links.

In January 2024, the Publishing Platform team attempted to solve this and partly completed some work in a [draft PR](https://github.com/alphagov/publishing-api/pull/2605). This work was discontinued at the time.

The work on adding a GraphQL API to Publishing API resulted in support for this missing functionality, so we know it is technically feasible to support multiple levels of Edition Links.

In August 2026, the earlier PR was rebased against the `main` branch. Since the previous attempt, [ADR-009](https://github.com/alphagov/publishing-api/blob/main/docs/arch/adr-009-change-linksets-primary-key-to-content-id.md) reduced the need for the SQL queries to be so complex.

At the same time, after a few other small changes, we have the basics of multi-level link expansion working in [a new PR](https://github.com/alphagov/publishing-api/pull/4153).

This demonstrates that multi-level Edition Link expansion is technically feasible.

The remaining work is to complete [dependency resolution](https://github.com/alphagov/publishing-api/blob/583173d9bbb3efbb86cb3e1526ef84667b735fd9/docs/dependency-resolution.md), locale/state handling and the associated test coverage:

- Support multiple levels of Edition Links in dependency resolution
- Return the correct locale for linked documents
- Only return documents in the correct state
- Properly test this, including against the [precedence tests](https://github.com/alphagov/publishing-api/tree/583173d9bbb3efbb86cb3e1526ef84667b735fd9/spec/integration/graphql/link_expansion) that were added during the GraphQL project

Even if we decide not to carry out the remainder of this RFC, this work should be carried out regardless, since it will have a high impact on other teams' ability to use Edition Links for tagging to the taxonomy.

### Remove Link Set Links from all publishing applications and content schemas

At the time of writing, there are 83 content schemas. This can be broken down based on existing link usage:

- No links: 5
- Edition Links only: 1
- Link Set Links only: 0
- Mixture of Edition Links and Link Set Links: 77

This analysis (including details of the exact links) has been added to [a document](https://beisgov.sharepoint.com/:x:/r/sites/GOVUK-Pub/Shared%20Documents/Content%20APIs/Workstream_%20Removing%20Link%20Set%20Links%20from%20Publishing%20API/2026-08-17%20Analysis%20of%20links%20used%20in%20schemas.xlsx?d=w505cd6cc06f54c0b9ca7d543a6861961&csf=1&web=1&e=4nPBda).

The Content APIs team will provide a migration guide to teams who own publishing applications, explaining how to migrate away from Link Set Links to Edition Links.

This will include information on the different requests to Publishing API that need to be made and how the user interface may need to be modified to support editions of the parent document.

This will include details and examples on how to:

- Modify the schema to support Edition Links.
- Change the publishing applications to send the links as Edition Links, instead of Link Set Links.
- Update the publishing application user interface to support multiple editions of a document.
- Remove the Link Set Links from Publishing API's database.
- Modify the schema to remove the Link Set Links.
- Make requests to Publishing API to obtain details of linkable documents that are published by other publishing apps.

It is not expected that the teams who own publishing applications will be able to complete this work immediately. It should be prioritised alongside other technical debt.

The Content APIs team will create a tracker to identify which content schemas have been migrated to use only Edition Links. This will update automatically, based on the content of the content schema files.

Due to the cross-team nature of this work, it is proposed that the Publishing Leads will coordinate the implementation, ensuring it is added to team backlogs, the benefits are communicated to relevant stakeholders and momentum is maintained. Once the migration of all publishing apps and content schemas is completed, the Content APIs team will lead on the changes needed in Publishing API.

### Make publishing applications the authoritative source for their documents' links

Content Tagger manages tags which are represented as Link Set Links of a limited number of link types. These are updated via the "patch links" endpoint in Publishing API. Content Tagger is not aware of editions, and does not publish the content of these documents.

The primary motivation behind Content Tagger appears to be to provide a tagging interface for document types whose publishing applications do not have this functionality.

This RFC therefore proposes Content Tagger becoming a taxonomy-management application by retiring Content Tagger's tagging functionality. The publishing applications would get native taxonomy editing (which is already the case in Whitehall). This moves the editorial workflow closer to the content being tagged.

This would create consistency across all publishing applications, by ensuring content is tagged solely in the publishing application, and remove the confusion caused by some publishing applications having their own interface.

As with the other changes needed in publishing applications, the Content APIs team will provide a migration guide to teams who own publishing applications, explaining how to migrate away from Content Tagger and Link Set Links to Edition Links in publishing applications.

#### Tagging of content that is not published from a publishing application

There are special cases (e.g. [Smart Answers](https://github.com/alphagov/smart-answers)) where content is not added using a publishing application, instead by sending the content item payload on demand using a rake task. These are then tagged using Content Tagger. This pattern means it will not be possible to provide tagging through a user interface. In these cases, the payload will need to be updated in the application's codebase ([example](https://github.com/alphagov/smart-answers/blob/6ff8907e3f6c9f2516a15b3d89121c883c12921d/app/presenters/content_item_presenter.rb#L10-L29)) to include the content IDs of the relevant tagged documents in the `links` part of the payload. This is consistent with how other changes are made to Smart Answers metadata, e.g. the title or description.

#### Bulk tagging

Content Tagger has a feature to allow content to be tagged in bulk. The history within the Content Tagger application suggests this has not been used in bulk for 4 years.

It is therefore proposed that prior to removing this feature from Content Tagger, user research should be carried out to identify whether this feature is still required.

If this feature is deemed to remain a user need, then bulk tagging will need to be built into the publishing applications, so content from that application can be tagged in bulk without requiring Content Tagger.

### Removal of the `policy_areas` links

Whilst doing the analysis to write this RFC, it was noted that `policy_areas` links exist in content schemas and in Publishing API's database, but they are not sent by any publishing application. These are present as a mixture of Edition Links and Link Set Links.

The code in Whitehall Publisher was [removed in 2020](https://github.com/alphagov/whitehall/pull/5666), but the PR comments suggest there was no decision on whether to retain these links in Publishing API's database.

This means it will not be possible to republish documents from the publishing application to migrate these from Link Set Links to Edition Links.

The only current usage of this link type across GOV.UK is [in `email-alert-api`](https://github.com/alphagov/email-alert-api/blob/132781fa5d801d00f8afe0aefe7ab02b827f9d88/lib/email_alert_criteria.rb#L74). This means users subscribed to alerts on a policy area will not be receiving updates for new documents, as it is no longer possible to tag documents to a policy area. These users will only receive updates for changes to existing documents.

There are currently 25 users subscribed to email alerts for `policy_areas` links, and there have been no matched content changes within the current retention period (one year).

It is therefore proposed that as part of this work, we would contact subscribers of policy areas to inform them this type of subscription has been deprecated. After a short grace period, we will remove all the `policy_areas` links from Publishing API's database and the associated code from Email Alert API.

This is not required to migrate publishing applications to Edition Links, but retaining `policy_areas` Link Set Links would prevent us from completely removing Link Set Links from Publishing API. We therefore propose treating this work as an essential part of the deprecation of Link Set Links.

### Remove endpoints to add Link Set Links to content in Publishing API

Once all the links are using Edition Links across all publishing applications and content types, the Content APIs team would remove the ["patch links" endpoint](https://github.com/alphagov/publishing-api/blob/7c401e34189c44ff9f4ff7bc52a6a27840135982/app/commands/v2/patch_link_set.rb) from Publishing API.

This would mean that no more Link Set Links could be added.

### Remove Link Set Links from link expansion code in Publishing API

Once the "patch links" endpoint has been removed from Publishing API, the Content APIs team would simplify the link expansion code, by removing all code to expand Link Set Links. This will result in the code being less complex and easier to understand.

Alongside this, the `link_sets` table (and associated relations) would be removed from Publishing API's database.

## Risks

### Performance could regress with multi-level Edition Links

Supporting multiple levels of Edition Links alongside nested Link Set Links could increase the amount of work Publishing API performs when resolving dependencies, particularly for deeply nested link structures.

This risk exists during migration and in the event the proposal is not completed in full.

As part of the work to support multi-level Edition Links, the Content APIs team will benchmark representative content against the current implementation and monitor Publishing API's link expansion and dependency resolution performance before and after the change.

### Changes to link expansion could change the content returned by Publishing API

Links currently follow an order of precedence, based on factors including: whether they are Edition Links, the state of the linked edition and locale. Additionally, when expanding an edition's links, there are occassionally both edition and link set links of the same link type, so we need to decide which takes precedence in case of disagreement.

There is a possibility that migrating away from Link Set Links will result in some links no longer showing or appearing in a different order, because of these factors.

This will be minimised through the usage of precedence tests. These were added to Publishing API during the GraphQL project and will be used to ensure that expanded links remain consistent during and after the migration.

### Changes to the publishing workflow

Publishers will need to tag content prior to publishing it in the publishing application, as opposed to using Content Tagger afterwards. This has a risk of causing confusion to users, where they need to provide a tag that was not previously required.

There is also a possibility the person responsible for tagging may not be the person responsible for publishing the content.

This will be mitigated through updating documentation and by gradually migrating content types.

### Migration could be blocked by teams that don't have capacity

Some publishing applications may remain on Link Set Links for a prolonged period, delaying removal of the Publishing API code.

To mitigate this delivery risk, the Content APIs team will track migration centrally and agree prioritisation with teams. Removal of Link Set Links will not be dependent on an arbitrary deadline unless all content types have been migrated.

## Consequences

Once this work is complete:

- Publishing applications will use Edition Links exclusively
- Publishing API will have no Link Set Link endpoints or expansion logic
- The `link_sets` database table (and associations) will be removed from Publishing API
- Content Tagger will no longer manage document links
- Edition Links will support the required multi-level expansion, locale and edition-state behaviour
- Long term technical debt that spans GOV.UK's Publishing architecture will be resolved

## Definition of done

This RFC will be considered complete when:

- all publishing applications use Edition Links only
- all content schemas contain no Link Set Links
- no Link Set Links remain in the Publishing API database
- no clients call the Link Set Link endpoints in Publishing API
- legacy `policy_areas` links have been removed
- link expansion and dependency resolution tests in Publishing API demonstrate this works correctly without Link Set Links existing

## Alternatives considered

### Retire Publishing API

By consolidating all publishing into a single application, there would no longer be a need for Publishing API, as the publishing application would have direct knowledge of all content and its dependencies.

Link expansion and dependency resolution could therefore take place within the publishing application itself. Link Set Links and Edition Links would no longer be required in their current form, and could instead be represented using regular Rails associations.

This is the preferred long-term direction, and work is already underway to consolidate publishing applications. However, it is not considered a viable alternative for this RFC because removing Publishing API would require a substantial migration of both code and data.

Publishing API is currently used by multiple publishing applications and provides functionality that would need to be replicated or migrated into a single application before it could be retired. This would therefore require significant changes across the publishing architecture, as well as migrating existing data. The scope and risk of this work would be considerably greater than the changes proposed by this RFC.

The proposed approach of removing Link Set Links can therefore be seen as an incremental step towards this longer-term architecture: it simplifies the current link model without requiring Publishing API, or the applications that depend on it, to be migrated or retired.

### Continue using both Link Set Links and Edition Links

We could continue to support both types of links and migrate publishing applications only where there is a specific need to use Edition Links. We could make it clear in publishing applications that Link Set Links are published immediately, rather than attempting to change the underlying link model.

This would avoid the migration work required by this RFC and would preserve the current behaviour of Content Tagger.

However, this would retain the existing complexity in Publishing API, including the need for link expansion and dependency resolution to handle two different types of links. It would also retain the confusing difference in behaviour between links added to a draft edition and links added using Link Set Links, and would not allow Link Set Links to participate in the edition workflow

This alternative would not resolve the long-standing technical debt regarding two types of links.

### Other options considered for Content Tagger

The Content APIs team carried out [an investigation](https://beisgov.sharepoint.com/:w:/r/sites/GOVUK-Pub/Shared%20Documents/Content%20APIs/Architecture/Migrating%20Content%20Tagger%20away%20from%20link%20set%20links.docx?d=w80e1fb93f1a14dc1b49d8f05b7bfdd51&csf=1&web=1&e=WHitfV) into how Content Tagger could work around the existence of only one type of link.

Two options were considered that would allow Content Tagger to exist in its current form. Neither of these options resolves the sub-optimal user experience of needing to edit tags in multiple places and not be able to assign some tags to draft documents. Both add complexity to Publishing API (either at read or write time).

Whilst the document contains full details, a summary of the two options is given below.

#### Option 1: A dedicated tags table in Publishing API

Move tags into a purpose-built table keyed on content_id (content_id, link_type, target_content_id, position), separate from the links table, but presented downstream as links so the frontend contract is unchanged.

New endpoints and adapter methods could make the tagging use case clearer:

- `PATCH /v2/tags/:content_id`
- `patch_tags(content_id, tags:, previous_version:, bulk_publishing:)`
- `GET /v2/tags/:content_id`
- `get_tags(content_id)`

These would work in a similar way to Link Set Links and remain related to the document (not an edition). This would allow Content Tagger to continue managing tags without using Link Set Links.

Publishing API would still need to resolve and merge two sources of links. This would retain complexity in link expansion and dependency resolution, and would not resolve the potential user experience problem of managing tags separately from the content being edited. It could however solve the problem of links going live immediately upon saving them in Content Tagger.

#### Option 2: Edition Links with an origin field in Publishing API

Everything becomes an Edition Link. Add an origin column (with possible values 'tagger' or 'publisher') to differentiate tagger-derived and publishing app-derived links. When creating a new edition, any tagger-originating links are copied forward to the new edition.

A new "patch Edition Links" endpoint would likely be confusing. The existing endpoint with its content ID parameter and links namespacing makes more sense, but it would need migrating to use Edition Links under the hood.

This would simplify link expansion and dependency resolution, by only having one type of link. However this solution would result in increasing the complexity of writing links to the database as both `put_content` and `patch_links` would need to be modified to copy foward Edition Links to the new edition. It would also retain the separate Content Tagger workflow and therefore would not resolve the potential user experience problem of managing tags separately from the content.

## Benefits of implementing the RFC

### Consistent publishing behaviour

All links will follow the same draft and publishing workflow as the content they relate to. This removes the distinction between links that are published immediately and links that are published when a draft edition is published.

This makes the publishing model more predictable for publishers and developers, and means that changes to a document and its links can be reviewed and published as a single unit.

### Improved user experience

Links will follow the same edition-based publishing model as the rest of the content. Changes to links will therefore be reviewed and published together with the content they relate to, in the same application, rather than having different publishing behaviour depending on the type of link.

This reduces the number of applications involved in the editorial workflow and means that publishers can manage the links associated with their content within the application that owns that content.

### Reduction in technical debt

Removing Link Set Links will resolve a long-standing technical debt item that spans Publishing API and multiple publishing applications.

Rather than continuing to maintain compatibility with two different models for representing links, the publishing platform will have a single model that can be extended as link requirements evolve.

### Reduction in code complexity

Quantifying code complexity is difficult. A rough estimate has been obtained (using Copilot AI) for the number of lines of code that could be removed from Publishing API by removing Link Set Links:

- Runtime code: ~900–1,100 lines
- Tests and factories: ~2,000–2,500 lines
- Documentation and cleanup scripts: ~300–500 lines

The likely total is roughly 3,200 to 4,000 lines, excluding historical migrations. This represents approximately 5% of the total code in Publishing API.

More importantly than the reduction in lines of code, removing Link Set Links will make the remaining implementation easier to understand and maintain.

### Reduced operational and support burden

Having a single model for links will reduce the number of different behaviours that need to be understood when diagnosing publishing issues. This will make it easier to identify and resolve problems involving links and reduce the amount of specialist knowledge required to support Publishing API.

### Easier future development

Removing Link Set Links will simplify future changes to Publishing API by removing the need to support two different link models. New functionality involving links will only need to consider Edition Links, reducing the complexity of design, implementation and testing.

This will make it easier to introduce future changes to the Publishing API, including new flexible APIs and functionality that needs to expose links.

It will also simplify changes to content schemas, as there will only be one type of link to be considered.

### Reduced developer cognitive load

Onboarding new developers to publishing will become easier, as there will be less specialist domain knowledge they need to learn.
