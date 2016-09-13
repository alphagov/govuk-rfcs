## Problem

Our current system of subscriptions is strictly "taxonomy based", that is, you are only able to subscribe to groupings of content such as [topics](https://www.gov.uk/topic/oil-and-gas/fields-and-wells/email-signup), [organisations](https://www.gov.uk/government/email-signup/new?email_signup%5Bfeed%5D=https%3A%2F%2Fwww.gov.uk%2Fgovernment%2Forganisations%2Fcabinet-office.atom), [document types](https://www.gov.uk/government/email-signup/new?email_signup%5Bfeed%5D=https%3A%2F%2Fwww.gov.uk%2Fgovernment%2Fpublications.atom), [policies](https://www.gov.uk/government/policies/access-to-the-countryside/email-signup) etc. and then receive updates when any content is tagged to a grouping or set of groupings you have subscribed to.

There is [mounting evidence](https://docs.google.com/a/digital.cabinet-office.gov.uk/presentation/d/1XP-ejOSiJJ15FN6jkFWRKUTimdE44T48NXVHeaGky04/edit?usp=sharing) of need for other kinds of subscription such as subscribing to an individual document. &nbsp;There are also kinds of filtering we support in [whitehall finders](https://www.gov.uk/government/publications)&nbsp;like keyword searching and date filtering which are then silently dropped when subscribing to email, though we don't yet have evidence that users need this.

We may want to replace GovDelivery as our subscription (and notification) provider as their system isn't well suited for our current subscription model, and doesn't support more complicated ones. GovDelivery currently costs us [redacted]&nbsp;per month, plus development costs for new features.

## Proposal

We need to either borrow, buy, or build a more flexible subscription system. &nbsp;It should cost less and do more.

### Borrow

We investigated whether there were any open source or GaaP-like solutions available to us.

GOV.UK Notify make sense for providing actual delivery of the emails, but they do not provide a subscription service and have no current plans to.

Government as a Platform are interested in providing a subscription service as part of their offering but have no current plans to.

DXW are building a subscription service for DIT&nbsp;(Department for International Trade (formerly UKTI (UK Trade & Investment))) but it's being driven solely DIT's needs and they don't go further than a taxonomy-based service much like ours. &nbsp;More detail available [on Trello](https://trello.com/c/3aqbP3Av/45-what-subscription-services-are-already-out-there).

GOV.SCOT build an email alert system in the 2000s, however it is mailing list based rather than subscription.

### Buy

We investigated the offerings on the GOV.UK Digital Marketplace (aka G-Cloud).

1. Services related to email are almost entirely standard email hosting, like your usual outlook mailserver type stuff.
2. The second most common email service are "protection" services, such as archiving, anti-virus, anti-spam.
3. The only services which mention membership, subscription and mailing lists are CRMs aka Customer Relationship Management tools. In these cases the emailing is just one small part of a larger business development / sales tool, and they're expensive. It's not clear if they would be at all useable for our purposes, and they'd definitely not be any more useable than govdelivery.

Examples of CRMs are:

- [https://www.digitalmarketplace.service.gov.uk/g-cloud/services/659196316649813](https://www.digitalmarketplace.service.gov.uk/g-cloud/services/659196316649813)
- [https://www.digitalmarketplace.service.gov.uk/g-cloud/services/396986384394288](https://www.digitalmarketplace.service.gov.uk/g-cloud/services/396986384394288)

### Build

With no existing systems available and the (time/money) cost of integrating high regardless, we are likely to need to build a system.

I built [a prototype](https://trello.com/c/hkTE6uI2/10-elasticsearch-proof-of-concept) based on [ElasticSearch's Percolation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-percolate.html) technology. &nbsp;An advantage of using ElasticSearch is that we already use the technology for our site search and so we have plenty of experience and prior art available to us. &nbsp;Costs for running a new ElasticSearch cluster is around £1500/month, and we may get away with just using a new index on the existing cluster.

The intent was to investigate the feasibility of supporting all the possible forms of subscription we've identified; taxonomic, individual document, keyword search, date filter. &nbsp;This allows user research to continue without restriction from the technical side, and when it comes to building the full system we can do so with just the functionality that was shown to be required during user research.

Based on the prototype I am confident that we can support all currently known potential user needs using ElasticSearch Percolation.

For more detail please review the [Trello ticket](https://trello.com/c/hkTE6uI2/10-elasticsearch-proof-of-concept), the [Rummager code branch](https://github.com/alphagov/rummager/compare/percolation), and the [comments thereon](https://github.com/alphagov/rummager/commit/a1f9310b58900f2c1eabe8b74a74db24303002f6#comments).
