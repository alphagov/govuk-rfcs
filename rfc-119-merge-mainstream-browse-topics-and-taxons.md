# RFC 119: Merge mainstream browse, specialist topic into to taxon content items

## Summary

Mainstream browse, specialist topic and taxon content items are functionally equivalent, in that they represent a category that groups content items. We would like to maintain future consistency between our taxonomy, mainstream browse and specialist topic titles. We propose merging the attributes of mainstream browse and topic content items into taxons and deprecating use of mainstream browse and specialist topics in the Publishing API and Content Store.

## Background

There are currently three different and independent ways to categorise content items - [mainstream browse pages][mainstream-browse-page-docs], [specialist topics][specialist-topic-docs] and [taxons][taxon-docs]. A content item can be associated with one or more mainstream browse pages, specialist topics or taxons. Each of which represents a grouping of content items that are related in subject matter. For example content items representing a "Income Tax" guidance page and a "Inheritance Tax" guidance page are assigned to the "Tax" mainstream browse page.

Mainstream browse pages, specialist topics and taxons themselves are represented as content items. Each type can contain links to other items of the same type and usually do so building a hierarchical tree structure. For example, the "Child benefit" and "Universal Credit" specialist topics are linked and represented as children of the "Benefits" specialist topic. For each type there is one "root" item that represents the start of the hierarchy. There is an exception for taxons, where there are two hierarchies with two distinct roots and sets of items - [topic taxonomy][topic-taxonomy-docs] and [world taxonomy][world-taxonomy-docs]. For purposes of this RFC ignore the world taxonomy.


## Problem

We have to maintain three separate types of categorisation for content items - mainstream browse pages, specialist topics and taxons. This means the categories themselves and the content assigned to them may be different between each type. For example, the "Education and learning" mainstream browse page is the logical equivalent of the "Education, training and skills" taxon and should be the same, however they differ in name and in the set of content items they represent. There are also categories that only exist in some types and not others, for example the "Setting up a business" mainstream browse page has no equivalent taxon.

Examples of equivalent content items:

Mainstream browse page: https://www.gov.uk/api/content/browse/benefits/universal-credit

Specialist topic: https://www.gov.uk/api/content/topic/benefits-credits/universal-credit

Taxon: https://www.gov.uk/api/content/welfare/universal-credit

There is currently ongoing work to ensure mainstream browse and specialist topics have equivalents in the taxonomy, i.e. mainstream browse and specialist topics become a subset of taxons. This is being done by Content Designers who are liaising with departments to come to agreement.

Once this work is complete we want to maintain alignment and prevent divergence from taxons. We would have to put constraints in collections publisher and content tagger (or any future apps) to ensure that mainstream browse and specialist topics continue to be subsets of taxons. This would involve adding complex logic to the publishing system to deal with addition, changing or removal of these content items.

## Proposal

