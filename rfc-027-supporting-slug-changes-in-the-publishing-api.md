## **Problem**

- slug changes are **costly and increasingly common** for live content
- we also need to handle slug changes for **draft content**

### Slug changes in live content

GOV.UK's existing publishing tools were built upon the assumption that document slugs do not change. This was a helpful simplifying assumption in the early days of GOV.UK and mostly held true. In the rare cases where a published slug did need to change, the cost of manual intervention from a developer to correct the issue was reasonable.

However as GOV.UK has matured, the factors in this trade-off have changed:

- we now have vastly more content on GOV.UK, so although the probability of a slug change per document may be unchanged, slug change requests are much more frequent
- our systems have become more complex over time and the effort involved in performing a slug change manually without introducing errors has increased

### Slug changes in draft content

We have always allowed slugs of draft content to change. This has never been an issue because draft items were contained within a single system, so there was no requirement to maintain consistency between multiple systems representing the same content item.

With the introduction of the 'content preview' system in Publishing API, we now handle draft items whose slugs can change.&nbsp;

The primary identifier used for content items in the publishing API is the&nbsp;`base_path`. Using&nbsp;`base_path` as the primary identifier is based on the assumption that it does not change.

If the slug of a draft content item changes, our only option at present would be to&nbsp;require the publishing application to notify the publishing API of this change so that it can remove the document at the previous slug (publishing API currently does not support deletion of content items).

**Proposal**

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

