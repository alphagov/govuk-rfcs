## Problem

Terminology:

- "document" refers to a collection of content items with the same content id
- "content item" refers to a version of a document represented by a row in the Publishing API content\_items table
- "content" refers to the data, generally words, that an editor has written and wants to eventually publish for users
- "links" refers to other documents or tags that are connected to a document via the links hash

Publishing API currently stores a single set of links (a LinkSet) per content\_id. It does not have a way to distinguish between links for a draft or live version of a document. This leads to publishing apps only sending the full set of links for a document when it is published, so as not to leak details about the draft of a document. This further leads to draft documents not being accurately previewable, as it may not have the correct links to organisations or ministers.

The original design of the current system was based around Finding Things' requirement to be able to update links at any time without needing to go through the publishing workflow. For example, a Detailed guide on Whitehall might need to be bulk-tagged as "Tax". Co-ordinating this bulk tagging with publishing of content would have been unworkable.

Full link versioning and integration into the publishing workflow is still not a requirement of the Publishing API. The main requirements are:

- Bulk tagging can occur and be applied to documents instantly without waiting for a publish event, or disrupting existing publishing workflow
- Publishing apps can manage links related purely to content and not taxonomy/IA. For example, the minister who gave a speech
- Publishers can preview documents from draft-content-store that have the eventual links they're setting in their publishing app
- Fully migrated publishing apps can store the intended links for a draft document in the Publishing API, and later edit them before publishing. This is a requirement for complex publishing apps becoming fully migrated, such as Government Publisher (Whitehall) and Mainstream Publisher

## Proposal

Publishing apps should stop using the PatchLinkSet command to manage their links. This should be used only for tagging operations, mostly by the Finding Things team. Instead, publishing apps should send content-related links using the PutContent command at the same time they send the actual content.

- PatchLinkSet will work as currently. It will instantly update the links for both the current live and draft versions of a document (if they exist), and send the updated content items to the correct content store.
- PutContent with links will update only the link types supplied for the draft item only, and not touch link types not supplied in the payload.
- Publish will copy the draft links wholesale&nbsp;from the current draft to the new published version.
- DiscardDraft will copy the published links wholesale&nbsp;from the current published version back to the draft version.
- Dependency resolution needs to be aware of whether it's operating on draft or live content, and use the correct set of links for both dependency resolution itself and link expansion.

This requires that the different types of links are split into two different categories, content links and tagging links. Content links will always be managed by the publishing app along with the publishing workflow and will be sent with PutContent. Tagging links can be managed outside the publishing workflow and are provided by PatchLinkSet. For example, the "ministers" link type is set by Whitehall and is a content link, whereas "taxons" are (currently) set by Content Tagger and are tagging links.&nbsp;

The split of these into categories could be codified in the Content Schemas. Each format that has content links could gain an additional "content\_links.json" file which gets merged into the main "schema.json" at build-time, and tagging links stay in the existing "links.json".

