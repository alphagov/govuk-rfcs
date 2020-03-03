# Storing global content in content-store

## Problem

We have content that is “global” to all of GOV.UK that isn’t represented in the content-store. These are things like the Header, Footer and Banners (Emergency and Cookie).

At the moment these are hard-coded into Static, and through Slimmer deployed across GOV.UK instantaneously.

This useful feature of instant deployment of content (as it bypasses our publishing-api to content-store workflow) is the [major blocker we face in removing Static and Slimmer](https://github.com/alphagov/govuk-rfcs/pull/84)

## Proposal

We could store content for the header and footer as pieces of content in themselves that every other piece of content links to.

However if we used the Publishing API as a means of updating, then _everything_ would need to update. The publishing queues would be full and it could take several hours for content to get this change. This is probably worse than upadting the frontend apps with new hard coded content in the govuk_publishing_components gem where we would update and deploy all of the frontend apps.

We can treat the header and footers as structured content, for example footer is a list of links, with headings, sections, custom link text (that do not match the title of destination content).

We could instead bypass the normal Publishing API workflow altogether (it could still exist in the Publishing API) and link every piece of content in the content-store directly to the global pieces in a 1-1 relationship.

If we want this global content to exist as a content item itself, this would result in it having its own URL which we would want to avoid. We could include it as part of the Homepage content item. Everything on GOV.UK already points back to the Homepage.

It should be based on its own JSON schema.

### Updating global content

We want

## Things to work out

- How do we update global content?
- Work out a schema - what data to store
- Scope of what the global content item contains
- How to deliver the “draft” overlay as this is provided by Static
- What all the banners are
- What all the footer links are
- Whatever other footer data there is

## Forseeable problems

Every content item “linking” to this global content means additional requests to fetch that over HTTP. An n^2 increase. Can our infrastructure handle that?