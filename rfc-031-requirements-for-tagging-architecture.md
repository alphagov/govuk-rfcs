# Problem

In , we tried designing an architecture for the publishing platform's tagging (or "linking") support, but kept finding new requirements we'd not anticipated which would be hard to implement with the suggested architectures. Instead, this RFC attempts list all the requirements we currently know about for tagging, so that we can try again to define a suitable architecture. It should also serve as a snapshot of what we currently understand the requirements to be.

I've structured the document as first a list of APIs we need to support, followed by a list of all the types of&nbsp;apps which will interact with the information in the "publishing platform", which APIs they need, and why. &nbsp;We're assuming that the "links" feature will be used for representing all tags (see discussion in RFC 24).

# APIs

(Methods and URIs here are "illustrative"; probably not exactly the ones we'd use - I'm just trying to illustrate the information and effects that are needed)

| Name | Illustrative URIs | Description | Needed by |
| ---- | ----------------- | ----------- | --------- |
| **publisher-put-content-only** | `PUT http://publishing-api/content-only/<content-id>` with a JSON body containing a content item. | Send a content item to the publishing platform, but without sending the "links" for the content item. &nbsp;Link information for the content item would not be affected. This is essentially the current `PUT /content/<content-item>` endpoint, without the links. | - Publishers - Collections-publisher |
| **publisher-patch-links** | `PATCH http://publishing-api/links/<content-id>` with a JSON body containing the items in the links hash which are to be updated | Send updates for some of the "links" for a content-item, without overwriting others, and without needing to resend the rest of the content item. | - Publishers - Tagging editor |
| **publisher-bulk-get** | `GET http://publishing-api/bulk?format=<format>&fields=<fields>` | Example: `GET http://publishing-api/bulk?format=topic&fields=title,content_id,base_path,draft,links.parent.title` Get information about all content items of a particular format, **including draft items**. Only a limited set of fields need to be returned, but these may include: - fields from the top-level of the content item - whether the item is in draft state or not - fields from within the details hash - fields from within the expanded links hash. The endpoint may also need to support pagination / filtering for efficiency. | - Publishers - Tagging editor |
| **publisher-get-links** | `GET http://publishing-api/links/<content-id>` | Get the current value of the "links" hash for a content item, as the list of content-ids, including any content-ids for draft or unknown items | - Publishers - Tagging editor |
| **publisher-get-linked** | `GET http://publishing-api/linked/<type>/<content-id>?fields=<fields>` | Get a list of the content which has a link of the given type to the given content-id. This is the reverse lookup from the "get-links" lookup - find the things which link to a piece of content. \<fields\> would be interpreted the same way as for the bulk get endpoint. (These might even be implemented as the same endpoint) | - Collections-publisher |
| **frontend-get** | `GET http://frontend-api/content/<base_path>` | Get a content item, with details of many of the fields in linked items expanded. Ideally, we want this call to take no options, allowing us to pre-calculate all these responses. Only returns information on pages which are live (eg, links to draft content wouldn't be included in responses). It would be useful for the content-id to be included in the response (and for the content-id of items in expanded links fields to be included, too). | - Frontend applications |
| **frontend-draft-get** | `GET http://draft-frontend-api/content/<base_path>` | Same as **frontend-get**, but would return information on pages in draft state. | - Frontend applications in content-preview |
| **frontend-feed** | probably not pure HTTP - but could be websocket based, or raw AMQP / kafka, etc. | Get a push notification when the frontend representation of any piece of content changes. The feed would contain sufficient information that the **frontend-get** API could be implemented using a key-value store which is populated directly from this feed. Note that the frontend representation includes expanded linked items, so if, say, the title of a **page A** changes, all other content-items **B** which include a reference to **A** anywhere in their links hash also need to be updated. The frontend feed should indicate the type of the update, including whether the original update was a "major" update to content, or a change in the tagging, or a change to one of the fields in a tagged document. | - Search indexing - Email alerting |
| **frontend-draft-feed** | see frontend-feed | Same as frontend-feed, but would include information on pages and linked pages in draft state. | - Search indexing in content preview |

# Application types

## Publishing applications

Examples:

- [https://github.com/alphagov/publisher](https://github.com/alphagov/publisher)
- [https://github.com/alphagov/whitehall](https://github.com/alphagov/whitehall)
- [https://github.com/alphagov/specialist-publisher](https://github.com/alphagov/specialist-publisher)
- [https://github.com/alphagov/hmrc-manuals-api](https://github.com/alphagov/hmrc-manuals-api)

These need the following APIs:

- **publisher-put-content-only** : needs to be able to send content without changing links (to avoid having to fetch the links first, for efficiency and avoidance of race conditions when links are being edited elsewhere)
- **publisher-patch-links** : able to send links without changing content, and able to update some links without overwriting others. &nbsp;eg, send a new set of "topic"&nbsp;taggings, but leave any "organisation" taggings untouched. &nbsp;Means that if only topic tags are changed, the app doesn't need to worry about fetching the data for populating any other links fields.
- **publisher-bulk-get** : get a list of all content items of a particular format, including draft items, to populate select boxes on forms. &nbsp;(ie, "get a list of all the topics"). &nbsp;Only needs some of the fields to be returned. &nbsp;eg, for topics, the fields needed would be:
  - title (shown to editors)
  - content-id (used to store the link)
  - base\_path (to enable a link to be made to show a preview of the topic contents)
  - information on whether the item was in draft state (this is displayed to editors)  
  - the title field for the parent in the links hash (needed because topic titles need to be displayed in the context of their parent - we could work around this some other way, perhaps by storing more information in the details hash, but this will require collections-publisher to do more work to maintain this)
- **publisher-get-links** :&nbsp;needed to pre-select the appropriate items in the tagging forms.

Status:

- These apps already exist.
- They mostly store the taggings of pieces of content in their own databases currently. &nbsp;Some store the taggings in panopticon. &nbsp;Moving all these taggings out of their databases and into a central store is a priority for the Finding Things team, to allow more flexible tagging.
- Currently, the content item needs to be sent together with the links.
- Currently, there is no API for getting the links out in content-id form
- Currently, there is API for fetching a list of all content items of a given format.

## Collections publisher

[https://github.com/alphagov/collections-publisher](https://github.com/alphagov/collections-publisher)

This needs the following APIs:

- **publisher-put-content-only** :&nbsp;send content items for each topic tag to the content store (also, mainstream browse tags, but these are very similarly modelled)
- **publisher-get-linked** :&nbsp;get a list of all content tagged to a given topic tag (including draft content), to allow manual curation. &nbsp;Required fields are:
  - content-id
  - title
  - base\_path
  - draft status
- **publisher-patch-links** : send links to the content store; eg, to represent links from mainstream browse pages to topic pages

Status:

- app already exists
- Is currently using rummager to get the lists of the content tagged to a topic tag, but the lag and differences between this and the "publisher" view of the content causes problems. &nbsp;In particular, draft content can't be curated into lists, and content-ids aren't known so we can't represent curated lists by content-id

## Tagging editor / bulk tagger

This needs the following APIs:

- **publisher-bulk-get** : get a list of all the possible topics, etc, that can be linked to, for populating select boxes.
- **publisher-get-links** :&nbsp;get a list of the links currently existing for a given content item.
- **publisher-patch-links** : update the links for a given content item.

Status:

- This does not exist yet. &nbsp;It is needed for the process of tagging all existing content on the site to topics, but the form it will take is not yet defined. &nbsp;It could even be a set of scripts without a user interface.

## Frontend applications

Examples:

- [https://github.com/alphagov/frontend](https://github.com/alphagov/frontend)
- [https://github.com/alphagov/smart-answers](https://github.com/alphagov/smart-answers)

These need the following APIs:

- **frontend-get** : get the content item, with links fields expanded.

Things that would be useful here:

- deep expansion - see examples in the discussion of that feature (at the end of this document).

## Search indexing

This needs the following APIs:

- **frontend-feed** : get a list of all content, in the frontend form.

The indexer needs the "links" fields to be in their expanded form, so that it is possible to index things like the slugs of organisations and topics, rather than their content-ids. &nbsp;It would also be desirable to index the actual titles of things like organisations / topics, to avoid the current approach used in rummager of keeping an in-memory cache of organisation slug -\> display name mappings.

Having content-ids available in the feed would be useful to use as unique identifiers (but not essential).

Having content-ids available would be essential if publishing tools want to be able to use the same search index as frontend, to locate pages to edit (or to find tags to suggest adding to a page, etc).

## Email alerting

This needs the following APIs:

- **frontend-feed** : get a list of all content modified, with details of the type of the change (eg, major/minor/republish).

Status:

- The current implementation of email-alert-monitor listens to a feed but ignores the "links" field - it uses information in the details hash to determine whether content is tagged appropriately. &nbsp;This breaks if slugs of topics change.

Things that would be useful here:

- If topics were represented in the links hash, the email-alert-monitor would probably be best implemented by listening for the relevant content-ids in the links field. &nbsp;The expanded form for links field isn't actually needed currently.

# Features

## Deep expansion

In some cases, it would be useful for the frontend representation of content items to have a "deep expansion" of links tags performed. Two examples:

- For a piece of content tagged to a role, it would be helpful to know the name of the person assigned to that role: eg, an organisation page ([https://www.gov.uk/government/organisations/department-of-health](https://www.gov.uk/government/organisations/department-of-health)) might be tagged with a ministerial role (eg,&nbsp;[https://www.gov.uk/government/ministers/secretary-of-state-for-health](https://www.gov.uk/government/ministers/secretary-of-state-for-health)) but should display the name and photo of the current minister, which is in turn represented as a link from the role page to the person page. Then, changing the link on the role page would update all pages where the current role holder is displayed, automatically.  
We might represent a "path" for this information in the content item as something like "`links.roles.links.people.{title,base_path,details.image_path}`".
- For a piece of content with some related content tagged to it, we currently need to know which topics and policy areas that related content is tagged to. &nbsp;This is so that we can group the related links by whether they are in the same topics as the current content.&nbsp;  
We might represent a "path" for this information in the content item as something like "`links.related_content.links.topics.{base_path}`".

These examples can be implemented in other ways, but deep expansion would be convenient for frontend applications.

## Links to things which aren't content-items

It may be necessary to link to things which aren't content items, and hence do not have a content ID. &nbsp;Some examples are:

- needs. We currently link to needs using the special "need\_id" field in content-items. &nbsp;It would seem cleaner if we could link to needs using the same mechanism as other links.
- external content. &nbsp;We might want to hook into the wider world of "linked open data".

It's unclear that there's any pressing need to implement this, but if we did implement it, we might do so by allowing a "prefix:" form to be specified for such links. No currently valid content-id contains a colon character, so we could add this in a backwards compatible way, by defining any link value without a ":" to be using a default namespace.

&nbsp;

&nbsp;

