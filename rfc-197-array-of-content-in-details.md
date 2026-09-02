---
status: proposed
implementation: proposed
status_last_reviewed:
---

# New convention: array of content instead of single 'body' 

## Summary

To date, by convention, the main content of a document is represented as a single `body` property in the `details` hash of its content item. This convention is codified end-to-end, from the publishing app, to Publishing API, to Content Store, to the frontend rendering app, as well as in other downstream consumers such as Search API.

This RFC proposes gradually moving towards a new convention of an 'array' of content as a more flexible means of expressing content and its metadata, to respond to new and emerging requirements.

## Problem

There are emerging requirements that cannot be represented cleanly using a single `details.body` value.

### Multiple sections of content

The new 'mini site' format needs to be able to position a "Featured" section at an arbitrary point in the page content.

With the current representation, the body is a single compiled Govspeak string:

```json
{
  "details": {
    "body": "<div class=\"govspeak\"><p>Some content</p></div>"
  }
}
```

There is no provision for embedding non-body content inside that string of HTML. Under the current architecture, we would need to introduce some sort of placeholder in the Govspeak and have Frontend parse the body to identify and swap out the placeholder.

This is recognised as a problem in the Technology Strategy Playback ([Sharepoint][tech_strategy_sharepoint], [Google][tech_strategy_google]), page 32:

> Rigid Template Layouts: Restrictive publishing formats limit modern design elements (like maps and video), which driving some departments to build disconnected, off-platform sites.

[tech_strategy_sharepoint]: https://beisgov.sharepoint.com/:p:/r/sites/GOVUKTechnologyCommunity-TechnologyCommunity/_layouts/15/doc2.aspx?sourcedoc=%7BA20B1F6F-8F10-4E4C-8B8F-CD9E9BFE0E32%7D
[tech_strategy_google]: https://docs.google.com/presentation/d/1PkG20xeW1dxeYlgQsW3SPaZLlCceQKVr0RaHsufe36M/edit

### Metadata attached to sections of content

There are also emerging requirements in the Classifications and Systems Metadata space. Whilst the exact use cases are still being finalised, there is a general desire to be able to tag content at a more granular level than the page itself. Use-cases for associating metadata with chunks of content could include:

* designating content as associated with a taxonomy
* designating content intended for an app
* designating content intended for AI consumption
* designating content intended for users in particular nations of the UK

