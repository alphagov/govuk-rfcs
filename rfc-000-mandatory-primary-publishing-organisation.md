# Make primary publishing organisation mandatory in content schemas

## Summary

Data on content ownership is patchy. We are gradually adding it to the publishing API.
We should make sure that new content always has this metadata set.

If this metadata is not enforced, we can expect data quality to degrade over time as we make changes to publishing apps/content types and forget to set stuff. Incomplete ownership data would affect future work on content management.

This RFC proposes to make this field mandatory in the schemas. It does not address validation of the schemas by the publishing API.

## Problem

The data-informed-content team is gradually setting the primary organisation link type for all content on GOV.UK, so that we can help publishers manage their content over time.

Organisations should be able to use GOV.UK publishing tools to manage their "content estates" and effectively prioritise content improvement work. But
to do that we need to know who owns what.

Every document on GOV.UK has an implicit owning organisation (which can be GDS). We used to just have an `organisations` link type, but this is used inconsistently
and is not sufficient to programmatically determine who owns something.

For example, the policy "[2012 Olympic and Paralympic Legacy](https://www.gov.uk/government/policies/2012-olympic-and-paralympic-legacy)" is tagged Department for Digital, Culture, Media & Sport, Foreign & Commonwealth Office, Home Office, Olympic and Paralympic Legacy Cabinet Committee, and Olympic and Paralympic Legacy Unit.

We now have all these link types:

|link type|schema description|main use case|
|--|--|--|
|primary_publishing_organisation|The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.|Content management|
|original_primary_publishing_organisation|The organisation that published the original version of the page. Corresponds to the first of the 'Lead organisations' in Whitehall for the first edition, and is empty for all other publishing applications.|Navigation/orientation|
|organisations|All organisations linked to this content item. This should include lead organisations.|Navigation/orientation and content management|
|lead_organisations|DEPRECATED: A subset of organisations that should be emphasised in relation to this content item. All organisations specified here should also be part of the organisations array.|Navigation/orientation|
|emphasised_organisations (details hash)|The content ids of the organisations that should be displayed first in the list of organisations related to the item, these content ids must be present in the item organisation links hash.|Navigation/Orientation|

We are working on retroactively populating `primary_publishing_organisation` for existing content, and making publishing apps set it when updating content. This will bring us to a state
where everything has a `primary_publishing_organisation` set, but when we add or change a document type in the future, we're likely to forget that this data is needed for GOV.UK publishing to work properly.

## Proposal

`primary_publishing_organisation` MUST be mandatory for all content, unless we've explicitly overriden it for a document type.

`primary_publishing_organisation` MUST still be set for a document even if GDS is the de facto owner of it.

`primary_publishing_organisation` MAY be optional for these things:
- things without base paths
- things without content (gone, unpublishing, redirect, vanish etc.)