## Context (Whitehall)

Currently, the Whitehall application has a model called Edition.

A cursory look at this model reveals that it is responsible for:

- Storing Content
- Images
- Access Limitation
- Workflow
- Audit Trails
- Translations
- Dependencies
- Editorial Remarks
- ... many more things

I think it would be fair to say that Edition is a god object.&nbsp;It knows too much and deals with too many things.

It is widely acknowledged that Whitehall is difficult to work on, largely due to its monolithic nature.

## Context (Publishing API)

Currently, the Publishing API has models called DraftContentItem and LiveContentItem.

A cursory look at these models reveals that they are responsible for:

- Storing Content
- Access Limitation
- Versioning
- Workflow (draft vs. published)

I think it would be fair to say that DraftContentItem and LiveContentItem are **in danger of becoming god objects**.

It follows that this would make the Publishing API difficult to work on, largely due to the likeliness that it becomes a monolithic application.

## Problem Analysis

Currently, the ContentItem models are **composed of** the responsibilities listed above.

These responsibilities are "mixed in" to the models through the use of ActiveSupport::Concern.

The database tables for these models include additional columns for every responsibility they support.

Here is an object diagram that shows this composition:

&nbsp;

&nbsp;

- The **[single responsibility principle](https://en.wikipedia.org/wiki/Single_responsibility_principle)** recommends that you give each class/object in your system a single responsibility.

In this case, ContentItem has more than responsibility because it is inheriting the responsibilities of its mixed-in concerns (effectively through multiple inheritance).

&nbsp;

- The **[open/closed principle](https://en.wikipedia.org/wiki/Open/closed_principle)** recommends that you build your objects such that they are closed for modification and open for extension.

In this case, every time you want to add a new feature to your system, you have to open the ContentItem model and modify it to incorporate new behaviour.

## Proposal

I have seen this problem before and solved a similar problem in my last role.

It tends to arise because it is the easiest thing to do at the time, but it quickly leads you into trouble as the system grows in complexity.

I propose that we refactor to something the promotes extensibility:

&nbsp;

&nbsp;

We essential flip the direction of the arrows round.

This means that an AccessLimited responsibility would know about ContentItems, but ContentItems wouldn't have anything to do with AccessLimited.

This allows you to introduce new concepts and features without interfering with features that already exist.

## Further References

I spoke about Domain Driven Design at LRUG. I talk about this specific problem at around the 10:00 mark:

[https://skillsmatter.com/skillscasts/6524-domain-driven-design-in-the-wild](https://skillsmatter.com/skillscasts/6524-domain-driven-design-in-the-wild)

## Migration Plan

If this RFC is favourable, I think we should take one concept and extract it from the ContentItem models and into its own model.

We'd have to do a database migration and move data from the ContentItem tables into this new table and set up references back to the ContentItem table.

This can all be done as a refactor and the outermost tests should not be effected.

## Closing Thoughts

I strongly believe that we need to do this to future-proof the application. This is something we want to support for a long time to come and continue development on.

There will always be complexity in the business requirements and incoming feature requests and if we don't take steps to adequately manage that, we will get ourselves into trouble.

## What Next?

Please leave your thoughts and feedback on this document.

Thanks

