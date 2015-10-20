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

I think it would be fair to say that DraftContentItem and LiveContentItem are starting to take on too many responsibilities.

This could make the Publishing API difficult to work on as it might start to become a monolithic application.

## Code Analysis

Currently, the ContentItem models are **composed of** the responsibilities listed above.

These responsibilities are "mixed in" to the models through the use of ActiveSupport::Concern.

The database tables for these models include additional columns for every responsibility they support.

Here is an object diagram that shows this composition:

&nbsp;

&nbsp;

- The **[single responsibility principle](https://en.wikipedia.org/wiki/Single_responsibility_principle)** recommends that you give each class/object in your system a single responsibility.

In this case, ContentItem has more than one responsibility because it is inheriting the responsibilities of its mixed-in concerns (effectively through multiple inheritance).

&nbsp;

- The **[open/closed principle](https://en.wikipedia.org/wiki/Open/closed_principle)** recommends that you build your objects such that they are closed for modification and open for extension.

In this case, every time you want to add a new feature to your system, you have to open the ContentItem model and modify it to incorporate new behaviour.

## Proposal

I saw a similar problem in my last role:

It tends to arise because it is quick and easy to add new responsibilities in this way, but it quickly leads you into trouble as the system grows in complexity.

I propose that we refactor to something that promotes extensibility:

&nbsp;

&nbsp;

We effectively flip the direction of the arrows round.

This means that an AccessLimited responsibility would know about ContentItems, but ContentItems wouldn't have anything to do with AccessLimited.

This allows you to introduce new concepts and features without interfering with features that already exist.

## Examples

Here's are some examples of the kind of things I'm proposing:

&nbsp;

**1) You could introduce the notion of a Workflow to relieve the ContentItem of this responsibility:**

```
content_item = Workflow.fetch("content-item-id", :draft) # or :live
```

If you did this, you could collapse the DraftContentItem and LiveContentItem tables into a single table.

The resulting ContentItem model would be free of workflow concerns, i.e. it wouldn't know or care whether it was in a Draft or a Live state.

This means that you could work on the business logic for workflow in isolation without needing to change the ContentItem model.

Consider what might happen if you decided to change your workflow: "draft", "proofread", "editing", "pre-publish", "published"

You could simply introduce these as new states without having to add three extra tables to the database.

This applies for other changes you might decide to make for workflow, e.g. rules for when a content item is allowed to transition from draft -\> live.

&nbsp;

**2) You could introduce the notion of a VersionArbiter (or some better name):**

```
version = VersionArbiter.version_for(content_item)
```

If you did this, the ContentItem model would no longer need to store its version and any validation rules could be extracted from this model.

For example, there is an invariant which states that the live version cannot be ahead of the draft version of a content item.

You could pull this out into the VersionArbiter who is responsible for enforcing this. The ContentItem simply focuses on storing its content - not on versioning.

&nbsp;

**3) You could introduce the notion of an AccessLimitation or Restriction to relieve the ContentItem of this responsibility:**

```
restrictions = Restriction.restrictions_for(content_item)
```

If you did this, you could remove the access\_limited field from ContentItem and you could focus on Restriction related business logic in isolation.

At present, only the DraftContentItem is eligible for AccessLimitation and so it appears as a field on that table.

You could remove that field and move it into a separate table which references the content item.

&nbsp;

**In summary**

My proposal is all about refactoring the system such that objects, with clear responsibilities, are working together to get things done.

When new concepts are added to the system, we can create objects that model those concepts and extend the system to incorporate them.

## Further References

I spoke about Domain Driven Design at LRUG. I talk about this specific problem at around the 10:00 mark:

[https://skillsmatter.com/skillscasts/6524-domain-driven-design-in-the-wild](https://skillsmatter.com/skillscasts/6524-domain-driven-design-in-the-wild)

## Refactor Plan

If this RFC is favourable, I think we should take one concept and extract it from the ContentItem models and into its own model.

We'd have to do a database migration and move data from the ContentItem tables into this new table and set up references back to the ContentItem table.

This can all be done as a refactor and the outermost tests should not be effected.

## Closing Thoughts

I really think that this refactor would help to future-proof the application. We want to support this app for a long time and this would help make that easier.

There will always be complexity in the business requirements and incoming feature requests and if we don't take steps to adequately manage that, we could slow down.

## What Next?

Please leave your thoughts and feedback on this document.

Thanks

