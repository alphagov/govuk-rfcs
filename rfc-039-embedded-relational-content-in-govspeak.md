## Related RFCs

- &nbsp;(some thinking done, but no activity recently)

## Problem

Whitehall applies some additional [presentational logic](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb)&nbsp;(and [styling](https://github.com/alphagov/whitehall/blob/master/app/assets/stylesheets/frontend/helpers/_govspeak.scss)) on top of [standard Govspeak](https://github.com/alphagov/govspeak). For the most part these [are](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L105-L107) [simple](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L162-L179) [tweaks](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L186-L190) that could probably be merged into Govspeak itself, or continue to stay on the publisher side of the content store.

There are two cases, Embedded Contacts (example) and Embedded Attachments (example), that are more complicated, and blur the lines between publisher and frontend concerns. Contacts and Attachments are slightly different in implementation, but are effectively instances of the same embedding problem, where a representation of secondary information (outside of the document being published) &nbsp;is embedded in the Govspeak output.

The current Whitehall behaviour looks like this:

- An editor adds an embed to their document, and publishes
  - they add the embed syntax (eg, `[contact:1234]`,` !@1`)
  - the document is persisted in the WH database
- The document (fetched from WH database) is rendered by a WH Frontend
  - where the [embed govspeak syntax is parsed](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L133-L143)
  - the embed ID is extracted and a embed record fetched from the Whitehall database
  - an [embed template](https://github.com/alphagov/whitehall/blob/master/app/views/contacts/_contact.html.erb) is rendered using the embed record replaces the embed syntax
  - (govspeak is then cached)
- An editor updates a contact/attachment embedded in the previous document
  - [whitehall keeps a track of embedding relationships](https://github.com/alphagov/whitehall/blob/5631a1722e186b194f4f7bb1f53cd2eb56e48034/lib/dependable.rb#L9-L11)
  - when a dependency embedded in a document changes the govspeak cache is invalidated
  - allow the updated embed record to be used when rendering the govspeak on next request

The qualities of this system that we would like to maintain are:

- When an embedded record is updated the documents which have embedded it are automatically updated
- The embed templates and their CSS/JS live in the same repo, and can be iterated at in tandem.
- Changes to the copy/design of the the embed templates can be applied by uncaching the govspeak of those documents

Considerations and constraints in new world architecture:

- The embedded records may not be owned by the same publishing application, eg, contacts moving to their own publisher
- We may want the same embedding (possibly for the same types) in different publishing apps (eg, embedding contacts in mainstream content)
- We may introduce new types of embedded content
- Frequency of use of contact (8,486 published documents) and attachment (1,320 published documents with callout, 1,864 with inline)&nbsp;embeds
- Frequency of change to design/markup of embed templates

As part of the migration work Core Formats looked at the World Location News Article Format, which supports embedded attachments. In order to progress that work we need to decide where the above qualities are managed, and represented in the new world architecture, at the very least in the short term, finding a way that works that we can revisit later without too much pain.

**Note** : There is already some support for embedded contacts for Case Studies, but as this format was migrated quickly, and as a very early example of the new world, we want to make re-evaluate the approach taken and compare to other options.

&nbsp;

## Proposals

### 1) Render embed template behaviour in publisher, send HTML to publishing API

This is effectively what case study does for contacts, which are already supported in the [govspeak component](http://govuk-component-guide.herokuapp.com/components/govspeak/fixtures/contact), equivalent styling would need to be added for attachments.&nbsp;

- publisher creates HTML body (including flattened embeds) and sends it to publishing API (embed templates stay in publisher)
- frontend reads HTML body from content from and passes it to govspeak component
- govspeak component has CSS/JS (based on the markup/selectors on the template in publisher) to add styling/behaviour for embed markup
- pros
  - no change to content schema,&nbsp;frontend, or&nbsp;publisher (case studies already do this for contacts)
  - maintains simple content item body representation, just HTML, keeps frontend simple
  - no need to model embed records as content store items/links
  - whitehall already tracks dependency changes and republishes
- cons
  - making design changes to embed templates is harder to keep in sync with component CSS&nbsp;
  - making design/copy changes requires republishing/re-rendering documents
  - mix of concerns - frontend/presentational content (inc translations) in publisher
  - embedded&nbsp;

### 2) Publish raw govspeak, have frontend parse govspeak/embeds/etc

- Change content item body to be govspeak, not HTML
- Move govspeak parsing/embedding logic (and templates) into frontend
- Include embed data in links hash, for frontend to interpolate
- CSS/JS for embeds lives in frontend(s)?, more likely still govspeak component on static
- pros
  - embed templates live in frontend, right separation of concerns
  - frontend has freedom in how to render embeds
  - link expansion means embed data will automatically update on change
- cons
  - big change to our representation of content in content items
  - adds&nbsp;significant complexity into all frontends (as the new world decouples publisher from frontend, any frontend may need to render embeds)
  - attachments and contacts need to exist in content store for link expansion
  - CSS/JS for embeds still lives in a separate repo (static, for components) to the template, which will be in frontend(s)?
  - Harder for non-government users to consume the content store item via API
  - Publisher still needs to be aware of embed syntax, to send right links

### 3) Publish HTML with embed placeholders, have Frontend parse/embed

_((please expand, based on rough notes in meeting last week))_

- Not as extreme as **2),** govspeak is still converted to HTML by the publisher, hiding most of the complexity from FE
- embeds are represented as [SSI style](https://en.wikipedia.org/wiki/Server_Side_Includes) includes in HTML (so transparent to 'dumb' frontend, or api client)
- otherwise same issues as above

### 4) A rendering service sits between content store/frontends and performs govspeak parsing/embedding

- Rendering services takes govspeak and expands embeds on request
- Frontends receive rendered HTML as normal
- Mix of concerns less of an issue, as embed rendering isn't in the publisher
- Pros
  - Single versionable service responsible for rendering Govspeak
  - Changes to rendering of Govspeak won't require republishing of documents
  - UNIX-like single responsibility principle
- Cons
  - Layer of indirection between Content Store and Frontend
  - Would do a lot of on-the-fly processing, rendering Govspeak for each cache miss
  - Yet Another Microservice, adds operational complexity
- An alternative to some complexity would be to add the rendering component directly into Content Store

### 5)&nbsp;Publishing API renders Govspeak into HTML for Content Store

- Publishing apps send Govspeak to Publishing API, along with embeddable data, e.g. attachments, images
- Publishing API renders Govspeak into HTML at publish time, and stores HTML in Content Store
- Publishing API will handle re-rendering/republishing if Govspeak design changes
- Pros
  - Publish-time rendering rather than on-the-fly frontend rendering
  - 

Single versionable service responsible for rendering Govspeak

  - 

Publishing apps don't need to re-render or republish documents if designs change

  - 

Supports future Phase 2 work by allowing publishing apps to store content source in Publishing API

- Cons
  - Additional complexity in Publishing API
  - Mismatch of content schema between publishing and frontend

&nbsp;

&nbsp;

&nbsp;

&nbsp;

