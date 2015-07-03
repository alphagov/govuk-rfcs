## **Problem**

**Proposal**

&nbsp;

Collections reads list of content tagged to a topic from rummager instead of content api (for topic page - already does it for latest feeds)  
 - makes this different for mainsteam browse pages (but we could add mainstream browse pages to search, or refactor to handle separately)

Store [manual\_slug =\> [topic content ids]] in a file in HMRC manual API  
 - send in links field to publishing API  
 - convert to topic slugs, and send to rummager.  
 - convert to topic slugs by: hardcoding, or querying content register.  
 - live querying content register;  
 - put sending to rummager into a background worker

Send changenotes to rummager from HMRC Manuals API.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

