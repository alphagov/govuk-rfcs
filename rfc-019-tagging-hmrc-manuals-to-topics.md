## **Problem**

GOV.UK runs an API endpoint for HMRC manuals. &nbsp;This works by allowing HMRC to submit manuals and updates to the manuals to the API, and forwards these on to the publishing API, and to Rummager (for search).

There is currently no way for HMRC to tag manuals to topics (ie, the hierarchy which now lives under&nbsp;[https://www.gov.uk/topic/).](https://www.gov.uk/topic/).)&nbsp;This means that manuals cannot appear on these pages, which will make them hard for users to find.

Long term, the "Finding Things" team is planning a rework of the tagging system, which will probably involve making a central place to manage tagging. &nbsp;Currently, however, the only place that topic tags can be applied to content is in "Publisher" and "Whitehall Publisher" - content which isn't produced by these publisher tools cannot be tagged to topics.

A further problem is that, even if the HMRC-manuals-API application sent topic tag&nbsp;information to Rummager and to the publishing API, the "Collections" frontend uses the old-world "content-api" to determine which content is tagged to a topic.

**Proposal**

Rather than update content-api to know about HMRC manuals, and allow tagging to them, we will update Collections to use Rummager to get the list of content in a topic, rather than Content-API. This should be low-risk, because it's what Collections already uses to display the "latest" feed for a topic.

Steps:

1incompleteCollections reads list of content tagged to a topic from rummager instead of content api (for serving the main topic page - it already does this for latest feeds).2incompleteStore a mapping from "manual\_slug" to a list of "topic page" content ids in a file in HMRC manual API. &nbsp;This will be updated by developers, based on tagging assignments&nbsp;from HMRC.3incompleteUse this mapping to populate a "links" field to send to the publishing API for the overall "manual" documents.4incompletePut the "sending to rummager" part of HMRC manuals API into a background worker; only the sending to the "publishing API" will be synchronous.5incompleteIn this background worker, when sending a manual to rummager, first make a call to content register to convert the content ids for the topics to slugs, and then populate the document sent to rummager with these topic slugs.6incompleteAdditionally, we need to update the HMRC Manuals API to send changenotes to rummager, so that the "latest" feed for topic pages will display the latest change note. (There is prior art for this - publisher and whitehall publisher send changenotes to rummager.)7incompleteAlso, we need to make sure that long changenotes are truncated appropriately when displayed in latest feed (in collections app)
## Problems

This&nbsp;makes the way Collections gathers the content links for topics&nbsp;different to the way it does them for mainsteam browse pages. &nbsp;We'll either have to refactor Collections to do this fetching differently for mainstream browse, or add full information on which mainstream browse pages content is tagged to to the search index (currently, search only knows about the "first" mainstream browse page that content is tagged to, but some content is tagged to multiple mainstream browse pages). &nbsp;I suspect that refactoring to continue serving mainstream browse from the content-api will be the least work for now.

&nbsp;

&nbsp;

