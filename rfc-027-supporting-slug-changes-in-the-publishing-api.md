## **Problem**

- slug changes are **costly and increasingly common** for live content
- we also need to handle slug changes for **draft content**

### Slug changes in live content

GOV.UK's existing publishing tools were built upon the assumption that document slugs do not change. This was a helpful simplifying assumption in the early days of GOV.UK and mostly held true. In the rare cases where a published slug did need to change, the cost of manual intervention from a developer to correct the issue was reasonable.

However as GOV.UK has matured, the factors in this trade-off have changed:

- we now have vastly more content on GOV.UK, so although the probability of a slug change per document may be unchanged, slug change requests are much more frequent
- our systems have become more complex over time and the effort involved in performing a slug change manually without introducing errors has increased

If we need evidence of the cost and the frequency of slug changes, we could review the workload of 2nd line support.

### Slug changes in draft content

We have always allowed slugs of draft content to change. This has never been an issue because draft items were contained within a single system, so there was no requirement to maintain consistency between multiple systems representing the same content item.

With the introduction of the 'content preview' system in Publishing API, we now handle draft items whose slugs can change.&nbsp;

The primary identifier used for content items in the publishing API is the&nbsp;`base_path`. Using&nbsp;`base_path` as the primary identifier is based on the assumption that it does not change.

If the slug of a draft content item changes, our only option at present would be to&nbsp;require the publishing application to notify the publishing API of this change so that it can remove the document at the previous slug (publishing API currently does not support deletion of content items).

## **Proposal**

### **Proposal 1: we should assume that slug changes will happen and incorporate this into the design of the publishing API**

The simplifying assumption that slug changes do not happen is no longer serving us.

### **Proposal 2: use content\_id as the primary identifier of content items**

In order to cater for the above change in assumptions, we should use a persistent abstract identifier for content items. We already have such an identifier in the systems, in the form of&nbsp;`content_id`.&nbsp;

Since&nbsp;it's a GUID it can be generated independently and asynchronously by the publishing applications (no need for a central coordinating authority).

All publishing API endpoints should accept&nbsp;`content_id` rather than&nbsp;`base_path`, ie. instead of:

This implies that&nbsp;`content_id` would be **required** &nbsp;for all content items (not an onerous requirement).

In order to transition to this approach there are a few options:

- introduce a set of publishing API endpoints which accept content by guid (e.g.&nbsp;`PUT /content_by_guid/,`&nbsp;`PUT /draft_content_by_guid/` or something similar)
- allow the existing endpoints to detect a slug which looks like a guid and treat it as such. Although slightly hacky, I the chance that a normal slug would match the patter for a guid is extremely low.

#### Benefits of using `content_id`&nbsp;as primary identifier

This will allow the publishing API to understand when the slug of a content item posted has changed. It will then allow publishing API to either:

- disallow the change
- gracefully handle the change by propogating the change to any downstream systems (e.g. router, url arbiter etc). It could even put in place a redirect from the old url to the new url.

Further down the line, if we move to a system where publishing API keeps some kind of 'transaction log' record, this API will allow us to keep a record of the changes of a documents slug over time. Having this data in a single transaction log will mean that we have all the information in one place to verify and enforce consistency in downstream systems.

&nbsp;

## Status of this RFC

This is an early draft, there are probably many things I have missed or not thought about.

- Do you agree with the end goal?
- Do you see any issues with migrating to this?
- Can you see any problems or risks I haven't identified?  

Thanks for reading and for your input!

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

