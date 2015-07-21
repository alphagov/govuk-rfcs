## **Problem**

GOV.UK currently supports various ways of associating extra information with&nbsp;documents; loosely speaking, these are things which might be thought of as&nbsp;tags.

We need to be able to associate tags with documents in a much more flexible way than we currently can.

FIXME - write up detail

## **Proposal**

We draw a distinction between two types of tag:

- Information which is part of the "core" of a document. This is things like "content type", "template", "is\_political?", "publishing government". If we want a fancy name for this, it would be "intrinsic tags".
- Information which is associated with the document. This is things like "topic", "mainstream browse category", "policy", "related links", "needs". The fancy name for this would be "extrinsic tags".

Intrinsic tags would be considered as part of the content of the document, follow the same workflow and review processes as the rest of the content, and probably be stored in the "details" section (or other special-purpose fields) in the content store.

Extrinsic tags will be stored in a separate system, which will be centralised (ie, not app-specific), but. &nbsp;It is possible that this system would be built by extending the existing "content register".

FIXME - write up detail

&nbsp;

&nbsp;

