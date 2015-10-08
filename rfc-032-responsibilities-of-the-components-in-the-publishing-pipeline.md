## **Aims**

This RFC aims to explain the responsibilities of the significant components in the "publishing pipeline."

The hope is that this will promote discussion and help us to align on what each part of the pipeline is for.

It also helps me (Chris Patuzzo) understand the pipeline after just two days of working at GDS.

## **Context**

There are already a number of proposals that deal with components within the publishing pipeline:

- RFC 12: Content store dependencies, and frontend/publishing split
- RFC 24: New tagging architecture
- RFC 31: Requirements for tagging architecture

In order the evaluate these RFCs, it would be helpful if we understood, first, what each of these components should and should not be responsible for.

For example,&nbsp;where does "govspeak" fit in? Which component(s) should be responsible for carrying out the govspeak to HTML transformation?

## **Significant Components**

**Publishing Applications**

There are numerous publishing applications which are used by content editors to produce content for consumption by users.

These applications should provide a user-interface and associated tooling for the editing and previewing of content.

These applications should no longer store their own content. Instead, this will be held by the "Publishing API."

&nbsp;

**Publishing API**

The Publishing API's primary responsibility is to provide "Workflow as a Service".

It provides an API that publishing applications can both read and write to in order to retrieve articles as well as create them.

It pushes content items to the relevant "Content Store" ("draft" or "live") and manages the transition of articles from "draft" to "live."

It should not understand the semantics of the content items themselves. Content items should be "opaque" to the Content Store.

&nbsp;

**Content Store**

The Content Store should hold the "rendered" representation of each content item, ready for consumption by the "Front-End Applications."

It provides an API for both reading content from the store as well as writing content to it.

It should validate that the content it receives is correctly formed and perform sanitisation on it if required.

&nbsp;

**Front-End Applications**

The Front-End Applications are responsible for serving requests to users of the website by reading content from the "Content Store" and rendering it.

They should aim to do as little as possible in order to minimise latency in handling incoming requests.

As much processing as possible should have handled before content enters the "Content Store", rather than it happening at request time in the "Front-End Applications."

## **Where does X fit in?**

**X = Govspeak Transformation**

Many of our publishing applications use "govspeak", which is an extension on Markdown. It provides a human-friendly interface for editing content.

The Front-End Applications should not have to transform govspeak into HTML at request time (see above).

Therefore, govspeak needs to be transformed into HTML **before** it goes into the Content Store.

&nbsp;

Currently, the application immediately prior to pushing content into the Content Store is the Publishing API.

However, the Publishing API should not carry out this transformation either as it should not understand the semantics of content items (see above).

We may be able to relax this rule for highly changeable content, but it would be a blocker to moving in the direction of effectively rendering a static site ahead of time.

Therefore, it may be that we need an extra service / application / thing that sits between the Publishing API and Content Store for content format transformations.

This issue is further complicated by "dependencies" between content items. This is elaborated on below:

&nbsp;

**X = Content Item Dependencies**

Content items can "reference" other content items. An example of this is a "contact" or an "attachment."

For example, in an article, you may want to refer to another article and embed its title and provide a link to it.

Currently, there is some special govspeak syntax for this. The dependent article's id is embedded in the body of the other article.

The dependent article may be republished or change out-of-band to the "dependee" article. If the title of this article is changed, the dependee needs to be updated, too.

&nbsp;

At present, this only happens in the Whitehall application. The resolution of the article's name is resolved at request time by making a separate call to look up this information.

This adds latency to the request and means that we are doing addition processing at request time. Ideally, front-end applications should not do this (see above).

Instead, it would be better to track these dependencies and update the dependee article when one of its dependencies changes.

RFC-12 suggests that these dependencies be tracked and the dependee article be re-published by the Publishing API when this happens.

However, this means that the Publishing API would have to understand the semantics of dependencies between articles and it adds an additional responsibility to this application.

This might be OK, but it could make more sense to handle this separately through some kind of "dependency management" application that tracks dependencies as its sole responsibility.

This is elaborated on further in RFC-24 and RFC-31.

## **Update: 8th October, 2015**

We held a meeting to discuss this further. Here is the whiteboard from that meeting:

&nbsp;

The main realisation was that&nbsp;Govspeak and Dependency Resolution are separate topics and should be considered separately.

There were three proposals for where to do the Govspeak to HTML transformation.

&nbsp;

1) Publishing Applications

The publishing applications would render HTML and send both Govspeak and HTML to the Publishing API.

They'd need to send both in order to allow content editors to work with draft content. The publishing apps no longer hold their own data.

&nbsp;

2) Something in the middle

We could invent something that sits between the Publishing API and Content Store that transforms Govspeak to HTML.

It was noted that neither the Publishing API or Content Store should understand the content payload and should be Single Responsibility services.

&nbsp;

3) Frontend Applications

This is currently what happens now (largely because of the dependencies issue). We could continue to do this, but it does add an overhead to every request.

If we did this, it would mean that the Publishing Pipeline isn't even aware of Govspeak and it's just another field that sits in a content payload.

This effectively pushes the responsibility of transforming Govspeak to HTML onto the applications external to the pipeline. This may not necessarily be a good thing.

&nbsp;

There were a number of questions that we should follow-up on (in no particular order):

1) Where do we sanitise / validate HTML?

2) Dialects?

3) How do we model dependencies?

4) What does dependency resolution?

5) Where do we transform Govspeak to HTML? (this question is the main focus of this topic)

&nbsp;

&nbsp;

&nbsp;

