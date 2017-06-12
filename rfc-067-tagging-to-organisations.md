# Tagging to organisations (not implemented)

---
**NOTE 2017/06/12**: This PR has not been implemented because of difficulty getting consensus about the semantics of the organisations tags. The only tag that has been added at the time of writing is the `primary_publishing_organisation`, which contains the first "lead organisation" for Whitehall documents.
---

## Problem

Historically, we've had "organisation tagging" on GOV.UK, but it's a bit
muddled. In particular, the value of "organisations" in the content store means
different things for different publishing apps.

## Model

There will be three organisation tagging options for any page on GOV.UK:

- **Primary publishing organisation** This is the publisher, or "owner" of the
  page.
- **Additional publishing organisations** In cases when there's more than 1
  organisation that has worked on the content.
- **Related organisations** The content is related to these organisations.

## Implementation

- The content store will expose the three organisation link types separately
- The search API will expose the three organisation link types separately, but
  also expose a compound field that contains all organisations
- We'll send the three types as separate dimensions to analytics, but also a
  compound field that contains all the organisations

## Usage

- Survey team can use primary publishing org from the search API to show
  breakdown per org
- Content performance manager can use the primary publishing org to show
  ownership
- Content transformation will use the primary publishing org to assign content
- We'll use all the organisations combined to do facetted search

## Mapping

### Whitehall

- The first lead org is the primary publishing org
- The other lead orgs become the additional publishing orgs
- The supporting orgs become the related orgs

### Publisher

- The primary publishing org will be **Government Digital Service**
- The current "Organisations" become related orgs
