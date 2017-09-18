# Approach for next iteration of Content API

## Contents

* [Summary](#summary)
* [Problem](#problem)
* [Proposal](#proposal)
  + [Guiding principles](#guiding-principles)
    - [External API == Internal API](#external-api--internal-api)
    - [Optimised for data organisation not use cases](#optimised-for-data-organisation-not-use-cases)
    - [Return data types and use type consistently throughout API](#return-data-types-and-use-type-consistently-throughout-api)
    - [Follow best practices of REST APIs](#follow-best-practices-of-rest-apis)
  + [Items we've tried to address](#items-weve-tried-to-address)
    - [Access to historical information](#access-to-historical-information)
    - [Avoiding the terminology of unpublishing](#avoiding-the-terminology-of-unpublishing)
    - [Ability to revoke legally sensitive information](#ability-to-revoke-legally-sensitive-information)
    - [Different ways to navigate content](#different-ways-to-navigate-content)
    - [Separate content from routing information (gone / redirects)](#separate-content-from-routing-information-gone--redirects)
  + [Items for further work](#items-for-further-work)
    - [How the JSON is represented](#how-the-json-is-represented)
    - [Write endpoints](#write-endpoints)
    - [How schemas are explained](#how-schemas-are-explained)
    - [Sequential IDs](#sequential-ids)
    - [Expanded Links](#expanded-links)
    - [Embedded content](#embedded-content)
    - [Not all content fits document/edition model](#not-all-content-fits-documentedition-model)
  + [Draft list of endpoints](#draft-list-of-endpoints)
    - [`/` (Root)](#-root)
    - [`/resource/{path}`](#resourcepath)
    - [`/documents`](#documents)
    - [`/documents/{content_id}`](#documentscontent_id)
    - [`/documents/{content_id}/{locale}`](#documentscontent_idlocale)
    - [`/documents/{content_id}/{locale}/editions`](#documentscontent_idlocaleeditions)
    - [`/documents/{content_id}/{locale}/change-notes`](#documentscontent_idlocalechange-notes)
    - [`/documents/{content_id}/{locale}/editions/live`](#documentscontent_idlocaleeditionslive)
    - [`/documents/{content_id}/{locale}/editions/version/{version}`](#documentscontent_idlocaleeditionsversionversion)
    - [`/editions`](#editions)
    - [`/editions/{id}`](#editionsid)
    - [`/editions/{id}/change-note`](#editionsidchange-note)
    - [`/editions/change-notes`](#editionschange-notes)
    - [`/locations`](#locations)
    - [`/locations/lookup/{path}`](#locationslookuppath)
    - [`/locations/{id}`](#locationsid)
    - [`/gones`](#gones)
    - [`/gones/{id}`](#gonesid)
  + [Draft list of entities](#draft-list-of-entities)
    - [Document](#document)
    - [Edition](#edition)
    - [ChangeNote](#changenote)
    - [Location](#location)
    - [Resource](#resource)
    - [Route](#route)
      * [RedirectRoute](#redirectroute)
    - [Gone](#gone)
      * [RetiredGone](#retiredgone)
      * [RevokedGone](#revokedgone)
  + [Next steps](#next-steps)
  + [Answers to hypothetical questions](#answers-to-hypothetical-questions)
    - [Why REST? Isn't everyone using GraphQL now?](#why-rest-isnt-everyone-using-graphql-now)
    - [How might this be rolled out?](#how-might-this-be-rolled-out)
    - [Do we need a content store should we be just querying the Publishing API?](#do-we-need-a-content-store-should-we-be-just-querying-the-publishing-api)
    - [Why use the word "live" when it is already used in the context of live content store?](#why-use-the-word-live-when-it-is-already-used-in-the-context-of-live-content-store)
    - [I'm not too sure about the naming of "x"?](#im-not-too-sure-about-the-naming-of-x)
    - [Is it preferred to lookup content via content_id than to use a path?](#is-it-preferred-to-lookup-content-via-content_id-than-to-use-a-path)
    - [Is there a plan for how to document this?](#is-there-a-plan-for-how-to-document-this)

## Summary

This RFC serves as an introduction to the approach that we (the API for Content
team) have taken to defining the next iteration of the GOV.UK Content API which
considers historical content.

The purpose of this RFC is to present our approach and ideas for what we feel
is the next logical iteration of the Content API. We are seeking feedback from
the wider GOV.UK developer community on this approach and looking for community
consensus that this a sensible path to proceed further on. We welcome
questions and are happy to explain further how we arrived at suggestions we
have proposed.

This RFC presents the principles we have applied to defining things, the items
we have considered inside/outside scope, a draft list of endpoints, and a
draft list of types reflected in the new API.

## Problem

GOV.UK, as a member of Open Government Partnership (OGP), has made a
[commitment][ogp-commitment] to:

- Provide APIs for government content
- Provide a full version history of every published page

Currently we loosely meet the first criteria of this commitment - with our
unofficially supported `/api/content` endpoint - and don't meet the second one.

To meet both of these we need the means to access historic content, which would
logically be [through the content store][content-history-content-store], and to
assess how well our current Content API meets the first commitment.

We have identified the following problems with the current Content API:

- There is just a single lookup for content - by path - and not means to
  navigate through content.
- There is useful information not exposed (such as routing) since it is not
  used to render pages.
- The information provided is hard to understand without knowledge of schemas
  and other sub-systems.
- Somewhat confusing responses are returned for non-content items such as
  redirects and gones.

When considered in the context of historic content we have these additional
problems:

- The model of a [ContentItem][content-item-definition] representing the
  compound of a [Document][document-definition] and
  [Edition][edition-definition] which causes significant data replication.
- The means of lookup (path) blurs the lines between current and historic
  content.
- An approach to identify which content is current and which is historic.

## Proposal

### Guiding principles

There are a number of basic principles we have followed in defining this API,
an understanding of these may be useful in understanding the "why" in some of
our suggestions.

#### External API == Internal API

If we are to have a single API that we use internally and externally we
gain the following:

- Less to maintain - only 1 API
- Higher chance of catching issues internally
- External API evolves implicitly with our internal needs

And we accept the following problems:

- Data included in the API that may be of no use outside GOV.UK
- More frequent changes to accommodate the changes needed for GOV.UK's evolution

#### Optimised for data organisation not use cases

We've structured the endpoints based on what data we have and the logical way
the resources fit together rather than considering what use cases may be. The
reasoning for this (aside from general REST API recommendations) is that we
are building this to enable usage of our data and we aren't trying to
anticipate what those uses may be.

However in contrast to this we have considered how the current `content/{path}`
endpoint can be replaced without requiring any additional API lookups. And
have chosen for endpoints to have a preference for returning "live" content.

#### Return data types and use type consistently throughout API

We chose to start from the principle that every resource returns an entity or
a list of entities. Each one of these entities has a defined structure and a
canonical URL.

This offers us a number of advantages compared to returning arbitrary data:

- Consistency - if the same data is used in two places you can expect it to be
  structured the same.
- Easier to model consumption of the API - the entity has a name you can use,
  same classes can be used for multiple API responses.
- Expansion of the API need an integrated consideration of the system.

And we accept the following problems:

- In some cases responses may be more verbose than necessary to return an
  entity.
- We may need to implicitly embed related entities in responses to provide a
  holistic response in endpoints.
- There could end up being a lot of entities in the system were we to model
  each schema.

#### Follow best practices of REST APIs

We have tried to follow industry best practices on REST APIs wherever
appropriate. Some aspects of this is are:

- Usage of nouns not verbs in endpoints
- Intention to provide filtering, sorting and pagination of collections
- Usage of links within the responses to communicate state and relationships

### Items we've tried to address

#### Access to historical information

This API proposal is designed around historical content being as easy to lookup
as content that is currently live. There is the expectation that a user of the
API can filter based upon just live, just past or a mixture of content.

#### Avoiding the terminology of unpublishing

We've tried to stay clear of the concept of unpublishing as is used in
[Publishing API][] and other publishing apps. The concept of unpublishing is
confusing in a historic context (and arguably even in our current context) as
it implies the inverse of publishing but something unpublished would still be
in the history.

We propose handling unpublishings through content _replacing_ the
[Resource](#resource) at a particular URL and having timestamps that indicate
when the resource was _live_.

The term "replace" is not actually used in the proposal for the API however
the term ["retired"](#retiredgone) has been introduced.

#### Ability to revoke legally sensitive information

A new concept introduced in this proposal is subtyping [Gone](#gone) into
[RetiredGone](#retiredgone) and [RevokedGone](#revokedgone). The former is
intended for the current scenario that Gone is used for - a document that was
once on GOV.UK but reached the end of it's useful life.

The concept of RevokedGone is intended for handling legally sensitive
information. It would be used to replace either an Edition or Document that has
needed to be removed for legal reasons and cannot continue to be in our history.

#### Different ways to navigate content

This proposal introduces a number of endpoints for navigating and filtering
collections of content. Potential usages this may provide is:

- Looking up all editions published within a time window
- Following the change notes of all content being published
- Tracking all content being removed from GOV.UK

#### Separate content from routing information (gone / redirects)

Currently in the content store paths that configure the router to return
redirect or gone responses are modelled as ContentItems. This proposal suggests
that these should be modelled separately.

Redirects are suggested to be modelled as a type of routing and not be
associated with a resource - as we do not store data beyond the routing with a
redirect.

Gones are considered to be a distinct resource from an Edition.

By separating these concerns from content we have the advantage to make the
rules for validity of a ContentItem stricter - as there is less variance in
what they might contain - and provide a more meaningful response when
accessing Gones/Redirects.

### Items for further work

There are a number of items that we are considering or are postponing
investigating/iteration. These are listed here to indicate current thoughts on
them.

#### How the JSON is represented

We are considering what structure we will use to represent the data. We are
looking for a way to express the type, hypertext links and meta information
without this being confused with the data. We'd like to apply this consistently
across all API responses.

We have investigated [json:api][] and [Hal Specification][] and felt neither
standards were an ideal fit for us. So we're looking to define something simple
which seems to be the more common approach. APIs we're taking inspiration
from the aforementioned standards and popular APIs such as [Stripe][stripe-api].

#### Write endpoints

This proposal does not consider what might need to change in how data is written
to the Content API. This is because only a single application, Publishing API,
writes to the Content Store whereas there are many users of the read API.

We intend to have done due diligence that is easy to write to the API before
any of the suggestions here are implemented.

#### How schemas are explained

One of the challenging parts of explaining content in the Content API is the
pre-requisite of understanding of what [govuk-content-schemas][] are and how
they can be used to describe the fields that make up content.

This proposal does not consider the effect they have, though there is the
possibility that these may be defined as a subtype of [Edition](#edition). We
intend to perform an investigation into how these can be used to explain
content in the current content store and apply our learnings to the next
iteration.

#### Sequential IDs

This proposal offers numerous endpoints that are the canonical method to look
up an entity, which may require the lookup by ID.

The current Content API does not expose any sequential IDs, and it could be
that by introducing IDs that are sequential we accidentally reveal information
that is not intended to be public (such as the ordering that policies are
drafted in).

It may be appropriate to use [UUID][] for all ID purposes, although this could
cause confusion with our `content_id` format.

#### Expanded Links

One of the problems we have with introducing historic content is how to handle
the links of that external content. It's a problem we have been considering
passively and want to explore it in more detail. This proposal does not attempt
to address it.

Some of the options considered are:

- Keeping all expanded links up to date
- Separating links into Document and Edition links
- Tying Edition links to a particular major version of a piece of content.

#### Embedded content

A requested feature for the current Content API is the means for there to be a
richer method to include data from a different content item than expanded links.
eg a method to pick particular relevant data from an expanded link.

This proposal does not attempt to solve this problem.

#### Not all content fits document/edition model

By revealing historic content we begin to see content which isn't particularly
well suited to the document/edition model. An example of this is a
[smart answer][smart-answers] which is written in code and has an edition
updated every deploy.

We expect that by introducing history this problem will be revealed more and
believe it should be investigated but is not a priority.

An early idea is having an Application entity to handle content that is
published automatically.

### Draft list of endpoints

This is a list of the endpoints we are proposing for the next iteration of the
Content API.

#### `/` (Root)

The root of the API, would return information to help someone get started with
the API and links.

Entity returned: A custom one

#### `/resource/{path}`

This is used to access a resource by the `path` it is available at. It is
synonymous with the `/api/content/{path}` endpoint from the current Content API.
For a `path` that is a [RedirectRoute](#redirectroute) this will return a
redirect, where the resource is a type of [Gone](#gone) a 410 will be returned
with the Gone response.

A `timestamp` parameter could be provided to return the resource available at a
particular time.

Entity returned: [`Resource`](#resource)

#### `/documents`

An endpoint to navigate through all documents that have been available on
GOV.UK, would default to showing those which have a live edition.

Could be used to track when new documents are added to GOV.UK.

Entity returned: `List<Document>`

####  `/documents/{content_id}`

This endpoint allows a user to browse the available locales a document is
available in for a particular `content_id`.

Entity returned: `List<Document>`

#### `/documents/{content_id}/{locale}`

This is the canonical path for a particular document. Used to look up details
of a Document.

Entity returned: [`Document`](#document)

#### `/documents/{content_id}/{locale}/editions`

This is used to browse through all editions available for a particular document.
Could be used to compare how a piece of content has changed over time. Could be
filtered by whether minor changes are shown.

Entity returned: `List<Edition>`

#### `/documents/{content_id}/{locale}/change-notes`

This is used to browse through the change notes for a particular document.

Entity returned: `List<ChangeNote>`

#### `/documents/{content_id}/{locale}/editions/live`

Used to access the live edition for a document. Live meaning the version that
is currently on the particular content store.

Entity returned: [`Edition`](#edition)

#### `/documents/{content_id}/{locale}/editions/version/{version}`

Used to look up a particular edition of a document by the version number that
describes it. Would offer links to navigate to earlier versions.

Entity returned: [`Edition`](#edition)

#### `/editions`

This returns a paginated list of editions that match parameters, by default it
would return just live ones. This endpoint could be used to track changes to
particular groupings and to track when new items are published on GOV.UK

Entity returned: `List<Edition>`

#### `/editions/{id}`

This is the canonical method to look up an Edition.

Entity returned: [`Edition`](#edition)

#### `/editions/{id}/change-note`

This is the canonical method to look up the change note for a particular
edition.

Entity returned: [`ChangeNote`](#changenote)

#### `/editions/change-notes`

This endpoint can be used to browse through all the change notes for every
edition (defaulting to live ones). Which can be used to track the reasons for
why things are changing on GOV.UK.

Entity returned: `List<ChangeNote>`

#### `/locations`

This endpoint is to browse what is on GOV.UK from a `path` perspective. It can
be used to browse the history of a path and to determine what was on GOV.UK at
a particular time.

Entity returned: `List<Location>`

####  `/locations/lookup/{path}`

This endpoint is used to lookup the routing data for a particular path, it can
be provided with a timestamp to determine the time you are looking up. Unlike
`/resource/{path}` this returns the routing data rather than the resource.

Entity returned: [`Location`](#location)

####  `/locations/{id}`

The canonical method to lookup a Location.

Entity returned: [`Location`](#location)

#### `/gones`

This endpoint is used to lookup content that has gone from GOV.UK, which could
be because it was retired or revoked. This could be used to keep track of what
is being taken off GOV.UK.

Entity returned: `List<Gone>`

#### `/gones/{id}`

The canonical method to lookup a Gone.

Entity returned: [`Gone`](#gone)

### Draft list of entities

This is a list of the entities envisioned to be used for the API, with brief
descriptions of their purpose.

#### Document

A object that represents all editions of a piece of content. Would store
information consistent across all edition, such as content_id,
locale, first_published_at. Could be used to access latest iteration of a
piece of content.

#### Edition

This object represents an edition of a document, which is therefore a piece of
content. This stores information such as title, content, description.

#### ChangeNote

This describes a change that has been made to an edition. It includes
information such as a note and timestamp.

#### Location

This object is used to represent a collection of routes that is associated with
a Resource. It will have information such as base_path, timestamps route was
live.

#### Resource

This represents something that can be at a Location. Currently the known items
would be an Edition or a Gone, however this could expand in future.

#### Route

This represents a single route that would be included in a Location. It would
contain a path and whether it is a prefix or not.

##### RedirectRoute

This would be a subtype of route that has additional information associated
with a redirect, such as destination, segment mode, etc.

#### Gone

A gone is a generic type that represents a piece of content that is no longer
available. This is available in two types RetiredGone and RevokedGone.

##### RetiredGone

A RetiredGone is used as a resource for a document that is no longer available.
This is synonymous with a Publishing API unpublishing of type “gone”

##### RevokedGone

A RevokedGone is a type to represent a new concept in the Content API which is
for content that has been removed for legal reasons.

### Next steps

The purpose of this RFC is to present and explain the approach the API for
Content team have taken towards defining an API. We feel that this is a
suitable point for seeking opinions as we've established ideas and patterns but
everything is still malleable enough that there's scope to reconsider.

We're particularly interested to learn whether the changes suggested will cause
problems for users of the content store or, alternatively, might solve problems
that currently exist.

We welcome any ideas or insights on the things we are suggesting here,
particularly with reference to projects that we may not be aware of.

Our next steps with this work is likely to be prototyping of these endpoints
within the Publishing API, which is to help inform the structure of fields.

### Answers to hypothetical questions

#### Why REST? Isn't everyone using GraphQL now?

GraphQL is an interesting proposition to us and has clearly been gaining
traction. It still seems an unlikely first choice for our stack as it would
require substantial re-tooling of our stack and feels like a potentially
unfamiliar interface for partners.

We are, however, interested in GraphQL and we feel that the usage of entities
keeps open an opportunity to provide a GraphQL interface at a later date if
there is sufficient need for it.

#### How might this be rolled out?

There would be a plan to allow access to both the current Content API and the
next iteration to co-exist for a period of time. This would allow time for
migration.

There are some unknowns about the process of enabling historic content to be
viewable and who needs to be consulted/what data needs to be fixed. We might
decouple this proposal from this concern by initially reducing the scope of
this API to be just content that is currently live.

#### Do we need a content store should we be just querying the Publishing API?

This is a question that has come up a number of times since we started
considering the differences in responsibilities the Content Store has once
historic content is a factor.

Outside of history we do have some advantages in a content store, such as a
separation between draft and live content store and data optimised for fast
reading.

We feel that we will learn in time whether the shared responsibilities between
Content Store and Publishing API are frustrating or not, however we feel that
by continuing to use the Content Store we have an easier path to completing
this work and not requiring large changes to the service stack.

#### Why use the word "live" when it is already used in the context of live content store?

We agree that this isn't ideal, we're just not sure of alternatives. We
initially considering using the word "current" but this felt too generic, we
want to avoid the term "published" because past items that are available are
still published. So we concluded that live was the most fitting word to describe
this and wouldn't be a problem for external users - since they don't have access
to the draft content store.

Any ideas/thoughts on this or a more suitable name are welcome.

#### I'm not too sure about the naming of "x"?

Please tell us so we can consider it and any naming suggestions are definitely
welcome, but we'll probably not want to get to involved in a naming debate at
this stage to avoid bikeshedding.

#### Is it preferred to lookup content via content_id than to use a path?

In a nut shell the answer is no.

In longer form though, content_ids and paths serve different purposes which due
to the relations of data can eventually lead to the same result. eg a
Location (path) is associated with an Edition, which is associated with a
Document (content_id). A user can use a content_id to get a historic overview
of every edition of a piece of content, whereas path is used to get a single
edition of a piece of content. If you aren't concerned with past editions you
need only consider path.

The number of endpoints involving a content_id compared to path seems to have
created an impression of content_id being the preferred method. This isn't
intended to be so however it is a natural side effect of content_id being part
of a solid data model. Whereas path and it's associated Location model is used
to link to a number of different data models, so navigating through this is
impractical due to their generic representation.

#### Is there a plan for how to document this?

The intention is to document this in a continuation of the approach established
for the current iteration of the Content API which is done through a
[microsite][content-api-docs-microsite] that is generated based on an [OpenAPI
v3 specification][content-store-openapi].

The choice to use OpenAPI is based on a [proposal][open-api-proposal] to
standardise on the usage of OpenAPI v3.

[ogp-commitment]: https://www.gov.uk/government/publications/uk-open-government-national-action-plan-2016-18/uk-open-government-national-action-plan-2016-18#commitment-12-govuk
[content-history-content-store]: https://docs.google.com/document/d/1yyRRlkwKrjC2_OZ0dlLP8wdzkORBhG3-T4qVoROk1u0
[content-item-definition]: https://github.com/alphagov/content-store/blob/master/doc/content_item_fields.md
[document-definition]: https://github.com/alphagov/publishing-api/blob/master/doc/model.md#document
[edition-definition]: https://github.com/alphagov/publishing-api/blob/master/doc/model.md#edition
[Publishing API]: https://github.com/alphagov/publishing-api
[json:api]: http://jsonapi.org/
[Hal Specification]: http://stateless.co/hal_specification.html
[stripe-api]: https://stripe.com/docs/api
[govuk-content-schemas]: https://github.com/alphagov/govuk-content-schemas
[UUID]: https://en.wikipedia.org/wiki/Universally_unique_identifier
[smart-answers]: https://github.com/alphagov/smart-answers
[content-api-docs-microsite]: https://content-api.publishing.service.gov.uk
[content-store-openapi]: https://github.com/alphagov/content-store/blob/76a415e30d03cbb65ca76d2a9883f47b71be53f3/openapi.yaml
[open-api-proposal]: https://github.com/alphagov/open-standards/issues/31
