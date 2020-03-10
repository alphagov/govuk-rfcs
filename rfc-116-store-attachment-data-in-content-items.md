# Store attachment data in content items

## Summary

Add a new field to the details hash of content items, `attachments`,
which has metadata about the document's attachments (if any).


## Problem

Documents on GOV.UK can have attachments, which come in a few
different types.  Whitehall, which has the richest model of
attachments, has:

- External attachments (links to other websites)
- HTML attachments
- File attachments (which can have previews)

When thinking about how attachments are displayed to the user, there
are two sorts:

- *Document-level attachments*, such on Whitehall publication and
  consultation documents, which are displayed separately to the main
  content.

- *Inline attachments*, such as in other Whitehall documents, manual
  sections, specialist documents, and travel advice documents, which
  are referenced in the page content and rendered as links.

Publishing applications vary in how easily accessible they make
attachment metadata in their content items.  Whitehall only sends
rendered HTML to the Publishing API.  Other publishing apps send a
combination of rendered HTML and metadata.

This inconsistency restricts what we can do with attachments,
particularly for Whitehall content.  For example, we cannot generate
comprehensive [schema.org][] metadata for attachments: [see this
comment][].

Additionally, users of the content API cannot make use of attachments
without parsing the document body.  This inhibits creative use of our
content, and makes life more difficult for users such as the National
Archives, who need to be able to record metadata like the HoC paper
number of official publications.

We should make metadata for Whitehall attachments available in the
same way as other publishing applications, but that requires some
changes into how we represent attachments across the stack.


## Proposal

In our content schemas we already have an [`asset_link` type][], which
is used for attachments in specialist documents and manual sections.
It's also used in travel advice pages for the page image and a single
attachment.  This type appears to solve all of our problems:
[Publishing API can render such attachments with govspeak][], and
content items can expose this data to enable programmatic use.

However, the metadata Govspeak expects and the `asset_link` type are
only *informally* the same.  And furthermore, Whitehall has much richer
attachment metadata than either `asset_link` or Govspeak allow.

Given that `asset_link` is currently used for both images and
attachments, adding all of the missing metadata to `asset_link` feels
a mistake: images and attachments have different metadata, so we
shouldn't conflate the two.

I propose we do this:

1. Split `asset_link` into three new types: `file_attachment_asset`,
   `specialist_publisher_attachment_asset` and `image_asset`, updating
   the schemas which use `asset_link` accordingly, with these fields:

   - `file_attachment_asset`:
     - `url` (required)
     - `content_type` (required)
     - `title`
   - `specialist_publisher_attachment_asset` (extends `file_attachment_asset`):
     - `content_id` (required)
     - `created_at`
     - `updated_at`
   - `image_asset`:
     - `url` (required)
     - `content_type` (required)

   **Migration concerns:** This would need to be done in three steps:
   1. Update manuals-publisher to not set the `created_at` and `updated_at` for attachments.
   2. Republish all manual sections.
   3. Update the schemas.

1. Add new optional fields for extra metadata:

   - `file_attachment_asset`:
     - `accessible`
     - `alternative_format_contact_email`
     - `attachment_type` (enum with permitted values `"file"`)
     - `file_size`
     - `filename`
     - `id`
     - `locale`
     - `number_of_pages`
     - `preview_url`
   - `image_asset`
     - `alt_text`
     - `caption`
     - `credit`

   **Migration concerns:** This can be done without breaking
   compatibility, as all new fields are optional.

1. Add a new attachment type for publication attachments:

    `publication_attachment_asset`:
    - `command_paper_number`
    - `hoc_paper_number`
    - `isbn`
    - `parliamentary_session`
    - `unique_reference`
    - `unnumbered_command_paper`
    - `unnumbered_hoc_paper`
    - plus a one-of combination of:
      - the properties of `file_attachment_asset`
      - or,
        - `attachment_type` (required; enum with permitted values `"html"`)
        - `id`
        - `locale`
        - `title`
        - `url` (required)
      - or,
        - `attachment_type` (required; enum with permitted values `"external"`)
        - `id`
        - `locale`
        - `title`
        - `url` (required)

   I've left out the following fields because they can be deduced from
   others: `csv?`, `external?`, `external_url`, `file_extension`, `html?`,
   `opendocument?`, `pdf?`

   And these fields because they don't seem to be used:
   `print_meta_data_contact_address`, `web_isbn`.

   And these fields because the Publishing Workflow team are planning
   to remove them from Whitehall: `order_url`, `price_in_pence`.

   And these fields because they don't need to be exposed outside the
   publishing app: `attachable_id`, `attachment_data_id`, `deleted`,
   `ordering`, `slug`.

   **Migration concerns:** This can be done without breaking
   compatibility, as the new type will be unused for now.

1. Make `attachment_type` and `id` in `file_attachment_asset` mandatory.

    **Migration concerns:** this would need to be done in three steps:
    1. Update specialist publisher, travel advice publisher, and
       manuals publisher to set the fields.
    2. Republish all affected documents.
    3. Make the field mandatory.

1. Add a *mandatory* `details.attachments` field to all formats which
   can have attachments.

    **Migration concerns:** this would need to be done in four steps:
    1. Add the field as optional.
    2. Update publishing apps to write to it.
    3. Republish all affected documents.
    4. Make the field mandatory.

