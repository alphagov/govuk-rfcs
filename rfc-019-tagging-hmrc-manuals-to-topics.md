## **Problem**

GOV.UK runs an API endpoint for HMRC manuals. &nbsp;This works by allowing HMRC to submit manuals and updates to the manuals to the API, and forwards these on to the publishing API, and to Rummager (for search).

There is currently no way for HMRC to tag manuals to topics (ie, the hierarchy which now lives under&nbsp;[https://www.gov.uk/topic/).](https://www.gov.uk/topic/).)&nbsp;This means that manuals cannot appear on these pages, which will make them hard for users to find.

Long term, the "Finding Things" team is planning a rework of the tagging system, which will probably involve making a central place to manage tagging. &nbsp;Currently, however, the only place that topic tags can be applied to content is in "Publisher" and "Whitehall Publisher" - content which isn't produced by these publisher tools cannot be tagged to topics.

A further problem is that, even if the HMRC-manuals-API application sent topic tag&nbsp;information to Rummager and to the publishing API, the "Collections" frontend uses the old-world "content-api" to determine which content is tagged to a topic.

**Proposal**

Collections reads list of content tagged to a topic from rummager instead of content api (for topic page - already does it for latest feeds)

- makes this different for mainsteam browse pages (but we could add mainstream browse pages to search, or refactor to handle separately)

Store [manual\_slug =\> [topic content ids]] in a file in HMRC manual API  
 - send in links field to publishing API  
 - convert to topic slugs, and send to rummager.  
 - convert to topic slugs by: hardcoding, or querying content register.  
 - live querying content register;  
 - put sending to rummager into a background worker

Send changenotes to rummager from HMRC Manuals API

Make sure longform changenotes are truncated appropriately in latest feed (in collections app)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

