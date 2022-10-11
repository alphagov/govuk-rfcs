# Integrating an off-the-shelf CMS with GOV.UK infrastructure to power custom pages

## Summary

GOV.UK has built a number of bespoke content management systems (CMS) to enable the publishing of a variety of pre-defined document types. However, these tools are of limited assistance when a need emerges to create a one-off page on GOV.UK (hereafter referred to as custom page) that is not one of these pre-defined document types.

Examples of these types of pages, and their content management solutions, are:

- [GOV.UK Homepage](https://www.gov.uk/) and [GOV.UK Roadmap](https://www.gov.uk/roadmap), where Rails I18n has been used as a basic [YAML CMS system](https://github.com/alphagov/frontend/blob/f2af829b14a9e6af21deb49c9bd0484e9ea49baa/config/locales/en.yml#L454-L576) which require developer support and complicates actual internationalisation management.
- [Travel Advice index](https://www.gov.uk/foreign-travel-advice), where content is [hardcoded](https://github.com/alphagov/frontend/blob/f2af829b14a9e6af21deb49c9bd0484e9ea49baa/app/views/travel_advice/index.html.erb) in HTML and needs developer support to amend.
- [Coronavirus landing page](https://www.gov.uk/coronavirus), where [bespoke CMS tooling](https://github.com/alphagov/collections-publisher/tree/d68bf4cf910b62d7827f488ed2f20126bc9b25a4/app/controllers/coronavirus) was built for a single page at a high implementation cost.

In 2022 GOV.UK again has the need for a new bespoke page, one to provide [Cost of living support](https://www.gov.uk/cost-of-living). It has been decided that GOV.UK will experiment with integrating an off-the-shelf [headless CMS](https://en.wikipedia.org/wiki/Headless_content_management_system) to meet the CMS needs for this page. This is to explore a hypothesis that with flexible CMS tooling a bespoke page could be built more simply, with the CMS functionality  managed entirely by the team developing the frontend code. The purpose of this RFC is to propose how a headless CMS product can integrate with GOV.UK infrastructure.

_Note, to facilitate focused discussion it's worth clarifying the scope of this RFC, which is limited to how an off-the-shelf CMS can be integrated with GOV.UK. This RFC only consider an off-the-shelf CMS for the purpose of meeting existing unmet CMS needs on GOV.UK and is intended to supplement existing GOV.UK CMS tools, this is not an indication that these will be replaced by an off-the-shelf CMS tool. It is outside the scope of this RFC to discuss whether GOV.UK should be building their own CMS for a custom page - a GOV.UK Senior Management Team decision was made to explore a non-bespoke solution for this situation. It is also outside the scope of this RFC to discuss which CMS will be used and the operational concerns - for the initial implementation it was decided that [Contentful](https://contentful.com) will be used, and should the experiment be a success a wider procurement exercise will consider CMS products._

## Problem

While it is relatively straight forward to model GOV.UK content in a headless CMS tool, it is less clear how this data will integrate with the GOV.UK stack.

There are key considerations to make such as:

- Will data from a CMS be input into the publishing pipeline (Publishing API, Content Store, etc) or bypass it?
- How might pages powered by a CMS result in a routes registered with Router?
- Could a page powered by a non-GOV.UK CMS have a presence in Search API?
- Will GOV.UK rendering applications need to consider another content source than Content Store and Search API?
- Should the CMS be offline would we accept unavailability of a public GOV.UK page or need a fallback system?
- Whether modelling changes in a CMS would result in needing to make other changes in the GOV.UK publishing stack?

## Proposal

We propose that integrating an off-the-shelf headless CMS into GOV.UK should involve the CMS syncing data with the Publishing API. This would allow:

- no increase in dependency for GOV.UK rendering applications, they continue to receive page content from Content Store and do not need to consider CMS unavailability
- ability to integrate a page with Search API using existing Publishing API message queue approach
- implicit updating of Router API

However in order to facilitate this there would need to be new software built, to bridge communication between a CMS and GOV.UK, and changes to existing software to facilitate this bridging.

### Bridging software

It is common that headless CMS tools make use of [webhooks](https://en.wikipedia.org/wiki/Webhook) as a means to notify subscribing software to events that occur in the CMS. We propose the introduction of a piece of software that will listen for a CMS's webhooks and use this information as an initiator of a process to update the content.

This software will identify whether a webhook event signifies a live or draft event and update the Publishing API accordingly by the content data in the CMS (typically a JSON blob).

For integration with Contentful, we will deploy a new GOV.UK application: Contentful Listener API. This was [developed](https://github.com/alphagov/contentful-listener-api) whilst spiking approaches to this problem. There is documentation written to the describe the [workflow](https://github.com/alphagov/contentful-listener-api/blob/main/docs/how-this-application-works.md) of this tool and [integration limitations](https://github.com/alphagov/contentful-listener-api/blob/main/docs/integration-limitations.md). This application will be owned by the Publishing Platform team.

### Changes to existing software

It is expected that in order to flexibly model a GOV.UK page in an off-the-shelf headless CMS there will need to be multiple content entities involved (ie. to model the Cost of living page, there may be multiple accordion entities associated with a Cost of living page entity). In order to track whether these are associated with content a new field will be added to the Publishing API: `cms_entity_ids` this can be used to store the unique IDs of items in the off-the-shelf headless CMS. When a webhook event is received this ID will be queried to determine if any GOV.UK content is affected.

The [`special_route`](https://github.com/alphagov/govuk-content-schemas/blob/main/formats/special_route.jsonnet) schema in [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas) will be updated to accept a details field. This details field will not have restrictions on how the data is structured, this will allow changes in the modelling of content without needing a schema to be updated (this was an [approach explored](https://github.com/alphagov/govuk-content-schemas/blob/170a941b42bbc53d529b4c50698ad5ba50776df5/formats/coronavirus_landing_page.jsonnet#L4-L8) for the Coronavirus landing page). It is theorised that having a schema for a custom page is more of a hindrance than benefit given the data is only used in a single place.

### Further considerations

- If the CMS was offline and we needed to make edits to content this would be done by a short term hardcoding in the frontend application to set content.
- It is unlikely, due to complexity reasons, that we would integrate [Asset Manager](https://github.com/alphagov/asset-manager) with the CMS tooling and instead rely on the CMS to host assets such as images. If the CMS was offline these would be unavailable, but as the page would still be available this would not be a critical issue to resolve.
- Should we change CMS we would retire contentful-listener-api in favour of an appropriate one, or rename contentful-listener-api to be cms-listener-api to be a generic tool that serviced multiple CMS tools.
- Should the result of the experiment be that we will not continue with an off-the-shelf CMS the Publishing team will revert all changes made to the stack.
- Should the experiment with the Cost of living support page be successful we may experiment with supporting other custom pages such as GOV.UK homepage or GOV.UK Roadmap or potentially the content of a Smart Answer.
