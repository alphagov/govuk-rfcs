---
status: superseded
implementation: superseded
status_last_reviewed: 2024-03-06
status_notes: Content Store content is kept in sync with Publishing API so there is no longer a choice.
---

# Managing special snowflake URLs through the Publishing API

## Problem

There are a [number of URLs on GOV.UK](https://docs.google.com/spreadsheets/d/1LUpym0SVeOkom-k6qnqUic1tyIRhnHgKrAsXwr1kX5w/edit#gid=0) which do not fall into the category of traditional leaf-node published content e.g. robots.txt, search, or the homepage.

These URLs are frequently registered with the router directly. &nbsp;Since they aren't entered into the URL arbiter this sometimes causes clashes and/or [downtime if important routes are overwritten](https://docs.google.com/document/d/1Ev_axmMdvsg3WTnYpdYVBciSAzM3q64QklB8MOZl7Go).

## Proposal

The minimum required to add safety to this process is to have the routes pass through the URL arbiter. &nbsp;We could have all applications which register these snowflake routes directly instead check with the arbiter first, but this is an untidy option and open to error. &nbsp;We'd also like to reduce the number of applications which talk directly to the router API as much as possible. &nbsp;This suggests we use the publishing API as the registration mechanism.

So far there are two proposals on how to do this:

1. **Use the publishing API as an endpoint but don't write to the content store**. &nbsp;This would require a new endpoint on the API which engages in URL arbitration but does not push to either live or draft content stores. &nbsp;It would also require the API to speak to the router API directly, something which it currently delegates to the content store.
2. **Add content store entries**. &nbsp;This would require no changes to the publishing API. &nbsp;The owning applications would publish a "snowflake" format document to the publishing API on deploy (or whenever else they normally do this, e.g. via rake tasks) containing some human-readable information about the path and why it exists (e.g. "`/search` handles the display of search results across the site" or "`/info` is a prefix to provide statistics about other routes on GOV.UK") and allow the standard publishing pipeline to deal with URL arbitration and route registration. &nbsp;This could later allow some of the routes to be not only registered via the publishing pipeline but also rendered out of the content store, for example in the case of `robots.txt`.

My personal preference is for proposal #2. &nbsp;Here's an example of what the document might look like for `robots.txt`:&nbsp;[https://gist.github.com/elliotcm/cddd6ea1f4e3989009bd](https://gist.github.com/elliotcm/cddd6ea1f4e3989009bd)

