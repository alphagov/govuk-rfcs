## Problem

Whitehall applies some additional [presentational logic](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb)&nbsp;(and [styling](https://github.com/alphagov/whitehall/blob/master/app/assets/stylesheets/frontend/helpers/_govspeak.scss)) on top of [standard Govspeak](https://github.com/alphagov/govspeak). For the most part these [are](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L105-L107) [simple](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L162-L179) [tweaks](https://github.com/alphagov/whitehall/blob/master/app/helpers/govspeak_helper.rb#L186-L190) that could probably be merged into Govspeak itself, or continue to stay on the publisher side of the content store.

There are two cases, Embedded Contacts (example) and Embedded Attachments (example), that are more complicated, and blur the lines between publisher and frontend concerns. Contacts and Attachments are slightly different in implementation, but are effectively instances of the same embedding problem, where a representation of secondary information (outside of the document being published) &nbsp;is embedded in the Govspeak output.

The current Whitehall behaviour looks like this:

&nbsp;

- An editor adds an embed to their document, and publishes
  - they add the embed syntax (eg, `[contact:1234]`,` !@1`)
  - the document is persisted in the WH database
- The document (fetched from WH database) is rendered by a WH Frontend
  - where the embed govspeak syntax is parsed
  - the embed ID is extracted and a embed record fetched from the Whitehall database
  - a template (contacts, attachments) is rendered using the embed record replaces the embed syntax
  - (govspeak is then cached)
- An editor updates a contact/attachment embedded in the previous document
  - whitehall keeps a track of embedding relationships
  - when a dependency embedded in a document changes the govspeak cache is invalidated
  - allow the updated embed record to be used when rendering the govspeak on next request

The qualities of this system that we would like to maintain are:

- When an embedded record is updated the documents which have embedded it are automatically updated
- The embed templates and their CSS/JS live in the same repo, and can be iterated at in tandem.
- Changes to the copy/design of the the embed templates can be applied by uncaching the govspeak of those documents

## Proposals

&nbsp;

### 1) Render embed template behaviour in publisher, send HTML to publishing API

&nbsp;

- publisher creates HTML body (including flattened embeds) and sends it to publishing API (embed templates stay in publisher)
- frontend reads HTML body from content from and passes it to govspeak component
- govspeak component has CSS/JS (based on the markup/selectors on the template in publisher) to add styling/behaviour for embed markup
- pros
  - no change to content schema,&nbsp;frontend, or&nbsp;publisher (case studies already do this for contacts)
  - maintains simple content item body representation, just HTML, keeps frontend simple
  - no need to model embed records as content store items/links
  - whitehall already [tracks dependency changes and republishes](https://github.com/alphagov/whitehall/blob/5631a1722e186b194f4f7bb1f53cd2eb56e48034/lib/dependable.rb#L9-L11)
- cons
  - making design changes to embed templates is harder to keep in sync with component CSS&nbsp;
  - making design/copy changes requires republishing/re-rendering documents
  - mix of concerns - frontend/presentational content (inc translations) in publisher

### 2) Publish raw govspeak, have frontend parse govspeak/embeds/etc

- Change content item body to be govspeak, not HTML
- Move govspeak parsing/embedding logic (and templates) into frontend
- Include embed data in links hash, for frontend to interpolate
- pros
  - embed templates live in frontend, right separation of concerns
  - frontend has freedom in how to render embeds
  - link expansion means embed data will automatically update on change
- cons
  - fundemental change to our representation of content
  - introduces significant complexity into all frontends (as the new world decouples publisher from frontend, any frontend may need to render embeds)
  - attachments and contacts need to exist in content store for link expansion

### 3) Publish HTML with embed placeholders, have frontend

- Not as extreme as&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

