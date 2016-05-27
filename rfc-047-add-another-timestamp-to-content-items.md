## Problem

One of the goals of migration is to make publishing apps use the publishing api as their data store. Publishing apps contain index pages that list all of the content they manage. These index pages are sorted by "most recently updated first" to help users find content they're working on more easily. The publishing api doesn't have a timestamp for this. The closest it has is updated\_at, but this is affected when content is republished. We could insist that republishing must happen in the same order that content appears on index pages, but republishing is often done via sidekiq, which doesn't guarantee message ordering. We also display this timestamp on the index page and it could confuse our editors if it changes as a result of republishing.

## Proposal

Introduce a new timestamp for content items in publishing api that is updated whenever there is a major or minor update, but not on republishes. This field should be called something like 'edited\_at' or 'private\_updated\_at' and is for internal use only. It should not be sent downstream to the content store. Publishing apps then specify this sort order in the request to publishing api when requesting content for the index page.

&nbsp;

&nbsp;

