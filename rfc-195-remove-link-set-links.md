---
status: proposed
implementation: proposed
status_last_reviewed: 2026-07-20
---

# Remove link set links from Publishing API and publishing applications

## Summary

Publishing API sits at the heart of the publishing infrastucture. It allows documents to link to others, to enable related links or other similar content to be displayed alongside each other on the public website.

The documents are stored as editions, so it is possible to have both a live edition and a draft edition (which is used to preview the document). Publishing apps send the content as a `PUT content` request, which makes the content appear on the draft site. They then make a `POST publish` request to make that content live.

But there are two ways of adding links:

- One of these are called "edition links", and these work like the rest of the content and are sent in the same payload, so they only go live when the publisher clicks publish.
- The other are called "link set links". These are associated with the document, not the edition, so go live as soon as a publisher adds them to the document (not when they publish the draft).

## Problem

The existence of two types of links has multiple consequences:

- It's a bad user experience: publishers think they are adding content to a draft document, but it appears live on the site immediately.  This has partly been mitigated by changing the UI in the publishing apps to make this clear, but it's far from ideal.
- It makes the link expansion code in Publishing API very complicated and difficult to understand. Developers are not keen on making changes because of the complexity. This became a prominent issue when we attempted to implement a GraphQL API, as we needed to support both types of link, again, making this code very complicated.
- The difference in features between the two types of links makes onboarding difficult as the difference is hard to conceptualise, for both developers and other roles.
- Edition links were only partly implemented, probably because of the complexity of the code. They don't currently support multi-level links, so you can't represent things like the taxonomy as edition links. This caused issues when the Whitehall team wanted to do that, as they needed to find a way of working around this limitation. See [RFC-188](https://github.com/alphagov/govuk-rfcs/pull/188).

This has been recorded as [tech debt](https://gov-uk.atlassian.net/browse/PTD-164).

Link set links are used by the following publishing applications:

- Collections Publisher
- Content Tagger
- HMRC Manuals API
- Mainstream Publisher
- Manuals Publisher
- Search API (limited only to a rake task that publishes static content related to search)
- Service Manual Publisher
- Specialist Publisher
- Travel Advice Publisher
- Whitehall

## Proposal

We are proposing to remove the usage of link set links from all publishing applications. This will then allow the code for link set links to be removed from Publishing API.

## Work required to support this RFC

### Remove link set links from all publishing applications

TODO: pending a discovery

### Remove link set links from all Publishing API content schemas

TODO: pending a discovery

### Remove endpoints to add link set links to content in Publishing API

TODO: pending a discovery

### Remove link set links from link expansion code in Publishing API

TODO: pending a discovery