We propose merging the attributes of mainstream browse and specialist topic content items into **existing** taxon content items with the same `title`. (For clarity we aren't proposing the creation of new taxons or taxon tree.)

Generally there are two main type of information we want to tranfer from mainstream browse and specialist topic to the equivalent taxon. The first is the links to content items. Currently content items (guidance pages, manuals etc..) do not contain links to mainstream browse or specialist topics. It's the reverse, mainstream browse pages and specialist topics have a list of content that's associated to them. This list we can migrate over to the taxon.

Secondly, we'd carry across the relationships (links) between mainstream browse pages/specialist topics. This manifests as multiple hierarchies within the same taxons. This is because different relationships are useful for different things i.e. the current hierarchy for taxonomy is used for modelling emails subscriptions, but cannot be used for modelling navigation. So we'd bring over the mainstream browse hierarchy to serve that purpose.

#### Top level attributes

All top level attributes will continue to have the existing values in the taxon:

- `title`
- `description`
- `analytics_identifier`
- `content_id`
- `document_type`
- `first_published_at`
- `locale`
- `phase`
- `public_updated_at`
- `publishing_scheduled_at`
- `rendering_app`
- `scheduled_publishing_delay_seconds`
- `schema_name`
- `updated_at`
- `withdrawn_notice`
- `publishing_request_id`

This is because they don't cause conflict or the mainstream or specialist topic value becomes redundant.

- `publishing_app`

Currently references Collections Publisher for mainstream and specialist topics, however references Content Tagger for taxons. We propose that `publishing-app` remains Content Tagger as it still has the responsibility of creating and removing taxons, even though some sub properties (i.e. links and details) may be set by Collections Publisher. In the future, we could also look at consolidating the publishing functionality of Collections Publisher and Content Tagger.

- `base_path`

Mainstream browse and specialist topic pages have different `base_path` to taxons. We propose that taxons keep their existing `base_path`. We could use new mainstream browse/specialist topic links within taxons to generate old base paths or find the appropriate taxon from an existing mainstream browse or specialist topic base path. Alternatively, we keep the old base paths as renamed attributes (e.g. `mainstream_browse_base_path`).

#### Link attributes

Taxons continue to have the following links:
- `legacy_taxons` (potentially remove once specialist topics are removed)
- `parent_taxons`
- `available_translations`

Add from mainstream browse:
- `browse_parent` (parent taxons which should be used for mainstream browse)
- `browse_children` (reverse links to `browse_parent`)

Add from specialist topic:
- `specialist_topic_parent` (parent taxons which should be used for specialist topics)
- `specialist_topic_children` (reverse links to `specialist_topic_parent`)

Dropped from mainstream browse:
- `top_level_browse_pages` (an be derived from `base_path` and following `browse_parent`)
- `active_top_level_browse_page` (can be derived from `base_path`)
- `second_level_browse_pages` (an be derived from `base_path` and following `browse_parent`)
- `related_topics` (is the related specialist topic, and would become a self reference)
- `primary_publishing_organisation` (redundant)
- `available_translations` (redundant)

Dropped from specialist topic:
- `taxons` (is the taxon, would become a self reference)
- `topic_taxonomy_taxons` (redundant)
- `primary_publishing_organisation` (redundant)
- `available_translations` (redundant)

#### Details attributes

Taxons continue to have the following details:
- `internal_name`
- `notes_for_editors`
- `visible_to_departmental_editors`

Added from mainstream browse:
- `browse_groups` (the curated groupings of browse children)

Added from specialist topic:
- `specialist_topic_groups` (the curated groupings of specialist_topic_children)

Dropped from mainstream browse:
- `internal_name` (redundant)
- `second_level_ordering` (can be deduced by following link to parent)
- `ordered_second_level_browse_pages` (can be deduced by following link to parent)

Dropped from specialist topics:
- `internal_name` (redundant)

### Example of proposed taxon content item after merging:
```json
{
  "title": "Universal Credit",
  "description": "Applying, signing into your account, and help with housing, disability, health conditions and unemployment",
  "base_path": "/welfare/universal-credit",
  "content_id": "62fcbba5-3a75-4d15-85a6-d8a80b03d57c",
  "document_type": "taxon",
  "schema_name": "taxon",
  "publishing_app": "content-tagger",
  "rendering_app": "collections",
  "locale": "en",
  "phase": "live",
  "first_published_at": "2018-03-08T16:38:00.000+00:00",
  "public_updated_at": "2018-08-22T13:14:40.000+00:00",
  "updated_at": "2019-08-09T20:07:42.761Z",
  "publishing_request_id": "12821-1535466331.861-10.3.3.1-394",
  "publishing_scheduled_at": null,
  "scheduled_publishing_delay_seconds": null,
  "analytics_identifier": null,
  "withdrawn_notice": {},
  "links": {
    "parent_taxons": [],
    "browse_children": [],
    "browse_parent": [],
    "specialist_topic_children": [],
    "specialist_topic_parent": [],
    "primary_publishing_organisation": [],
    "available_translations": []
  },
  "details": {
    "internal_name": "Universal Credit [M]",
    "notes_for_editors": "",
    "visible_to_departmental_editors": false,
    "specialist_topic_groups": [],
    "browse_groups": [],
    "browse_ordering": "curated",
    "ordered_second_level_browse_pages": []
  }
}
```

We would probably approach this work in two stages by merging mainstream browse *and then* specialist topics. After both are merged we'd look at deprecating mainstream browse and specialist topics content items in the Publishing API and Content Store.

To do this we'd change application dependencies to read from taxons. Application dependencies we'd have to consider:

- Rendering `/browse/*` and `/topic/*` pages in Collections Frontend
- Displaying metrics for `/browse/*` and `/topic/*` pages in Content Data
- Signing up and email subscriptions per specialist topic
- Finding browse links in the Knowledge Graph

Once we are confident we are solely using the taxons, we can unpublish the existing mainstream browse and specialist topic content items.

This work should not introduce any user facing changes.

## Benefits
This would allow us to ensure ongoing consistency of our "Information Architecture" and grouping of content, without the complexity of maintaining three document types or seperate sets of content items.


[mainstream-browse-page-docs]: https://docs.publishing.service.gov.uk/document-types/mainstream_browse_page.html
[specialist-topic-docs]: https://docs.publishing.service.gov.uk/document-types/topic.html
[taxon-docs]: https://docs.publishing.service.gov.uk/document-types/taxon.html
[topic-taxonomy-docs]: https://docs.publishing.service.gov.uk/manual/taxonomy.html
[world-taxonomy-docs]: https://docs.publishing.service.gov.uk/manual/world-taxonomy.html