Some [native Govspeak support already exists for devolved content](https://github.com/alphagov/govspeak#devolved-content), but this still requires the entire body to be retrieved and parsed. It's also not a particularly sustainable approach to have to add new Govspeak rules for every thing we might want to be able to tag.

This is also recognised as a problem and recommendation in the Technology Strategy Playback ([Sharepoint][tech_strategy_sharepoint], [Google][tech_strategy_google]), page 64:

> Restructure GOV.UK content and metadata specifically so that it is machine-readable and consumable by third-party Large Language Models (LLMs) and automated agents, rather than just optimising for human web consumption.

## Proposal

Instead of a single `details.body` string of HTML, we will iterate towards `details.content[]`, which will contain an array of objects adhering to a common interface. Each object will include the following properties:

- `type` - the type of the object
- `value` - the value of the object
- `metadata` (optional - can be omitted) - a hash of arbitrary metadata associated with the object
- Additional properties could be allowed in future on a per-object-type basis.

This data structure allows us to solve the content-granularity and content-tagging problems outlined earlier.

### Example

Here is how a content item currently looks:

```json
{
  "details": {
    "body": "<div class=\"govspeak\"><p>Some content</p></div>",
    "change_history": [
      {
        "public_timestamp": "2026-08-10T08:41:00.000+01:00",
        "note": "First published."
      }
    ]
  }
}
```

As a starting point, all we're looking to do is swap the above for this - note that the other fields within `details` (i.e. `change_history`) are unchanged:

```json
{
  "details": {
    "content": [
      {
        "type": "html",
        "value": "<div class=\"govspeak\"><p>Some content</p></div>"
      }
    ],
    "change_history": [
      {
        "public_timestamp": "2026-08-10T08:41:00.000+01:00",
        "note": "First published."
      }
    ]
  }
}
```

Going forward, we're free to work towards new object types and any arbitrary metadata, to accommodate future requirements. The following example is out of scope for this RFC, but is included as an indication of what could be possible. As ever, it is up to downstream consumers (such as Frontend) to decide what to do with this information:

```json
{
  "details": {
    "content": [
      {
        "type": "html",
        "value": "<div class=\"govspeak\"><p>Some content</p></div>",
        "metadata": {
          "app_friendly": true,
          "devolved_nations": [
            { "nation": "wales", "alternative_uri": "https://gov.uk/foo.cy" }
          ]
        }
      },
      {
        "type": "featured_section",
        "ordered_featured_documents": [
          {
            "document_type": "Policy paper",
            "href": "/government/publications/youth-matte..."
          },
          ...
        ]
      },
      {
        "type": "govspeak",
        "value": "## Heading\n[Link](https://gov.uk/bar)",
      },
      {
        "type": "html/h1",
        "value": "HEADING LEVEL 1 GOES HERE (just an example)",
      },
    ],
    "change_history": [
      {
        "public_timestamp": "2026-08-10T08:41:00.000+01:00",
        "note": "First published."
      }
    ]
  }
}
```

Note the multiple objects in the `details.content` array, the different `type`s and the common use of `value` (where appropriate).

### Implementation

We're going to begin with content types that have [migrated to StandardEdition](https://docs.publishing.service.gov.uk/repos/whitehall/migrating_to_standard_edition.html). At time of writing, these are: Topical Events, News Articles, Case Studies and History Pages. The long term aim in Whitehall is to migrate all content types to StandardEdition, so eventually all content types originating from Whitehall will be represented as `details.content[]`.

Working backwards, we need to build support into the downstream consumers of content.

1. In Frontend, make a change to [ContentItem](https://github.com/alphagov/frontend/blob/d3073a4fd70e304d47aae413a160cbd42ae959eb/app/models/content_item.rb#L14) so that the `body` method grabs the first appropriate item (`type: "html"`) from `details.content` if it exists, otherwise falling back to `details.body`.
1. In search-api, make a change to [indexable_content_parts](https://github.com/alphagov/search-api/blob/87a43870dc63f1e08d72092cd0eb389a8aaf5bb0/lib/govuk_index/presenters/indexable_content_presenter.rb#L39-L44) to look for `details.content` and to retrieve any objects which have a `value`.
1. In search-api-v2, make a change to [INDEXABLE_CONTENT_VALUES_JSON_PATHS](https://github.com/alphagov/search-api-v2/blob/e13de24a3b825b7a2c805c011d1693cec435d058/app/models/concerns/publishing_api/content.rb#L15) to include `$.details.content[*]['value']`.

Then in the publishing stack:

1. Update Publishing API schemas for the StandardEdition formats, to accept either a `details.body` string or a `details.content` array of objects.
1. Make a change to Whitehall's [StandardEditionPresenter](https://github.com/alphagov/whitehall/blob/7a505b1b575e24676405d828e22ad8f32b41f292/app/presenters/publishing_api/standard_edition_presenter.rb#L42-L43) to send `details.content` instead of `details.body`.
1. Republish all StandardEdition content.
1. Update Publishing API schemas again to remove support for `details.body` from these formats.

At this point we'd now have the foundations in place, across the stack, to allow for arbitrary placement of additional sections in the page, and arbitrary tagging of said sections.

In terms of governance, we also propose:

1. A shared document in the Developer Docs, describing the different object types that can appear in `details.content[]`. That way, all downstream consumers have a reference they can build against.
1. Pact tests could be considered further down the line, when more object types are created, but are overkill at this stage.

### Beyond

Where we iterate on the foundation above is out of scope for this RFC. But as an indicator of the kind of value this change can unlock, here are some thoughts below.

On a per-document-type basis, the Whitehall and Patterns & Pages teams will work together to enable dynamic support for unlimited elements in the `details.content` array.

In the short term, we may begin with the new 'mini site' content type, with a view to sending two bodies of content and a Featured section in the middle:

```json
{
  "details": {
    "content": [
      {
        "type": "html",
        "value": "<div class=\"govspeak\"><p>Content above the featured section</p></div>",
      },
      {
        "type": "featured_section",
        "ordered_featured_documents": [
          {
            "document_type": "Policy paper",
            "href": "/government/publications/youth-matte..."
          },
          ...
        ]
      },
      {
        "type": "html",
        "value": "<div class=\"govspeak\"><p>Content below the featured section</p></div>",
      },
    ],
  }
}
```

We might achieve this in Whitehall in the short term by:

1. Continuing to have a single 'Body' textarea
1. Defining some sort of `{{Featured}}` placeholder that the publisher can put into the Body
1. At the point of saving, the StandardEditionPresenter can check for the presence of that placeholder and if it exists, split the Body into two, and inject the Featured section in between, in the `details.content` that is sent to Publishing API

Longer term, one can imagine some sort of [WordPress Gutenberg](https://wordpress.org/gutenberg/)-like WYSIWYG interface where the publisher can create and rearrange structured content, allowing them to inject all manner of special content (such as maps, videos, etc) anywhere in the content body. That interface could also allow for arbitrary tagging of each piece of content.

## Appendix

### Naming

`details.content` was so chosen because this is expected to encapsulate the main content of the page, replacing `details.body` - and there don't appear to be any existing presenters / content items where a `content` property already exists.

`details.content[].type` was so chosen because it's a good name for the 'type' of the thing in the array. We did also consider `content_type`, but apart from the unnecessary repetition of the word 'content', that property name _does_ have an existing meaning in the publishing stack already:

- Content can be sent as an array of hashes each with a `content_type` property, with a value of `text/html` or `text/govspeak`. See [example of sending 'summary' of type Govspeak from Specialist Publisher](https://github.com/alphagov/specialist-publisher/blob/c8bb9d4902e8dd341589ce96018b46a32cccfb91/app/presenters/finder_content_item_presenter.rb#L64-L74)
- If only an element of `content_type: "text/govspeak"` is sent, [Publishing API renders the Govspeak](https://github.com/alphagov/publishing-api/blob/70c62d85f71205b22a1d1bd467e4330d84b3fbac/lib/govspeak_details_renderer.rb#L27-L35) and saves an additional element to the hash of type `text/html`.
- All `content_type`s are [sent downstream to Content Store](https://github.com/alphagov/publishing-api/blob/1e3f1f48822b3caf7a34eb8d92000b626d251241/app/commands/v2/put_content.rb#L33-L37)
- When Content API renders a content item, it [looks for an element of type 'text/govspeak'](https://github.com/alphagov/content-store/blob/e77343c4f4ec4e14b289c61fbf22c56ec543e988/app/presenters/content_item_presenter.rb#L10) and [retrieves only the first matching element from the array](https://github.com/alphagov/content-store/blob/196a82266cca7f3f8d4e639cd654bc9229c89078/app/presenters/content_type_resolver.rb#L31-L33)
- ...so if we'd gone with `content_type` in this RFC, we'd risk Content API dropping anything that doesn't match `text/html`!

### See also

- [RFC-194](https://github.com/alphagov/govuk-rfcs/pull/194), which proposes moving Govspeak rendering to Frontend. (It currently happens mostly in Whitehall, and occasionally Publishing API). Nothing in this proposal conflicts with that RFC.
- [RFC-182](https://github.com/alphagov/govuk-rfcs/pull/182), which proposes sending `details.flexible_sections` made up of objects with bespoke properties (e.g. `contents_list`). That does cover a lot of the same ground as this proposal, but it also includes layout implications and changes to the publishing interface in its scope. RFC-197 is deliberately focussed on a smaller subset of the problem: modularisation of the content itself, and the flexibility that that allows for in future when it comes to content structure and tagging.
