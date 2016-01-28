## Problem

The publishing system uses the&nbsp;`format` element of a content item for three purposes:

- to identify the schema used to validate a content item
- to determine the way the item is displayed on the frontend
- (in phase 2) to filter lists of objects in publishing apps

Although these use cases are related, it is not necessarily the case that a schema maps directly to a document type: one example is in specialist-publisher, where there is one single schema for "specialist document" but many different types of document, eg CMA cases, AAIB reports, drug safety alerts, etc, which need to be displayed separately in the publishing app.

This is likely to become more significant when the work is done to consolidate formats; at that point we might only have a small selection of schemas and front-end templates, but potentially still need to distinguish sub-types in the publishing apps.

Currently, specialist documents define a "document type" field in the details hash; however, because it is not at the top level of the document, it is not available for use in filtering.

## Proposal

We will deprecate the current `format` field, and replace it with two new fields:

- `schema` - determines which file in govuk-content-schemas is used to validate the item.
- `content_type` - used for frontend display and for filtering in publishing apps&nbsp;

(Question: does the latter actually need to be two separate fields, eg "content\_type" and "display\_content\_type"? Is there a case when they will be different?)

### Migration

We will support both naming types for a period to ease transition, and modify publishing-api to supply missing data where necessary. If only the old&nbsp;`format` field is supplied, its value will be copied to&nbsp;`schema` and&nbsp;`content_type`. If&nbsp;`format` is not supplied, its value will be copied from&nbsp;`schema`. It will be an error to supply only one of&nbsp;`schema` and&nbsp;`content_type`.

All three fields will be supplied to content-store.

&nbsp;

&nbsp;

&nbsp;

