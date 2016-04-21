&nbsp;

&nbsp;

---
status: "IN PROGRESS"
notes: "Closing for comments on Friday 29 April"
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

We propose to leave withdrawing as it is, but simplify the unpublishing workflow by adding&nbsp;a new endpoint,&nbsp;`/v2/content/:id/unpublish`. This will accept a POST with **\<format TBC\>** and move the content item to the correct state and sending the resulting format (gone/unpublishing/redirect) to content-store.

...details...

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