1. Add a *mandatory* `details.featured_attachments` list to
   publication formats, which is an ordered list of strings that each reference
   an id of an entry in the `details.attachments` collection.

   The reasons for preferring an id over the previous embedded HTML approach
   are:

   - less scope for inconsistency in content items - there isn't a risk
     the HTML doesn't match the attachment data;
   - removes a risk of unexpected content, since the HTML is a string
     it can contain any content and may not necessarily reflect a single
     attachment;
   - easier to updating featured attachment rendering - for a change
     in attachment rendering there is not a need to republish every document
     that uses featured attachments
   - reduction in superfluous data stored in the content item.

   **Migration concerns:** this would need to be done in four steps:
   1. Add the field as optional.
   2. Update publishing apps (just Whitehall and Content Publisher) to write to it.
   3. Update frontend apps to render attachments by injecting attachment data
      into an attachment component.
   4. Make the field mandatory.

1. Remove the `details.documents` field.

   **Migration concerns:** this would need to be done in three steps:
   1. Update publishing apps to not set `details.documents`.
   2. Republish all affected documents.
   3. Remove the field.

The final schemas will be:

```
local FileAttachmentAssetProperties = {
  accessible: { type: "boolean", },
  alternative_format_contact_email: { type: "string", },
  attachment_type: { type: "string", enum: ["file"], },
  content_type: { type: "string", },
  file_size: { type: "integer", },
  filename: { type: "string", },
  id: { type: "string" },
  locale: { "$ref": "#/definitions/locale", },
  number_of_pages: { type: "integer", },
  preview_url: { type: "string", format: "uri", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local HtmlAttachmentAssetProperties = {
  attachment_type: { type: "string", enum: ["html"], },
  id: { type: "string" },
  locale: { "$ref": "#/definitions/locale", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local ExternalAttachmentAssetProperties = {
  attachment_type: { type: "string", enum: ["external"], },
  id: { type: "string" },
  locale: { "$ref": "#/definitions/locale", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local PublicationAttachmentAssetProperties = {
  command_paper_number: { type: "string", },
  hoc_paper_number: { type: "string", },
  isbn: { type: "string", },
  parliamentary_session: { type: "string", },
  unique_reference: { type: "string", },
  unnumbered_command_paper: { type: "boolean", },
  unnumbered_hoc_paper: { type: "boolean", },
};

{
  image_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "content_type",
      "url",
    ],
    properties: {
      alt_text: { type: "string", },
      caption: { type: "string", },
      content_type: { type: "string", },
      credit: { type: "string", },
      url: { type: "string", format: "uri", },
    },
  },

  file_attachment_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "attachment_type",
      "content_type",
      "url",
    ],
    properties: FileAttachmentAssetProperties,
  },

  specialist_publisher_attachment_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "attachment_type",
      "content_id",
      "content_type",
      "url",
    ],
    properties: FileAttachmentAssetProperties + {
      content_id: { "$ref": "#/definitions/guid", },
      created_at: { format: "date-time", },
      updated_at: { format: "date-time", },
    },
  },

  publication_attachment_asset: {
    oneOf: [
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "content_type",
          "url",
        ],
        properties: FileAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      },
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "url",
        ],
        properties: HtmlAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      },
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "url",
        ],
        properties: ExternalAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      }
    ],
  },
}
```

I've validated this proposed schema by regenerating the full schemas
and checking the examples after making the following changes:

- Change `travel_advice` to use `file_attachment_asset` and `image_asset`
- Change `asset_link_list` to use `specialist_publisher_asset`

The `what-is-content-design.json` example failed as it is missing
content IDs for its attachments and it was using the specialist
publisher attachment format.  For the actual change we'd either
introduce new attachment list types, or do away with `asset_link_list`
entirely and just define the lists in the relevant schemas.

### Some design considerations

**Why two lists?**

As mentioned earlier, there are really two different types of
attachments in documents.  There are attachments which appear in the
body, and attachments which appear separately to the normal document
text, like in publications.

The `details.attachments` list would contain both types of
attachments, so there is one list with everything in.  The
`details.featured_attachments` list fulfils its current purpose:
providing the ordered list of document-level attachments for
publication-like document types.

**Why make the lists mandatory?**

Is there a difference between a missing list and a present, but empty,
list?  Maybe not, but I think it's better to be explicit that there
are no attachments for a document.

**Why split `asset_link`?**

`asset_link` is currently used for two different things: images and
attachments.  However images have strictly less permissable metadata
than attachments, it doesn't make sense to give a page image an ISBN
for example.  These should be separate types.

**Why have multiple attachment types?**

Different publishing apps have different allowable metadata, so it
makes sense to have different types constraining what a publishing app
is able to provide.

We have prior art in using a single-valued enum to make a tagged
union: it's how the top-level schemas do it, eg:

```json
"schema_name": {
  "type": "string",
  "enum": [
    "detailed_guide"
  ]
},
```

**Why `publication_attachment_asset`?**

Whitehall calls the Publication and Consultation types, which are the
types with featured attachments which present all the extra metadata,
"publicationesque" types.

**Why do we need a type for specialist publisher?**

The `specialist_publisher_attachment_asset` is needed because
Specialist Publisher presents the `created_at` and `updated_at` fields
to publishers.  Specialist Publisher uses the Publishing API as its
database, so all of that information needs to live in the content
item.

Manuals Publisher and Travel Advice Publisher have their own
databases, rather than using Publishing API directly as a backing
store, so they don't have this same problem.

[schema.org]: http://schema.org/
[see this comment]: https://github.com/alphagov/govuk_publishing_components/pull/1247#pullrequestreview-338008254
[`asset_link` type]: https://github.com/alphagov/govuk-content-schemas/blob/47a751e7eb193738c2ec43be03b149527a2b8e15/formats/shared/definitions/asset_links.jsonnet
[Publishing API can render such attachments with govspeak]: https://github.com/alphagov/publishing-api/blob/1b8e328540ab96759807787ab87dcb33bbcc72e3/app/presenters/details_presenter.rb#L71-L73
