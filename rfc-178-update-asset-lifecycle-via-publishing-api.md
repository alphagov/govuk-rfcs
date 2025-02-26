---
status: proposed
implementation: proposed
status_last_reviewed:
---

# Update Asset Lifecycle State via Publishing API Message Queue

## Summary

Currently, each publishing application updates the state of each asset associated with an edition of a document when the edition's state changes. For example, when an edition is published, Whitehall updates the `draft` state of any assets associated with the edition to `false` by making an API call to Asset Manager. This will cause Asset Manager to serve the asset from the live domain. Other publishing applications which support asset uploads, such as Specialist Publisher and Manuals Publisher, make the same API call each time a document is published.

To reduce this duplication and reduce the chatty API connections between the publishing applications and Asset Manager, we could have Asset Manager consume messages placed on RabbitMQ by Publishing API whenever an edition's state is updated. The message processor could then inspect the state of the edition's attachments and images and apply the appropriate updates to the relevant asset states, for example by updating the redirect URL associated with the assets if the edition has been unpublished.

## Problem

GOV.UK publishing has found asset management a difficult challenge in recent history. It has been the source of several incidents and bugs, such as [this high profile incident](https://docs.google.com/document/d/1niSvK0w-BkzHpkqj6-yqcHrRPI4OfYhOfHn5paEQH7Q/edit?usp=sharing) from 2024, and [this extant bug in Manuals Publisher](https://trello.com/c/5LqwCypV). There are two main problems:

1. Each publishing app which supports asset uploads has duplicate code for updating the state of Asset Manager
2. The code for synchronising the state of Asset Manager with the state of Publishing API in the publishing applications is generally very brittle and sensitive to race conditions.

## Proposal

There SHOULD be a single mechanism for updating the state of an asset based on the owning edition's state. This SHOULD be achieved via Publishing API, which will reduce the burden on the publishing applications to maintain consistency between Publishing API and Asset Manager. This will make the data flow consistent with how Search API and Router API are updated, and decouple the publishing applications from Asset Manager.

In this scenario, publishing applications MUST upload binary assets directly to Asset Manager (as per the current process) They MUST send any access bypass information and access limiting information (also as per current process). Asset Manager can set the default lifecycle state for new assets as follows:

```ruby
{
  draft: true,
  deleted_at: nil,
  parent_document_url: nil,
  replacement_id: nil,
  redirect_url: nil,
}
```

After this, publishing applications must continue to include sufficient information about attachments and images in Publishing API payloads to allow Asset Manager to make appropriate state updates. Attachments sent to Publishing API by Whitehall look like this:

```json
{
    "accessible": false,
    "alternative_format_contact_email": "different.format@hmrc.gov.uk",
    "attachment_type": "file",
    "command_paper_number": "",
    "content_type": "application/vnd.oasis.opendocument.text",
    "file_size": 11349,
    "filename": "Amendments_5_to_8_to_Clause_37-Claim_for_relief_on_foreign_income.odt",
    "hoc_paper_number": "",
    "id": "8485786",
    "isbn": "",
    "title": "Amendments 5 to 8 to Clause 37: Claim for relief on foreign income",
    "unique_reference": "",
    "unnumbered_command_paper": false,
    "unnumbered_hoc_paper": false,
    "url": "https://assets.publishing.service.gov.uk/media/67bf19a4750837d7604dbb96/Amendments_5_to_8_to_Clause_37-Claim_for_relief_on_foreign_income.odt"
}
```

Asset Manager's ID for the asset is part of the attachment URL, but we MAY provide it as a separate field so that Asset Manager can easily perform a lookup for the correct asset. We MUST add a deletion marker and the replacement ID (if replaced) to the attachment data to allow Asset Manager to make the correct state adjustments for attachment assets.

Images look like this:

```json
{
  "alt_text": "The launch of the Amelia Troubridge photography exhibition at Getty Images Gallery, London.",
  "caption": "The launch of the Amelia Troubridge photography exhibition at Getty Images Gallery, London.",
  "high_resolution_url": "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/image_data/file/65710/s960_Fanzi-Down.jpg",
  "url": "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/image_data/file/65710/s300_Fanzi-Down.jpg"
}
```

Again, we MAY include the Asset Manager IDs for each image, and we MUST provide deletion and replacement state.

Publishing API already places a message on a RabbitMQ exchange each time an edition is published. We MUST add another topic for updates to draft editions so that Asset Manager can make additional updates to access limiting and access bypass states for draft documents.

Unpublishings look like this:

```json
{
  "analytics_identifier": null,
  "base_path": "/guidance/brexit-guidance-for-individuals-and-families",
  "content_id": null,
  "description": null,
  "details": {

  },
  "document_type": "redirect",
  "first_published_at": "2021-07-01T11:33:00+01:00",
  "links": {

  },
  "locale": "en",
  "phase": "live",
  "public_updated_at": "2022-05-09T12:37:43+01:00",
  "publishing_app": "whitehall",
  "publishing_request_id": null,
  "publishing_scheduled_at": null,
  "redirects": [
    {
      "destination": "/government/collections/brexit-guidance",
      "path": "/guidance/brexit-guidance-for-individuals-and-families",
      "type": "exact"
    }
  ],
  "rendering_app": null,
  "scheduled_publishing_delay_seconds": null,
  "schema_name": "redirect",
  "title": null,
  "updated_at": "2025-01-21T14:44:13+00:00",
  "withdrawn_notice": {

  }
}
```

We MUST add a way to look up assets belonging to unpublished editions so that they can be redirected. We COULD add the asset IDs for each attachment and image to the redirect, or we COULD create a separate `unpublished_documents` topic to handle these events. Incidentally the Search API way of handling unpublishing is somewhat awkward, so a separate topic may be beneficial.

## Implementation

Asset Manager can use the `GovukMessageQueueConsumer` to consume RabbitMQ messages from the `published_documents` topic. Here is how Search API consumes the queue: https://github.com/alphagov/search-api/blob/main/lib/tasks/message_queue.rake.

As mentioned above. We MUST add a new topic for draft documents.

The message processing code MUST be retryable with a backoff. RabbitMQ does not enable such behaviour out of the box, so we COULD write the messages to a Mongo document collection with an ID and then read the messages back in a Sidekiq job. This would be an improvement to the Search API workflow which writes the message directly to the Sidekiq Redis instance, causing the Redis memory to become very full when jobs are building up faster than workers can handle the jobs. Alternatively we COULD provide some job management within Asset Manager itself.

We SHOULD initially restrict the message processor to only process messages where the document has a publishing app of Whitehall. Once we have proven that we can manage asset lifecycle state via Publishing API for Whitehall assets, we can migrate other publishing applications to use the same system.


