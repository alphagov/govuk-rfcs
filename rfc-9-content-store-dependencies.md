## **Aims**

An ideal of the "publishing 2.0" design is that frontend apps should need to make only a single call to the "content store" to get all the information they need to render a particular page.&nbsp;This is not always possible: for example, for a search results page the set of queries which users might enter is essentially unbounded, and information about the whole site is needed to present the result pages.

Therefore, in some cases (eg, finders, search pages) the frontend app might need to make a separate call to a "search api" (currently rummager), but this should only be necessary where there's an unbounded, user-generated, set of options to be displayed, and pre-calculating all the pages is implausible or impossible.

A separate aim is that "publishing" apps should be decoupled from the frontend world; all they should need to do is keep the content store updated with information about the pages they "own".

## **Problem**

In the "publishing 2.0" design as currently being implemented, it is currently difficult to model dependencies between pieces of content. &nbsp;Some examples:

- govspeak can have links to "contacts" embedded in it. &nbsp;When the govspeak is rendered to HTML, the referenced contacts need to be looked up to have information from them embedded in them. &nbsp;If those contacts are later updated, all pieces of govspeak which referenced that HTML need to be updated.
- when building the search index from the content store, we need to store the titles, acronyms, etc of organisations (and topics, and several other fields) in the search index. &nbsp;If these are updated (eg, an organisation slug or title or acronym changes), all documents linked to that organisation need to be updated.

Other related problems:

- The publishing tools are currently being encouraged by the design to pre-render HTML and store that in the content store. &nbsp;This is additional complexity, makes them slower to republish their content, and I think is assigning an inappropriate responsibility (rendering HTML to be shown) to the publishing tools, which ought to be outputting semantic information which can then be rendered into multiple forms.
- Most frontend apps will end up simply taking a response from the content store, reformatting it into HTML, and wrapping standard headers and footers around it. &nbsp;This would be much cleaner done at publishing time, storing the statically rendered output in pure HTML form (and then pushing this to mirrors, and possibly even to cache nodes), rather than using CPU time to render it repeatedly (and incurring the corresponding latency). We can't easily do this currently because there is no way to be confident that we'd update the generated HTML when relevant dependencies change.

## **Proposal**

Split the content store into two parts:

- **Publisher content store**. &nbsp;Publisher apps would continue pushing to this, in much the same way as presently, except that:
  - Apps would only push "semantic" information - eg, push raw govspeak, rather than HTML.
  - Apps would be responsible for populating a newly introduced "dependencies" field, containing the content-ids of any other documents which this document depends on. &nbsp;For example, if there was a piece of govspeak with a link to a contact, the dependencies field would list the content-id of that contact.
    - The dependencies field might be grouped into "types" of dependencies (like the links field), or might not need to be.
    - It might even obsolete the "links" field, but I think there may still be uses for declaring such dependencies differently.
    - It might be appropriate to declare which fields in the dependency are relevant. &nbsp;Eg, if only the "title" and "base\_path" fields of a contact are needed for rendering links, this could be declared.  
  - The "content ID" would be the primary key in this content store.  
  

- **Frontend content store**. &nbsp;Frontend apps would read the information needed to render a page from this:
  - Often this would simply be a single, rendered, HTML field, which the frontend app would use slimmer and static to wrap with standard headers.
  - For pages like finders, there would be rendered chunks of HTML, which the frontend app would add the appropriate dynamically rendered content to based on calls to other APIs (the search API, in the case of a finder).
  - The "base path" would be the primary key in this content store.

The obvious question is how these two parts would be connected. &nbsp;I suggest:

- Use a robust messaging framework to listen to changes (we could continue trying to use RabbitMQ, or try another technology like Apache Kafka which is more suited to this design but which we have less experience of).  
  
- The "publisher content store" would use a database table to record the declared dependencies between documents.  
  
- Whenever a document was published, the "publisher content store" would put several messages on the queue:
  - one message for the document that was just published.
  - also, one message for each document that has declared a dependency on the document that was published.
These messages would contain full details about the document that was published, and also about all the declared dependencies. &nbsp;If we allow fields to be associated with dependencies, only the declared fields for dependencies would be included here.  
  
- We would add a new class of apps which listen to the "publisher content store" message queue. &nbsp;Let's call these " **presenter**" apps. &nbsp;A presenter app would be declared for each type of document, and be responsible for taking the "semantic" information from the "publisher content store", together with all its dependent documents, and building the HTML to be shown for that page. &nbsp;The output of the presenter app would then be sent to the "frontend content store". &nbsp;Other information would also be stored in the frontend content store, to inform analytics, render other formats (eg, PDFs), etc.  
  
- The "frontend content store" could be a very simple "key value" store, since it only needs to store a blob of information for each base path, and return that on demand to the frontend app.

The search indexer would listen to the output for the "publisher content store" message queue, which would have all the semantic information needed.

## **Migration**

This is all very well, but how would we get to here from what we have currently (ie, a mostly implemented content store, with url-arbiter, content-register, schemas, some frontend apps, etc).

Suggestion:

- Existing content store becomes the "publisher content store".
- Extend existing content store to support a "dependencies" top-level field.
- Make a new message queue output which contains the raw "storing" type information, but wraps that in a top-level object together with information from dependencies.
- Build a new "frontend content store", which need do little more than be an efficient "key-value" store.
- Build a framework for implementing presenter apps which listen to the queue and publish to the "frontend content store"
- Define schemas for the output of the presenter apps, which the frontend content store checks when content is sent to it.

**Other thoughts**

Things like PDFs for multipage formats could be rendered by a presenter app for a page with the appropriate dependencies&nbsp;

The frontend and backend schemas become entirely decoupled in this architecture: the presenter apps are free to do whatever transformations they desire.

The "publisher content store" only deals with data which is valid according to "backend" schemas.

The "frontend content store" only deals with data which is valid according to "frontend" schemas.

&nbsp;

&nbsp;

