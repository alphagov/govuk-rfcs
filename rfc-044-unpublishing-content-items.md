&nbsp;

&nbsp;

---
status: "IN DEV"
notes: "Development has started (2nd May, 2016)"
---

## Problem

The workflow around unpublishing and withdrawing content items in the publishing-api is unclear and does not cover all the use cases of the different publishing apps. We need to simplify the processes, while making sure that all current actions are supported.

There are various different types of withdrawal action. They can be grouped as follows:

1. **Withdrawing with a message** : This is used for content that was previously valid but is no longer current. The content continues to display, with the addition of a large message block at the top stating that the content is withdrawn, and it is no longer findable in search. (Whitehall)
2. **Unpublishing with a message** : The content is removed from the site, and an explanatory message is displayed at that URL instead. The message can optionally contain an alternative URL which is displayed as a link, but does not redirect automatically.&nbsp;(Whitehall)
3. **Unpublishing with a redirect** : The page is replaced by an automatic redirect to a different URL. (Whitehall, Publisher)
4. **Unpublishing with a Gone** : The page is replaced by a 410 Gone page. (Publisher, Specialist Publisher)
5. In addition, Whitehall sends a Gone for items that were scheduled to be published but then unscheduled, as long as there is no previously published version, and when non-edition items such as organisations or persons are deleted.

&nbsp;

Proposal

Currently it is up to the publishing apps to send the relevant formats to publishing-api in each of these cases above. This involves sending a new draft item - of the original format updated to include the message for case 1, an Unpublishing item for case 2, a Redirect for case 3 and a Gone for cases 4 and 5 - and then a second call to publish.

We recommend the following steps:

1. **Clarify our language**. &nbsp;We adopted "withdrawing" as a verb in the publishing API when really that should be constrained to occasions when the content remains on the site but is removed from the canon of the current government. &nbsp;Everything else is "unpublishing".
2. **Flag documents as withdrawn** &nbsp;from the publishing app rather than supporting "withdrawn" as a first-class state, so the front-ends can render the appropriate banner. &nbsp;This should be handled the same way when we do "historic" documents.
3. **Refuse to clobber existing documents**. &nbsp;We currently allow gones/redirects to take the place (base\_path) of documents, and vice versa. &nbsp;This provides an in-app way to implement unpublishing (and republishing). &nbsp;We should remove the first case of this functionality and require the existing content to be unpublished via the new endpoints&nbsp;`/v2/content/:id/unpublish` or moved by altering its base\_path and publishing (which automatically creates a redirect). &nbsp;Allowing gones/redirects to be clobbered still makes sense as it is a reclamation of an unused path.
4. **Create `/v2/content/:id/unpublish`** &nbsp;accepting a POST with \<format TBC\>, which returns the content item to draft and creates & publishes the resulting format (gone/unpublishing/redirect). &nbsp;Question: should we autodiscard an existing draft if there is one, or refuse to take action?
5. **Populate gone items** with enough information to render the page seen after unpublishing, which in the case of Whitehall is the reason for unpublishing and/or alternate URL. &nbsp;This page presentation can then be tidied up and standardised across publishers / frontends.
6. **Indicate unpublished state** back to the user. &nbsp;We need to be able to indicate that a piece of content was More thought warranted on this.

&nbsp;

&nbsp;

&nbsp;

