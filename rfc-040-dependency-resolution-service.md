## Related RFCs

- [RFC 32: Responsibilities of the components in the Publishing Pipeline](https://gov-uk.atlassian.net/wiki/display/pubplatform/RFC+32%3A+Responsibilities+of+the+components+in+the+Publishing+Pipeline)
- [RFC 39: Embedded relational content in govspeak](https://gov-uk.atlassian.net/wiki/pages/viewpage.action?spaceKey=GOVUK&title=RFC+39%3A+Embedded+relational+content+in+govspeak)

## Problem

When content items are presented to users, they can contain information from other content items. For example, an organisation might embed/inline information about a contact.&nbsp;Both the organisation and the contact are separate content items and have separate life-cycles. When the contact is updated, the information on the organisation page should reflect this.&nbsp;At present, this information is looked up at request time and separate calls are made to the database. This slows page load times down and causes additional load on our servers.

## Proposal

Introduce a Dependency Resolution Service that operates within the Publishing Pipeline.

This service would keep track of content item dependencies and provide an API to query this information.

### How would it keep track of dependencies?

Content items currently reference other content items in the links hash.

The dependency resolution service would consider these content items to be its dependencies.

It would store these dependencies as a directed graph in a relational database (details TBC).

### How would applications interact with the service?

TBC

### What would the API look like?

TBC

&nbsp;

TODO - requires further discussion

&nbsp;

&nbsp;

