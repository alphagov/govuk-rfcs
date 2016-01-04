## Related RFCs

- [RFC 32: Responsibilities of the components in the Publishing Pipeline](https://gov-uk.atlassian.net/wiki/display/pubplatform/RFC+32%3A+Responsibilities+of+the+components+in+the+Publishing+Pipeline)
- [RFC 39: Embedded relational content in govspeak](https://gov-uk.atlassian.net/wiki/pages/viewpage.action?spaceKey=GOVUK&title=RFC+39%3A+Embedded+relational+content+in+govspeak)

## Problem

When content items are presented to users, they can contain information from other content items. For example, an organisation might embed/inline information about a contact.&nbsp;Both the organisation and the contact are separate content items and have separate life-cycles. When the contact is updated, the information on the organisation page should reflect this.&nbsp;At present, this information is looked up at request time and separate calls are made to the database. This slows page load times down and causes additional load on our servers.

## Proposal

Track content item dependencies and update dependent content items when content items are written to the content store. This would be the responsibility of the content store.

### How will dependencies be denoted?

 key to the default content item schema:&nbsp;

&nbsp;

### How will this information be delivered to front-end apps?

The response from the content store will contain the resolved dependencies:

&nbsp;

Note: We could make it so that this key is called "dependencies" and it instead replaces that portion of the document.&nbsp;This is an implementation detail we can discuss later.

### Which fields will be included in the resolved\_dependencies?

These fields will be specified in the content schemas.

There will be a default set of attributes that applies for to all dependencies (such as title).

You will be able to customise this on a per format basis.

### When will dependencies be resolved?

Dependencies will be resolved when writes are made to the content store.

A query will run against mongo to find all content items that depend on the content id of the incoming request.

The&nbsp;_resolved\_dependencies_ of these content items will be updated to include the updated content item.

### What about dependencies of depth greater than 1?

Not supported.

### What about search indexing?

TBC

### What if a content item has lots of dependencies, won't the documents be huge?

Potentially yes. We might only include select fields in the _resolved\_dependencies_ such as title, description, etc.

 property.

### How would I annotate dependencies with additional metadata?

This would be placed elsewhere in the document. Perhaps in the details hash.

### What about rendering pages that use reverse dependencies?

We're going to tackle this separately. This should be easier once we're tracking the dependency graph.

&nbsp;

&nbsp;

