## Related RFCs

- 
- 
- 

## Related Discussions

- [https://github.com/alphagov/publishing-api/pull/332](https://github.com/alphagov/publishing-api/pull/332)
- [https://github.com/alphagov/publishing-api/blob/9295bd3de3b6b5395d39784daae0f6cac4f6862b/doc/arch/embedded-content-in-govspeak.md](https://github.com/alphagov/publishing-api/blob/9295bd3de3b6b5395d39784daae0f6cac4f6862b/doc/arch/embedded-content-in-govspeak.md)

## Context

The problem was originally discussed in [RFC 39](https://gov-uk.atlassian.net/wiki/RFC 39: Embedded relational content in govspeak), agreeing on a [rough proposed solution](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+39%3A+Embedded+relational+content+in+govspeak?focusedCommentId=44761325#comment-44761325)&nbsp;but became dormant for ~6 months. This was partly due to dependencies on [dependency resolution](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+40%3A+Dependency+Resolution) and [supporting content items without URLs](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+43%3A+Content+items+without+a+base+path), which did not exist at the time.&nbsp;

Although this document attempts to summarise the issue, it's highly recommended that you&nbsp;[read the original RFC](https://gov-uk.atlassian.net/wiki/pages/RFC%2039:%20Embedded%20relational%20content%20in%20govspeak)&nbsp;for context, before commenting on this one.

The work was [picked up again recently](https://github.com/alphagov/publishing-api/blob/9295bd3de3b6b5395d39784daae0f6cac4f6862b/doc/arch/embedded-content-in-govspeak.md), starting from the previously agreed solution, where concerns were raised and we decided to re-evaluate the proposed solution -&nbsp;It's been a long time this the last discussion:

- Team turnover: many people involved in that discussion are no longer, and some&nbsp;who've joined since.
- Through migration we've learnt a lot about new architecture and hopefully have a better understanding of it.  
  

## Problem

&nbsp;

- embedded dependency: a contact, or attachment
- embedded content layout: the templating logic/markup for rendering an embedded dependency

## Qualities of an ideal solution

- Minimal logic in Frontend applications, with the long-term goal of static frontends
- Content store is a useful API to 3rd Parties
- Avoid bulk republishing?

Dependency&nbsp;

## Proposals

### 1. 100% Publishing: Govspeak rendering, and embedded content, is done on the Publishers (or shared service)

- content-store returns fully rendered HTML, including embedded content  
  

&nbsp;

- embedded dependency changed: publishing app needs to tract when an embedded dependency has changed, and re-render the&nbsp;
- embedded content layout changed: all content items with an embedded dependency using that layout need to re-generate HTML

### 2. Hybrid: Govspeak rendering&nbsp;

- content-store returns partially rendered HTML - no raw govspeak, but placeholders for&nbsp;
- embedded dependency data is included in links hash

&nbsp;

- embedded dependency changed: publishing app needs to tract when an embedded dependency has changed, and re-render the&nbsp;
- embedded content layout changed: all content items with an embedded dependency using that layout need to re-generate HTML

&nbsp;

### 3. 100% Frontend:&nbsp;Govspeak rendering, and embedded content, is done by Frontends (or shared service)

- content-store returns raw govspeak, no HTML, with standard Govspeak syntax for embedded dependencies
- embedded dependency data is included in links hash

sdss

&nbsp;

3.&nbsp;

## Summary

The proposals share some common behaviour that is likely to exist regardless of the proposal

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

