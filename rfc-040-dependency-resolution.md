## Related RFCs

- [RFC 32: Responsibilities of the components in the Publishing Pipeline](https://gov-uk.atlassian.net/wiki/display/pubplatform/RFC+32%3A+Responsibilities+of+the+components+in+the+Publishing+Pipeline)
- [RFC 39: Embedded relational content in govspeak](https://gov-uk.atlassian.net/wiki/pages/viewpage.action?spaceKey=GOVUK&title=RFC+39%3A+Embedded+relational+content+in+govspeak)

## Problem

When content items are presented to users, they can contain information from other content items. For example, an organisation might embed/inline information about a contact.&nbsp;Both the organisation and the contact are separate content items and have separate life-cycles. When the contact is updated, the information on the organisation page should reflect this.&nbsp;At present, this information is looked up at request time and separate calls are made to the database. This slows page load times down and causes additional load on our servers.

## Proposal

Track content item dependencies and update dependent content items when content items are written to the content store. This would be the responsibility of the content store.

### How will dependencies be denoted?

We will add an optional _dependencies_ key to the default content item schema:

```
dependencies: ["content-id-1", "content-id-2"]
```

```
 
```

&nbsp;

### How will this information be delivered to front-end apps?

The response from the content store will contain the dependent content items:

&nbsp;

&nbsp;

&nbsp;

