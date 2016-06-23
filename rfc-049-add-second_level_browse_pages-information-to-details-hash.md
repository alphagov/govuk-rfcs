&nbsp;

&nbsp;

---
status: "Open"
notes: "Open for review"
---

## Background

The publishing API has two mechanisms for storing metadata about content:

- The details hash is an opaque container. It's validated against a schema and passed along to the content store to be used by frontend apps.
- The links hash relates a content item to other content items. It contains sets of content ids grouped by "link\_type". The publishing platform expands these links, adding in titles, base\_paths etc. for each of the target content ids.

In &nbsp;we made the decision to not preserve ordering for sets of links in the publishing API.

The consensus was that:

- the ordering of links within a page is a presentational concern
- the links data should be easy to update outside of the owning publishing app (i.e. content tagger) without needing to specify how the frontend will present it

Further background on what we are aiming for can be found in&nbsp;

In this RFC when I talk about tagging, I mean any activity that creates a link between a content item and some kind of "linkable" content item, i.e. mainstream browse page, topic page, organisation etc.

This doesn't have to take place within the normal workflow for changing content - for certain link types and formats, we can change the tags in content tagger without creating a new draft of the content item.

The links functionality in publishing api is also used to describe how linkables relate to each other. i.e. structuring taxonomies. This is a different activity, involving different users, and different apps (collections-publisher). This is the main activity I want to talk about in this RFC.

Collections-publisher is also used to curate content, i.e. pick out content to display within a mainstream browse section, instead of an A-Z of all content tagged to the browse page. Again, there is a restricted number of users with permission to do this, mostly inside GDS.

## Problem

When we implemented RFC 36, we removed all ordering information about links from the publishing api. Since then, we've since noticed two places on GOV.UK that used to rely on the ordering of links:

1. Some organisations get emphasised (come first) on whitehall content pages, eg a policy page
2. On mainstream browse pages, you have the option to change the ordering of second-level browse pages: eg&nbsp;[https://collections-publisher.integration.publishing.service.gov.uk/mainstream-browse-pages/451c8029-6fe3-41cf-80e8-717debd317bd/manage-child-ordering](https://collections-publisher.integration.publishing.service.gov.uk/mainstream-browse-pages/451c8029-6fe3-41cf-80e8-717debd317bd/manage-child-ordering)&nbsp;- this functionality is now broken.

We can foresee similar needs arising as we continue to develop the alpha taxonomy for education and prototype new navigation structures.

The first example has been dealt with by placing an additional field in the details hash, following the suggestion by Chris in RFC 37.

This means that there are two fields: organisations (links hash, expandable) and emphasised\_organisations (details hash, not expanded). The frontend needs to use both of these fields to render the results, but apps that only do tagging do not need to set emphasised\_organisations.

A consequence of this is that if a user updates the tags of a document outside of the content publishing workflow, the organisation will not be emphasised. They would have to create a new draft and go through the regular 2i process to do that.&nbsp;

In this RFC I would like to reach a consensus on whether this is a workable solution for the second case: **what should we store when a user fills out the "manage child ordering" page for a browse page in collections publisher?**

## Current taxonomy for browse pages

This is my current understanding of the how the mainstream browse page taxonomy works. Please correct me if anything is wrong, I'm very likely to be wrong.

- 

Each browse page has **top\_level\_browse\_pages** links, this is always the full set of top level browse pages, and each browse page content item has the same set:&nbsp;

- Each top level browse page has **second\_level\_browse\_pages** links: this points to all child browse pages, and is the inverse of "active\_top\_level"
- Each second level browse page has **second\_level\_browse\_pages** links as well, in this case the links point to all its siblings
- Each second level browse page has an **active\_top\_level** link pointing to the top level it belongs to. This is similar to how we implement breadcrumb tagging.
- second\_level\_browse\_pages is supposed to be sorted alphabetically by default, but can also be ordered manually. This ordering is what we've lost.
- Content can be tagged to a browse page using the mainstream\_browse\_pages link.
- A mainstream browse page can be curated using the groups field in the details hash of the browse page content item.

Live example:&nbsp;[https://www.gov.uk/browse/childcare-parenting/childcare](https://www.gov.uk/browse/childcare-parenting/childcare)

The second level is ordered alphabetically rather than following the curated order.

## Possible solutions

### Option 1: follow the same approach as emphasised\_organisations

- Keep second\_level\_browse\_pages unchanged in the links hash
- second\_level\_browse\_pages links get expanded by existing links expansion code, to get titles, urls etc
- Add a details field, eg second\_level\_browse\_page\_ordering, that contains the same content ids but ordering is preserved
- Frontend uses the details information in its rendering of the expanded links (if available)

#### Advantages

- It's easy and works

#### Disadvantages

- top\_level\_browse\_pages and second\_level\_browse\_pages links contain redundant information that is only relevant to presentation, which is what we wanted to avoid in the links hash
- In this case, collections-publisher is the only publishing app we need to worry about, so its easy to keep two fields in sync. But this may not be true in general - if a link is used for tagging, as in the organisations case, then there are multiple workflows/apps that change it. Either both apps know about both fields, or the fields can become inconsistent (eg when you untag an organisation).
- Why does collections publisher need to determine sibling and child information up front, when the publishing api can work it out from active\_top\_level links?

### Option 2: move fields from links hash to details hash, without keeping the links

- Move second\_level\_browse\_pages (and optionally top\_level\_browse\_pages) to the details hash
- Provide some mechanism for publishing API to expand details fields in a similar manner to links
- Reparenting browse pages becomes a tagging operation on the child: there is no need for any new content items to be created
- Setting a non alphabetical order on the child browse pages remains a content operation on the parent - it creates a new version

#### Advantages

- Less redundancy, less risk of data becoming inconsistent
- Presentational information is kept out of the links hash&nbsp;

#### Disadvantages

- Changes how the publishing api works
- There is still a separation between ordering information and structural information, and the two could still become inconsistent
- We spend more time on taxonomies that we want to eventually replace

### Option 3: add ordering back into the links hash

- Basically reverse RFC 36. See that RFC for arguments against.

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

