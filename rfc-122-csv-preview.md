---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# CSV Preview

[govuk-content-schemas]: https://github.com/alphagov/govuk-content-schemas
[government-prefix]: https://trello.com/c/74KTVXBs/52-whitehall-relies-on-prefix-government-and-world-routes
[router]: https://github.com/alphagov/router#backend-handler

## Summary

Move the CSV Preview feature out of Whitehall and into Government Frontend, so that it can be used for documents published by other apps, like Content Publisher. The new implementation will work by rendering a content item in a new `attachment_preview` format, which represents an attachment to preview.

## Problem

A user viewing a Whitehall document on GOV.UK can click a "View Online" link for any of its CSV file attachments [[example](https://www.gov.uk/government/publications/hmrc-exchange-rates-for-2020-monthly)]. This takes the user to a new page, currently rendered by Whitehall. The page contains:

   - A 'header' section with details of the parent document (and navigation links)
   - A 'body' section with a preview of the content of the CSV attachment

This CSV Preview feature only works for CSV file attachments uploaded through Whitehall. We need it to work for CSV attachments published through Content Publisher, which is superseding Whitehall.

## Proposal

### Step 1

Create a new `attachment_preview` format in [govuk-content-schemas][] to represent the preview page for an attachment. A publishing app will publish content items in this format for each CSV attachment to preview.

```
# formats/attachment_preview.jsonnet
(import "shared/definitions/publishing_api_base.jsonnet") + {
  document_type: "attachment_preview",
  attachment: {
    "$ref": "#/definitions/file_attachment_asset"
  },
  edition_links: {
    parent: {
      description: "The parent content item.",
      maxItems: 1,
    },
    primary_publishing_organisation: {
      maxItems: 1,
    },
  }
}
```

- Using a content item is consistent with the one-to-one mapping of pages and content on GOV.UK. This should make it easier to debug issues with the feature, since it follows an existing pattern.

- The schema includes a link to the parent document. Using an expanded link means we don't need to make an extra API call to the Content Store in order to show information about the parent document.

- The schema includes a link to the primary publishing organisation. Including organisation info is [a longterm endeavour](https://github.com/alphagov/govuk-rfcs/pull/92), and will also make it a bit simpler to render the organisation logo in the header.

- Using the publishing system means we can follow an existing approach for things like automatic redirects (in case the base path changes), unpublishing and anonymous preview ('fact check'). However, this entails an overhead of extra Publishing API operations to manage the separate content items - draft, publish, remove, etc. - with the associated risk they get out-of-sync e.g. due to transient network errors when calling the API.

- Using a separate content item means we're not coupled to a particular rendering app. This provides a foundation for extending the preview feature in the future.

### Step 2

Re-implement the CSV Preview feature in Government Frontend.

- Government Frontend currently renders all documents published by Whitehall, that have CSV file attachments. This makes it a relevant codebase to implement this feature in.

- We expect the implementation to be small, isolated and not to grow/change much. Adding a new responsibility to Government Frontend seems like a reasonable compromise when compared to the [rejected proposals](#rejected-proposals).


### Step 3

Change Whitehall to use the new CSV Preview feature for newly published documents. We will need to use a different URL structure, since the current one is coupled to Whitehall.

```
# current URL example
https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/856932/Management_information_-_further_education_and_skills_-_as_at_31_December_2019.csv/preview

# proposed URL example
https://www.gov.uk/government/remaining-parent-document-base-path/preview/asset-id
```

The `asset-id` should be the ID used by Asset Manager e.g. `597b098a759b743e0b759a96`, since it persists for the lifetime of the asset, even if the original file is replaced.

### Step 4

Change existing attachments (in Whitehall) to use the new CSV Preview. This will involve republishing all Whitehall documents that include a CSV preview link.

Once this is done, we can remove some of the config for [the `assets` domain](https://github.com/alphagov/govuk-puppet/blob/51d7f7b648e8fde5aae3adfb774ec3bca6325bd8/modules/router/templates/assets_origin.conf.erb#L69-L74) that supported the legacy feature ([`gov.uk` routing](https://github.com/alphagov/government-frontend/blob/dcbc563030c470e6242d6432896d84feebb2138b/config/routes.rb#L14) remains). We can also delete the code for the legacy feature.

> We may want to add redirects for the old preview URLs in Whitehall, if they continue to receive lots of traffic after all the 'View Online' links have updated.


## Rejected proposals

### Use a top-level prefix for the routing (e.g. `/preview/:base_path/:attachment_id`)

This would involve registering a new `/preview` prefix route in [router][router], which would set the backend (rendering app) to Government Frontend for all paths beginning with that route.

- This involves less effort than individually managing lower-level routes for each attachment preview. However, because we don't have any knowledge of these routes, we can't help the user if the URL they enter is invalid; this could happen when the asset is removed, or the parent document changes e.g. unpublished, redirected.

- Using a top-level prefix for CSV Preview is at-odds with the behaviour of other top-level prefixes (`/info`, `/api/content`), since it only works for specific URLs, and doesn't apply to GOV.UK content in general.

### Improve the feature in Whitehall (frontend)

This would involve rewriting the existing CSV Preview feature so that it can work for documents published elsewhere, instead of being coupled to the attachment model in Whitehall.

> We could make the feature work for attachments published by others apps, using the proposed URL structure, which gives us the parent document and the `asset-id` of attachment being previewed.

- This would mean continued reliance of the Whitehall (frontend) codebase and the `/government` prefix route, which has been identified as [tech debt][government-prefix].

- Not using specific routes for each attachment preview means we won't be able to do things like automatic redirects (if the base path of the parent document changes).

### Using sub-routes of the parent document for the routing

The Publishing API supports any number of `routes` for a content item. Normally, this will just be a single route, equal to the `base_path` of the content item. We could add an extra route or routes to support CSV Preview.

> Any additional routes that exist (and which are not redirects) will use the same rendering app as the 'main' route. This fits with the proposal to re-implement CSV Preview in Government Frontend.

> We could use [a prefix sub-route, or specific sub-routes for each attachment](#appendix-sub-routes). Using a prefix sub-route is less effort, but the behaviour is ambiguous if an attachment is not found or associated with the document.

- This would have a lower implementation effort for individual publishing apps, as opposed to creating a separate content item for each attachment preview, which could get out-of-sync with the parent document.

- Most of the lifecycle management, such as unpublishing and redirects, would be done by the Publishing API. However, we would need to address a number of issues with sub-routes in the Publishing API:

  - Publishing API does not clean up sub-routes when they are no longer present in the content item. It _will_ handle redirects for them if the parent base path changes, but that's it.

  - Publishing API does not propagate changes in document state to its sub-routes. For example, a remove/redirect on the parent document does nothing to its sub-routes.

- It's surprising to see routes that aren't related to the actual content item being defined as part of the content item itself. This would be a new pattern for GOV.UK, which someone working on the feature would need to learn.

### Implement the feature in Asset Manager

- Asset Manager has direct access to the CSV attachment, whereas other apps need to download it. Since Asset Manager also 'owns' the attachment, it seems reasonable for it to support preview for attachments.

- It would be hard to reproduce the 'header' section of the preview page, since Asset Manager does not store data about the parent document, and we have no precedent for an `assets` URL to contain such data, either.

- Rendering a CSV preview page would break the convention of Asset Manager being an API-only app. We expect that getting Asset Manager to render pages would be a relatively large/complex solution to the problem of this RFC.

### Implement the feature in a new app

This is a variant of the proposal to reimplement the preview capability in Government Frontend. Instead, we would create a new app dedicated to previewing attachments.

- Using a separate codebase would allow us to extend the preview feature to support other file types.
- Creating a new app would also be a much larger change, and increase the complexity and support burden of GOV.UK.

## Appendix: Sub-Routes

- Publishing API payload with a prefix sub-route

  ```
  routes: [
    { path: "#{document.base_path}/preview", type: "prefix" }
  ]
  ...
  ```
- Publishing API payload with specific sub-routes

  ```
  routes: [
    "{ path: #{document.base_path}/preview/#{attachment1.asset_id}", type: "exact" },
    "{ path: #{document.base_path}/preview/#{attachment2.asset_id}", type: "exact" },
  ]
  ...
  ```
