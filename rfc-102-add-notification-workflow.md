# A 'notify' workflow step in publishing pipeline

## Summary

Email notifications are currently sent to relevant subscribers only when content is published with a major update.

We've identified a use case where the significance of _organising_ content after it has been published may warrant an email notification.

## Problem

We have a high profile use case with the [business readiness finder](https://www.gov.uk/find-eu-exit-guidance-business) where the facet-tagging workflow step is deemed significant enough to warrant notifying subscribers via an email alert.

Departments wish to notify users that new items of content from across GOV.UK have been included in the results for this finder. This is partly a consequence of tagging content after it has been published, but also in part due to the process of writing and reorganising guidance at pace.

Republishing content for the purposes of notifying users is possible but this seems pollutive given the workflow event is (re)categorisation.

The current (temporary) [tagging notification mechanism uses a direct HTTP request between Rummager and Email Alert API](https://github.com/alphagov/rummager/blob/master/lib/indexer/workers/metadata_tagger_notification_worker.rb#L11-L20).

The current (temporary) [metadata tagging implementation is moving to Content Tagger](https://github.com/alphagov/content-tagger/pull/884), the publishing pipeline will handle [tagging via links](https://github.com/alphagov/govuk-content-schemas/commit/071731cb08e8c9c8956a70769748c979f762cf44).
The current email tagging notifications will not be triggered once this has moved.

## Proposal

- Publishing API supports a 'notify' endpoint and sends a distinct message type downstream for Email Alert Service/API consumption.
- Content Tagger UI supports an explicit 'notify users of these changes' workflow choice, defaulting to a no-op.
- Users can opt out of this type of notification as they may only wish to receive updates for publishing events.
