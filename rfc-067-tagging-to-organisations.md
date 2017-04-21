## Problem

Historically, we've had "organisation tagging" on GOV.UK, but it's a bit muddled. In particular, the value of "organisations" in the content store means different things for different publishing apps.

## Model

There will be three organisation tagging options for any page on GOV.UK:

**Primary publishing organisation**

This is the publisher, or "owner" of the page.

**Additional publishing organisations**

In cases when there's more than 1 organisation that has worked on the content.

**Related organisations**

The content is related to these organisations.

## Implementation

- The content store & will expose the three organisation link types separately
- The search API will&nbsp;expose the three organisation link types separately, but also expose a compound field that contains all organisations
- We'll send the three types as separate dimensions to analytics, but also a compound field that contains all the organisations

## Usage

- Survey team can use primary publishing org from the search API to show breakdown per org
- Content performance manager can use the primary publishing org to show ownership
- Content transformation will use the&nbsp;primary publishing org to assign content
- We'll use all the organisations combined to do facetted search

## Mapping

**WHITEHALL**

- The first lead org is the primary publishing org
- The other lead orgs become the additional publishing orgs
- The supporting orgs become the related orgs

**PUBLISHER**

- The primary publishing org will be **Government Digital Service**
- The current "Organisations" become&nbsp;related orgs

