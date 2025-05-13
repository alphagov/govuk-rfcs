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
4. What will the migration path be when we want to make a change to a flexible page type?

## Decisions

### 1. Should the flexible page content schema provide a layout within which various block components are specified, or a list of sections with the layout encoded in the frontend?

We have identified two possible schema designs that would fulfil our needs. The  first structure follows the original design proposed by the Patterns and Pages team. This is how we would represent a history page in a publishing app following that design:

```yaml
document_type: history_page
flexible_sections:
- section: page_title
  uid: title
  inputs:
  - name: heading_text
    type: text
    required: true
  - name: context
    type: text
  - name: lead_paragraph
    type: text

- section: rich_text_with_contents_list
  uid: rtcwcl
  inputs:
  - subsection: contents_list
    inputs:
    - name: image
      inputs:
      - name: source
        type: url
        required: true
      - name: alt
        type: text
      - name: caption
        type: text
    - name: items
      children:
      - name: href
        type: text
        required: true
      - name: text
        type: text
        required: true
    - name: content
      type: govspeak
      required: true
```

In this design, the schema is a list of named sections, each with fixed subsections. It is expected that each section would take up the entire width of the screen on the frontend.

We are also considering a second possible design, which specifies a layout. The same history page example above would look like this in the second design:

```yaml
document_type: history_page
header:
  - section: page_title
    uid: title
    inputs:
      - name: heading_text
        type: text
        required: true
      - name: context
        type: text
      - name: lead_paragraph
        type: text
sidebar:
  - section: image
    uid: sidebar_image
    inputs:
      - name: image
        inputs:
          - name: source
            type: url
            required: true
          - name: alt
            type: text
          - name: caption
            type: text
  - section: contents_list
    uid: page_contents
    inputs:
      - name: items
        children:
          - name: href
            type: text
            required: true
          - name: text
            type: text
            required: true
main_content:
  - section: rich_text
    uid: body
    inputs:
      - name: content
        type: govspeak
        required: true
```

In this design the schema defines a number of page regions which can be populated by one or more sections.

### 2. How strict should the Publishing API content schema be in enforcing the content?

There are two simple approaches to validating the flexible page content sent to Publishing API:

1. No validation of the flexible page content
2. Write a schema for each flexible page type specifying exactly what attributes should be present within the content

If we were to adopt the second design from decision 1, which places sections within a particular region, then an additional approach is possible:

3. Write a single schema for all flexible page types which validates the individual sections, but allows for any sections to be used in any region.
