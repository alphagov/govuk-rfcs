&nbsp;

&nbsp;

---
status: "IN DRAFT"
notes: "Closing for comments on 27 June 2016"
---

## Background

In , we made the decision to not preserve ordering for sets of links in the publishing API.

The consensus was that:

- the ordering of links should be a presentational concern
- the links data should be easy to update outside of the owning publishing app (i.e. content tagger) without worrying about this stuff

Further background on what we are aiming for can be found in&nbsp;

Each different kind of activity has different users and different workflows, so we should be careful not to conflate them:

- Managing content with the standard 2i process
- Tagging content to linkables
- Structuring taxonomies (building graph structures out of linkables)
- Curation of content, changing how stuff is presented in particular interfaces

## Problem

Since the previous RFC, we've since noticed two places that depend on ordering:

1. Some organisations get emphasised (come first) on whitehall content pages, eg a policy page
2. On mainstream browse pages, you have the option to change the ordering of second-level browse pages: eg&nbsp;[https://collections-publisher.integration.publishing.service.gov.uk/mainstream-browse-pages/451c8029-6fe3-41cf-80e8-717debd317bd/manage-child-ordering](https://collections-publisher.integration.publishing.service.gov.uk/mainstream-browse-pages/451c8029-6fe3-41cf-80e8-717debd317bd/manage-child-ordering)&nbsp;- this functionality was broken by the previous RFC.

We can foresee similar needs arising as we continue to develop the alpha taxonomy for education and prototype new navigation structures.

The first example has been dealt with by placing an additional field in the details hash, following the suggestion by Chris in RFC 37.

This means that there are two fields: organisations (links hash, expandable) and emphasised\_organisations (details hash, not expanded). The frontend needs to use both of these fields to render the results, but apps that do tagging do not need to set emphasised\_organisations.

A side effect of this is that if a user updates the tags of a document outside of the content publishing workflow, the organisation will not be emphasised. They would have to create a new draft and go through the regular 2i process to do that.&nbsp;

In this RFC I would like to reach a consensus on whether this is a workable solution for the second case: **what should we store when a user fills out the "manage child ordering" page for a browse page?**

## Current taxonomy for browse pages

This is my current understanding of the how the mainstream browse page taxonomy works. Please correct me if anything is wrong, I'm very likely to be wrong.

- 

Each browse page has top\_level\_browse\_pages links, this is always the full set of top level browse pages, and each browse page content item has the same set:&nbsp;

- Each top level browse page has **second\_level\_browse\_pages** links: this points to all child browse pages, and is the inverse of "active\_top\_level"
- Each second level browse page has second\_level\_browse\_pages links as well, in this case the links point to all its siblings
- Each second level browse page has an **active\_top\_level** link pointing to the top level it belongs to (similar to breadcrumb links)
- second\_level\_browse\_pages is supposed to be alphabetical by default, but can be curated. This ordering is what we've lost.
- Content can be linked to a browse page via the mainstream\_browse\_pages link (not really relevant to this RFC)
- The groups field in the details hash of a browse page allows us to curate the linked content (also not relevant)

&nbsp;

&nbsp;All this data feeds the mainstream navigation visible here:&nbsp;[https://www.gov.uk/browse/childcare-parenting/childcare](https://www.gov.uk/browse/childcare-parenting/childcare)

Notice that the second level is ordered alphabetically rather than following the curated order.

## Possible solutions

### Option 1: follow the same approach as emphasised\_organisations

- Keep second\_level\_browse\_pages as is in the links hash
- second\_level\_browse\_pages links get expanded by existing links expansion code, to get titles, urls etc
- Add a details field, eg second\_level\_browse\_page\_ordering, that contains the same content ids but ordering is preserved
- Frontend uses the details information in its rendering of the expanded links (if available)

#### Advantages

- It's easy and works
- We can tag things without worrying about presentational concerns

#### Disadvantages

- top\_level\_browse\_pages and second\_level\_browse\_pages links contain redundant information that is only relevant to presentation. Why should publishing apps have to deal with them?
- How do we keep these two related fields in sync if not all apps use both? If a user removes a link, following a separate tagging workflow, how do we ensure it gets removed from the supplemental details field?
- Why do publishing apps need to send sibling and child information, when the publishing app can work it out from active\_top\_level links?

### Option 2: move fields from links hash to details hash, without keeping the links

- Move second\_level\_browse\_pages (and optionally top\_level\_browse\_pages) to the details hash
- Provide some mechanism for publishing API to expand details fields in a similar manner to links
- Reparenting browse pages could be a purely tagging operation on the child. e.g. we could do it in content tagger
- Setting a non alphabetical order on the child browse pages remains a content operation on the parent - it creates a new version

#### Advantages

- Less redundancy, less risk of data becoming inconsistent
- Presentational information is kept out of the links hash, resulting in a simpler data model for links (just a single "belongs to" link, like we have for other linkables)&nbsp;

#### Disadvantages

- Changes how the publishing api works
- There is still a separation between ordering information and structural information, and the two could still become inconsistent

### Option 3: add ordering back into the links hash

- Basically reverse RFC 37. See that RFC for arguments against.

### Option 4: something else

???

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

