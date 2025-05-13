---
status: draft (not yet ready for review)
implementation: draft (not yet ready for review)
status_last_reviewed:
---

# Technical approach to publishing Flexible pages

## Summary

Key decisions to make:

1. Should the flexible page content schema provide a layout within which various block components are specified, or a list of sections with the layout encoded in the frontend?
2. How strict should the Publishing API content schema be in enforcing the content?
3. Should the publishing interface for flexible pages be built in Whitehall, Specialist Publisher, or another application?
4. How will we model the flexible page content in our data store?

## Decisions

### 1. Should the flexible page publishing schema provide a layout within which various block components are specified, or a list of sections with the layout encoded in the frontend?

We feel that providing the layout within the publishing schema will enable us to support a wider range of user needs faster than if each layout is encoded in the frontend. By encoding the layout in the schema, we hope to minimise the scope of changes required when new content types are requested to just a single schema file. Encoding the layout in the frontend would mean that changes or new flexible page types would require code changes in both the publishing app and the frontend app.

With the above consideration in mind, here is the schema we propose for the Publishing application:

```yaml
- document_type: history_page
  rows:
    - columns:
        - width: full
          chunks:
            - type: page_title
              uid: page_title
              heading_text:
                type: text
                required: true
              context:
                type: text
              lead_paragraph:
                type: text
    - columns:
        - width: one-third
          chunks:
            - type: image
              uid: sidebar_image
              src:
                type: text
              alt:
                type: text
            - type: contents_list
              uid: contents_list
              derived_from: govspeak_body # references uid from chunk from which contents will be extracted

        - width: two-thirds
          chunks:
            - type: govspeak
              uid: govspeak_body
              body:
                type: govspeak
```

We believe this schema allows for clear iteration in code, as follows:

```ruby
flexible_page.rows.each do |row|
  row.columns.each do |column|
    column.chunks.each do |chunk|
      #render chunk
    end
  end
end
```

We include `uid` values for each chunk so that chunks can reference each other, as will be required for the contents list chunk.

The width value for each column can be appended to `govuk-grid-column` to generate the appropriate class name for the frontend.

#### Decision

### 2. How strict should the Publishing API content schema be in enforcing the content?

There are two simple approaches to validating the flexible page content sent to Publishing API:

1. No validation of the flexible page content
2. Write a schema for each flexible page type specifying exactly what attributes should be present within the content

If we were to adopt the second design from decision 1, which places sections within a particular region, then an additional approach is possible:

3. Write a single schema for all flexible page types which validates the individual sections, but allows for any sections to be used in any region.

#### Decision

### 3. Should the publishing interface for flexible pages be built in Whitehall, Specialist Publisher, or another application?

From our existing publishing applications, there are two obvious candidates to host flexible page publishing: Whitehall and Specialist Publisher.

Factors in favour of hosting flexible page publishing in Whitehall:

1. Whitehall has the most mature feature set. Extending the Whitehall edition model would enable flexible pages with the full publishing workflow, including scheduling and 2i.
2. Whitehall is the most commonly used publishing tool, so publishers will not need to adapt to a new tool.

Factors in favour of hosting flexible page publishing in Specialist Publisher:

1. Specialist Publisher already deals with dynamically generating content forms from a schema, so we have some useful primitives in place.
2. We're less encumbered by Whitehall's hard-to-change publishing workflow and deep inheritance trees.
3. We're storing the data directly in Publishing API, so we could rely on Publishing API's schema validation rather that implementing additional validation within the publishing application.

We should also consider whether extending an open source content management system may be appropriate for our needs. However, we would need to understand how to integrate such a system with our Publishing ecosystem tools such as SignOn, Publishing API and Asset Manager.

#### Decision

### 4. How will we model the flexible page content in our data store?

We are expecting to store the flexible page content in a denormalised data structure, because we don't plan to reuse flexible sections across documents. Denormalising the data will reduce the effort for developers to add new flexible page types, at the cost of making changes to the data structures more difficult owing to a lack of support from common database migration tools. If we choose to host flexible page publishing in Whitehall, we MAY use a JSONB column on the `editions` table to store the flexible page content in. We MAY also serialize the data into the existing `body` column.

We will need a plan to handle migrations when the data structure needs to change. There are two options available:

1. Version the schema and have the publishing tool and frontend support both versions whilst the content is migrated.
2. Apply an expand and contract approach where we add new fields to the flexible page schema and only remove the old fields once all the content has been migrated. 

TODO: Consider expressing compatibility approach in terms of forward/backward compatibility defined at https://docs.confluent.io/platform/current/schema-registry/fundamentals/schema-evolution.html

#### Decision
