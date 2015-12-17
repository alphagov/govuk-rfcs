## Related RFCs

- [RFC 32: Responsibilities of the components in the Publishing Pipeline](https://gov-uk.atlassian.net/wiki/display/pubplatform/RFC+32%3A+Responsibilities+of+the+components+in+the+Publishing+Pipeline)
- [RFC 39: Embedded relational content in govspeak](https://gov-uk.atlassian.net/wiki/pages/viewpage.action?spaceKey=GOVUK&title=RFC+39%3A+Embedded+relational+content+in+govspeak)

## Problem

When content items are presented to users, they can contain information from other content items. For example, an organisation might embed/inline information about a contact.&nbsp;Both the organisation and the contact are separate content items and have separate life-cycles. When the contact is updated, the information on the organisation page should reflect this.&nbsp;At present, this information is looked up at request time and separate calls are made to the database. This slows page load times down and causes additional load on our servers.

## Proposal

Introduce a Dependency Resolution Service that operates within the Publishing Pipeline.

### Key responsibilities

1) Keep track of content item dependencies

2) Automatically update content items whose dependencies have changed

### Change to architecture

TBC

- Should this sit in between the publishing api and the content store?
- Should this be a separate service that the publishing api speaks to?
- Should this be an additional responsibility of the publishing api?

&nbsp;

TODO - requires further discussion

&nbsp;

&nbsp;

