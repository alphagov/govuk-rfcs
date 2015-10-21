&nbsp;

&nbsp;

---
status: "IN PROGRESS"
notes: "Closing for comments on ..."
---

## Problem

We have a policy that no URL be left behind. &nbsp;This means that when a piece of content moves, we need to arrange for redirects from the old location to the new.

The old endpoints for publishing content was keyed on base path, i.e. that was the unique identifier for the content, which made it difficult to move content while keeping its unique identity.

Our newer endpoints are keyed on content ID, which makes moving the content easier.

These endpoints refuse to allow new base paths to be set on published content. &nbsp;We need some explicit way of supporting the moving of content.

## Proposal

My proposal is to create an explicit (v2) endpoint to support the moving of content. &nbsp;

1. The route would be `/v2/content/:content_id/move`, which matches our publishing action endpoints (e.g. `/content/:content_id/publish`).
2. The request body would be the new location of the item.
3. Moving an item to the location it's already at would result in a 422.
4. Moving a draft item would result in a 422 (these updates can happen via the PUT content endpoint).
5. Example request body:&nbsp;[https://gist.github.com/elliotcm/02744272e6d9d26ac3e7](https://gist.github.com/elliotcm/02744272e6d9d26ac3e7)
6. The endpoint would change the `base_path` for the content item and create a&nbsp;[redirect item](https://github.com/alphagov/govuk-content-schemas/blob/master/formats/redirect/publisher/examples/redirect.json) with the old base bath under a new content ID.
7. Downstream services would be informed as per the current publish behaviour, since only published content needs to be moved this way.
8. URL arbitration would happen as per the current publish behaviour.

## Contentious points

Point 4 might be contentious, in that it could accept draft content and update the URL directly. &nbsp;This would complicate the implementation and change point 7, as the endpoint would have to apply different behaviour depending on state.

We might need to create a new update type (as we did for the links endpoint) since these changes may not be relevant enough to warrant an email alert.

&nbsp;

## Revised Proposal

In a discussion on 2015/10/21, a revised proposal was made. Under this proposal, any moves happen implicitly when a new draft is published.&nbsp;The workflow now goes as follows:

1. User publishes item with base path of /old\_path
2. User makes new draft and edits base path to /new\_path
3. Draft content item is saved with new path, this is available on content-preview at the new URL. The original item is still available on both live and content-preview at the old URL.
4. User publishes the item. This makes it available at /new\_path on live. A redirect is automatically created from /old\_path to /new\_path.

This requires two changes to publishing API functionality:

- Remove the restriction on changing the base path on draft items that have been published.
- On publish, the command checks whether the base path has changed from the previously published version. If so, it adds a redirect from old\_path to new\_path.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

