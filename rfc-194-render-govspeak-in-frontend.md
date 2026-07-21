---
status: proposed
implementation: proposed
status_last_reviewed:
---

# Render Govspeak in Frontend

## Summary

It's been almost a decade since we made the decision (in [RFC-48]) to render [govspeak] in the publishing apps. Recently the concept of rendering it in frontend has come up, and in this RFC we'll look at whether it might make more sense to render govspeak in the frontend apps instead.

## Problem

GOV.UK publishing works in a three-step system. In step one editors create documents using (mainly) govspeak. In step two that raw govspeak is converted into an HTML representation, which is then passed on to the data stores ([publishing-api] and [content-store]). Finally the frontend apps request those HTML representations, which they use to compose the pages rendered to the users.

Pros of the current situation:
- Efficient: each document of raw govspeak only has to be converted to HTML once, at time of publishing
- Status Quo: No extra work required

Cons of the current situation:
- When components in govspeak change, all documents using that component have to be republished
- It puts a timing burden on component changes, since the republish and the gem change have to be planned to prevent CSS/JS mismatch
- The app can't easily manipulate HTML (ANECDOTAL - CONFIRM WITH APP TEAM)
- Parsed HTML is generally larger than raw govspeak
- Components embedded in pre-parsed govspeak can't have A/B tests applied to them easily
- LLMs prefer markdown to HTML (ANECDOTAL - CONFIRM WITH CHAT TEAM)

## Things to consider

- Is manipulating Govspeak definitely slower than manipulating HTML?
- Could we speed up Govspeak -> HTML conversion (Could we realistically replace Kramdown with [Markly](https://github.com/socketry/markly), apparently 40x faster)
- We have extensions to Markdown to form Govspeak, are these extensions all needed if we're converting closer to time of rendering?
- Will this affect third parties (App team do not use the rendered HTML, does anyone else?)
- How do we handle inline images?
- Can the govspeak component handle this automatically? Can it handle HTML _or_ govspeak automatically?
- Could we have markdown linters or other support for publishing apps?
- Would this simplify embedding things that the frontend later has to pick out?
- Would this simplify analytics?

## Potential Benefits

- We could pass markdown to the mobile app through content api
- Publishing apps do not have to know about markdown->html conversion
- It might be easier to handle embed codes in frontend apps, improving the flexibility of
  various document types (for example, a document could have an embed tag for "postcode
  finder goes here", allowing editors more latitude in what they put before or after
  the finder).
- Single representation of blocks of edited text throughout the publishing system
- We could pass markdown to LLMs, possibly resulting in better answers
- We could perform A/B tests on components rendered in govspeak

## Proposal

We move Govspeak rendering out of the publishing stack and into the frontend stack.

Changes that would be required:
- The govspeak component in the [govuk_publishing_components] gem would need to be enhanced to allow it to accept raw govspeak and convert it to html in-app.
- Publishing apps would need to stop processing govspeak before passing it to the publishing-api

[content-store]: https://github.com/alphagov/content-store
[govspeak]: https://github.com/alphagov/govspeak
[publishing-api]: https://github.com/alphagov/publishing-api
[RFC-48]: https://github.com/alphagov/govuk-rfcs/blob/main/rfc-048-govspeak-rendering-and-embedded-content.md
