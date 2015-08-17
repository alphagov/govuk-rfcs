## **Problem**

The current content-store architecture requires that the full information about a piece of content is sent by the publishing app. &nbsp;This information currently includes tag information (eg, tagging of content to topics, mainstream browse pages, etc).&nbsp;This requires that each publishing application models tagging of content to topics in its own database, and then forwards this information to the content-store. &nbsp;It also requires that all changes to the tagging involve going through the publishing application.

This turns out to be a problem for topic / browse / policy taggings, because it is often necessary to do things such as bulk tagging, or adjusting tagging. &nbsp;It needs to be possible to change the tagging of a document from a central tool, to support bulk tagging. &nbsp;It also needs to be possible to build a centralised review system so that subject matter experts can moderate all use of particular tags.

### Types of tags

We can draw a distinction between two types of tag:

- Information which is part of the "core" of a document. This is things like "content type", "template", "is\_political?", "publishing government", "primary organisation" (ie, the organisation publishing the content). If we want a fancy name for this, it would be "intrinsic tags".
- Information which is associated with the document. This is things like "topic", "mainstream browse category", "policy", "related links", "needs", "relevant organisations" (ie, organisations which are relevant to the content). The fancy name for this would be "extrinsic tags".

Intrinsic tags would be considered as part of the content of the document, follow the same workflow and review processes as the rest of the content, and probably be stored in the "details" section (or other special-purpose fields) in the content store.

Extrinsic tags will be stored in the "links" section, and be able to be updated independently of the workflow for the rest of the content. &nbsp;It is best to think of these tags as being applied to the document in general, rather than to a particular version of the document.&nbsp;

**Proposal**

This RFC proposes moving the implementation of the "links" feature out of the content store, and into a separate "links-store". &nbsp;This change would be hidden from frontend applications - they would still receive the same combined information. &nbsp;Publishing applications would be able to use a new API to set the links for a document without affecting the rest of the stored content item.

### Publishing applications

When editing a document, publishing applications will allow editing of tags for the document. &nbsp;The interface for this will be the same across all publishing applications (this will probably initially be implemented by writing a Gem to encapsulate the interface code. &nbsp;In future, a centrally hosted component would be an even better way to encapsulate this). &nbsp;To support this, publishing applications will need the following features from the central store apps:

- Fetch a list of all available tags from content-store (to populate selection boxes, etc). &nbsp;This will be a new "bulk" fetch endpoint on the content store - perhaps something like "GET https://content-store/bulk?format=topic", and would return a list of matching content items. &nbsp;This list&nbsp;_must_ include tags which are in "draft" state - thus, perhaps this should be done by providing an endpoint on publishing-API specifically for this purpose, which routes to the draft content store.  
  
The response must also include the content-IDs of items (which is not currently included in the response for GET requests to content-store). &nbsp;For simplicity, I suggest that we should change the content store GET endpoint to always return the content ID of items.  
  
In order to reduce response size and give reasonable performance, it will probably be necessary for this bulk endpoint to provide a way to specify a subset of fields to return (eg, to make the endpoint only return the "title" field, or only the "parent" field from within the "details" hash). &nbsp;For populating the selection boxes, the "links" field values wouldn't be needed in the return value for this bulk endpoint.  
  
- Fetch the currently applied tags from the links-store (to set the initial selection in selection boxes - tag information will no longer be persisted in publishing apps). &nbsp;This information is almost what is already provided from a content-store GET request for a content-item, except for two things: the response must include the content-ids for the items, and must also include items for which the content-id doesn't resolve to a content item (yet). &nbsp;For this reason it is probably best to make a brand new API for getting the links for a content item in "raw" form.  
  
- When saving a content item, the links may be sent together with the content (ie, using the current API), or may be sent independently from the content (using a new API). &nbsp;Sending the links independently from the content might be done using a PATCH HTTP verb. &nbsp;The publishing API would route these requests to the links-store and content-store as appropriate. &nbsp;Question: would it be simpler and better to require that the links are always sent independently of the rest of the content - ie, to have a separate API for each of these?

Publishing applications will make it clear to users that changes to the tags are applied immediately, rather than being part of the rest of the tagging workflow. &nbsp;We will do design and user-research work to ensure that users understand this - perhaps by making the tagging section be separated into a different part of the publishing tool interface (separate tab, or similar), and with appropriate messaging.

Note: topics have a hierarchy, and information on this hierarchy is needed to populate selection boxes for topics appropriately. &nbsp;This is probably best implemented by making collections-publisher populate each "topic" content-item with details of its parents, stored in its details hash (rather than by trying to expand this hierarchy dynamically when fetching the topic content-items). &nbsp;This is mostly already implemented in collections-publisher anyway, and since this logic is specific to only one format of document, it is desirable to keep it out of the central stores.

### Central tagging tools

Like publishers, a central tagging tool will make use of the same endpoints for getting lists of all available tags, and for getting the tags applied to a content item. &nbsp;A central tagging tool will never update the content-item; it will only use the API method for updating the stored links.

### Versioning

The "links" content will be updated independently from the rest of the content item. &nbsp;Therefore, when we are thinking about versioning support for the content store, the "links" content should be versioned independently of the rest of the content item. &nbsp;This becomes important for avoiding conflicts - a central tagging tool may make changes while a piece of content is in draft state, for example, and should not be affected by this (and nor should the publishing tool with the content in draft state be affected by it).

### Frontend API

A new "frontend API" layer would be introduced (let's assume this will be an application, but it might be possible / better to implement it as a Gem). &nbsp;This will be responsible for making API calls to links-store and content-store to produce the single view of a piece of content that frontend applications want, and will be the only part of the system that frontend applications call.

The process would roughly be:

- frontend-API gets a request for item X
- frontend-API requests the item X from the content-store
- in parallel, frontend-API requests the links for item X from the links-store. &nbsp;The response to this request will be the unexpanded links representation (ie, a hash of lists of content-IDs).
- frontend-API then makes a bulk request to the content-store for the items in the links-store response, asking only for the fields needed for the expanded links response.
- frontend-API puts all the information together, and returns the result.

The frontend-API could be expanded in future to support things like progressive degradation (eg, still serve the main content if the tagging system is broken for some reason).

### Whiteboard notes from meetings

&nbsp;

&nbsp;

&nbsp;

