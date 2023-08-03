# Technical Direction in Publishing 2023

## Summary

This RFC documents the expected future direction of applications in the Publishing area of GOV.UK and the technical principles that are adopted by teams working in Publishing as of Summer 2023. While the information in this can be, and is encouraged, to be used by other parts of GOV.UK we have only sought product level agreement within Publishing.

## Problem

This RFC aims to address a number of cases where there is information that is shared conversationally but a lack of documentation of it. It reflects that the future app direction in Publishing is no longer consistent with [RFC 95 - long term future of applications](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-095-long-term-future-apps.md) and that Publishing has gone through and continues to go through frequent changes in people.

The purpose of this is to provide easy guidance for existing and new people in Publishing to understand directions and what is valued.

## Proposal

### Future direction of publishing and publishing adjacent applications

This provides an update on the application directions outlined in [RFC 95](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-095-long-term-future-apps.md) to reflect current expectations in Publishing. This lists applications that are owned by Publishing and those which aren't that Publishing has a view on. This should be considered a point-in-time view and will be affected by future strategic changes in GDS, GOV.UK and Publishing.

Application | Description | 2018 view | 2023 owning directorate | 2023 view
-- | -- | -- | -- | --
asset-manager | Manages uploaded assets (images, PDFs etc.) for applications on GOV.UK | No change expected | Publishing | Short term: remove Whitehall specific endpoints<br>Long term: consider whether an expanded Publishing API is a suitable consolidation destination due to similar functionality
authenticating-proxy | Allows authorised users to access the GOV.UK draft stack | No change expected | Publishing | No change expected
bouncer | Handles traffic for sites that have transitioned to GOV.UK | Rename to "transition-redirector" | User Experience | Medium term: merge into Transition application to resolve tight coupling and number of applications to maintain
collections-publisher | Publishes step by steps, /browse pages, and legacy /topic pages on GOV.UK | While topics and browse pages will be removed, this can still be the app for curating collections. We might move Whitehall's document collections into this app | Publishing | Medium term: retire Coronavirus publishing<br>Long term: consider whether curation/publishing functionality should be part of a larger publishing application such as Mainstream Publisher or Whitehall
contacts-admin | Publishes HMRC contact information on GOV.UK | No change expected | Publishing | Medium/long term: consolidate features with contacts in Whitehall, merge into Whitehall
content-publisher | Beta publishing application for improved publishing of Whitehall news/press release formats | Expand to publish most content | Publishing | Short term: retire in favour of Whitehall Publisher, migrate content to Whitehall
content-store | API for content on GOV.UK | No change expected | Publishing | Short term: replace Mongo 2.6 with PostgreSQL<br>Long term: evaluate whether it would be preferable to implement Content Store functionality in Publishing API and retire Content Store
content-tagger | Tool to tag content and manage the taxonomy on GOV.UK | No change expected | Publishing | Medium term: remove functionality related to Topic Taxonomy rollout<br>Long term: future unclear but will likely depend on product direction/investment in Topic and World Taxonomies
hmrc-manuals-api | API for HMRC to publish manuals to GOV.UK | No change expected | Publishing | Long term: undesirable to have an app for one document type and one department; we should decide whether we are prepared to provide API publishing functionality to departments and, if so, provide it in a reusable way that would eventually replace this
info-frontend | Serves /info pages to display user needs and performance data about a page on GOV.UK | No change expected | User Experience | Short term: retire due to being rendered mostly obsolete by Performance Platform decommissioning and planned Maslow retirement
manuals-publisher | Publishes manuals on GOV.UK | Retire in favour of content-publisher | Publishing | Short term: deliver quality of life improvements<br>Long term: consider whether app can be migrated into Whitehall, should Whitehall have support for hierarchical content structures.
maslow | Create and manage needs on GOV.UK | Rename to "user-needs-publisher" | Publishing | Short term: retire application due to long term lack of usage and need for significant culture change to be a viable product
organisations-publisher | An idea for a publishing app to manage organisations, people and roles within GOV.UK | Will take on the organisation and "machinery of government" functionality of whitehall | N/A | App was never built, from our 2023 perspective we’d prefer to iterate the machinery of government function in Whitehall than rebuilding it in a new app.
publisher | Publishes mainstream content on GOV.UK | Retire in favour of content-publisher | Publishing | Short/Medium term: Investment opportunity for new/experimental GOV.UK formats/iterations<br>Medium term: meet business decisions on greater departmental involvement in mainstream content (likely either cross-government access to publisher or moving cross-government formats to Whitehall)<br>Long term: Consider whether the functionality of Whitehall and publisher is similar enough to justify separate applications
publishing-api | API to publish content on GOV.UK | No change expected | Publishing | Medium term: iterate to meet emerging business needs, such as embedded content<br>Long term: potential consolidation destination for Asset Manager, Content Store and Router API
router-api | API for updating the routes used by the router on GOV.UK | Merge into either content store or publishing-api | User Experience | Long term: establish an alternative way for Router to load routes from Publishing API or Content Store and then retire
service-manual-publisher | Publishes the Service Manual on GOV.UK | Custom application that could long term be replaced by content-publisher | Publishing | Long term: candidate for consolidation into Whitehall
short-url-manager | Tool to request, approve and create short URL redirects on GOV.UK | No change expected | Publishing | No change expected
signon | Single sign-on service for GOV.UK | No change expected | Publishing | Short term: invest in security and modernisation updates<br>Medium/long term: explore whether off-the-shelf software or third party integrations could replace this software or reduce its responsibilities
specialist-publisher | Publishes specialist documents on GOV.UK | Retire in favour of content-publisher | Publishing | Short term: simpler process to create new Specialist Finders<br>Medium/long term: candidate for consolidation into Whitehall
transition | Managing redirects for sites moving to GOV.UK. | Rename to "transition-admin" | Publishing | Medium term: merge destination for transition-config and bouncer. Simplify app removing functionality no longer used<br>Long term: Simplify app drastically or replace app with a text based config file (nginx or similar)
transition-config | Separate repository to manage Transition's configuration | N/A | Publishing | Medium term: merge into transition
travel-advice-publisher | Publishes foreign travel advice on GOV.UK | Retire in favour of content-publisher | Publishing | Medium/Long term: candidate for consolidation - most likely into Whitehall, however Publisher is also a candidate should Travel Advice be considered mainstream content
whitehall | Publishes government content on GOV.UK | Retire in favour of content-publisher, organisations-publisher, and collections-publisher, custom-frontend (history pages) | Publishing | Short term: remove frontend rendering, invest in improvements, consolidation destination for Content Publisher<br>Medium/long term: Iterate content modelling to enable application consolidation and to meet new business needs. Explore future approaches to manage machinery of government concepts.

### Publishing Technical Principles

- [Improving software is typically faster, more effective and less risky than rebuilding](#improving-software-is-typically-faster-more-effective-and-less-risky-than-rebuilding)
- [Only build new apps in exceptional circumstances](#only-build-new-apps-in-exceptional-circumstances)
- [Embrace existing conventions; start new conventions collaboratively](#embrace-existing-conventions-start-new-conventions-collaboratively)
- [Code should be correct, clear, concise and tested](#code-should-be-correct-clear-concise-and-tested)
- [If a migration is worth starting, it’s worth ending](#if-a-migration-is-worth-starting-its-worth-ending)
- [Prefer identifying and implementing missing features over toil tasks and data manipulation](#prefer-identifying-and-implementing-missing-features-over-toil-tasks-and-data-manipulation)
- [Optimise for maintainability, yet prioritise security](#optimise-for-maintainability-yet-prioritise-security)
- [Understand the tooling you own; respect the ownership of others](#understand-the-tooling-you-own-respect-the-ownership-of-others)
- [Paying down tech debt is a continuous process](#paying-down-tech-debt-is-a-continuous-process)
- [Keep coding fun! Reduce developer pain points and help others make progress](#keep-coding-fun-reduce-developer-pain-points-and-help-others-make-progress)

#### Improving software is typically faster, more effective and less risky than rebuilding

Building new software from scratch is expensive and time consuming, rebuilding software to meet the same needs as pre-existing software is [infamous](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/) in [its risks](https://gordonbrander.com/pattern/second-system-syndrome/). In GOV.UK’s history we’ve invested multiple times in rebuilding projects, and rarely have these been completed - common problems are: programme priorities change, effort needed underestimated and value of rebuilding overstated. Problems created by building new software are typically compounded by neglect to existing software that is expected to be replaced by the new software.

Improving existing software, while less exciting, is a model that works for us - we can ship value to a full user base quickly and, should priorities change, pivot priorities. This also allows us to focus the building of software on delivering improvements to users, rather than rebuilding what already works.

Replacing whole applications by rebuilding their features in a new application should only be considered when it can be completed in a short timespan or if the underlying framework and/or programming language is end-of-life. Rebuilding of components/modules within software applications is reasonable when it can be completed in a sufficiently short time frame that a team can guarantee its completion and the completion of any migratory work. 

#### Only build new apps in exceptional circumstances 

We have [lots of apps](https://docs.publishing.service.gov.uk/apps.html), far more than we can realistically maintain and iterate - we don’t want to add to this (indeed, we’d like to decrease it). We aspire to have our apps meet a broad section of needs for the majority of publishers, rather than being bespoke functionality for niche scenarios. We’ve learned many times that it’s quick to create a new app, hard to justify continuously financing them and harder still, once they have some usage, to retire or consolidate them.

When new user needs emerge, that prompt the consideration of a new app, we want to consider the following:

- Is this need a variation of something that one of our existing applications meet? If so, improve the existing app
- Can most of this need be fulfilled by an industry product? If so, prefer that - we prefer building software for what is unique to us
- Is this new software need something the GOV.UK programme will continue investing in for the foreseeable future? If not, it’s unwise to build it.
- Is this a need for a specific department? If so, can we abstract the specific need to a common need to avoid the ownership confusion of us building a tool for one department

#### Embrace existing conventions; start new conventions collaboratively

GOV.UK software, like most software, is built upon layers of convention and standards. We like conventions: they reduce developer surprises and unnecessary decisions. We don’t like competing conventions - we prefer one consistent, if non-ideal, approach to solve a problem applied to an app rather than individual developers picking their individual preference each time they face a similar problem.

Many GOV.UK conventions are documented. There is the [Service Manual](https://www.gov.uk/service-manual) on the high level team approach. There are organisational tech standards in the [GDS Way](https://gds-way.cloudapps.digital/). GOV.UK has [conventions for Rails applications](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html) and individual repositories can have [team agreed conventions](https://github.com/alphagov/whitehall/blob/main/docs/adr/0001-add-view-components.md). 

Not all conventions are documented. Some are learned from reading the code and the early decisions the developers made; others can be learned from observing team members or through code reviews. Not all conventions are in how software is written or documented. Others are in how team members interact with each other and collaborate.

Starting new conventions is a team activity not an individual one - we want the results of our teams to feel collective. Please communicate liberally in starting a convention so it has the best chance of becoming established and adopted.

#### Code should be correct, clear, concise and tested

Code should be optimised for readability. Choose clarity over brevity or performance, unless there is a genuine need not to. 

Code should have automated tests. These tests should be [necessary and sufficient](https://blog.testdouble.com/posts/2020-02-25-necessary-and-sufficient/).

Embrace relevant software engineering principles such as [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns), [single responsibility principle](https://en.wikipedia.org/wiki/Single-responsibility_principle) and [You aren’t gonna need it (YAGNI)](https://en.wikipedia.org/wiki/You_aren't_gonna_need_it). Embrace consistency, modularity and abstractions to manage complexity. When editing code strive to leave it in as-good or better state than in how you found it and place value in [intuitive naming](https://medium.com/signal-v-noise/hunting-for-great-names-in-programming-16f624c8fc03).

The decisions you make in producing your code should be included in your commit message. It is common that GOV.UK developers look at old commits when trying to resolve problems or understand design decisions. Always include the “why” of a change, the “what” is usually covered by the code.

#### If a migration is worth starting, it’s worth ending

Like many tech organisations, we’ve been burnt by large projects to adapt software from an old state to a new one that have been left incomplete. We value these migrations reaching an end state, whether it’s completing the planned migration or rolling back on an idea that won’t work. We discourage staying in an intermediary state.

If you’re part of a team that has inherited an incomplete migration, we encourage you to consider likelihood of the migration's success and whether it fits into future goals. Seek to bring it to a close.

If you’re a team starting a migratory project, plan carefully. Minimise time spent in an intermediary state, by deferring anything non-essential to the migration, particularly if the migration is going to take more than a couple of weeks (most migrations take longer than expected). Be extremely careful starting a migration that may take longer than the foreseeable roadmap, you must be sure there will remain a business priority to fund it. Consider that the longer a migration is put off, the longer it’s likely to take - keep tasks like version upgrades small by doing them often.

#### Prefer identifying and implementing missing features over toil tasks and data manipulation

Treat the need for developers to intervene in the running of an application as an efficiency smell, whether through doing things for users, running manual tasks or writing code to manipulate data. 

Use the evidence of these tasks to understand whether applications are missing features or have resolvable limitations and, where appropriate, implement changes to reduce the need for these tasks.

Avoid letting developer interventions blur the boundary of the service offered to users. Consider each time that a developer does something manually for a user as GOV.UK creating an undocumented feature. This feature then carries the expense of a developer’s time each usage. For frequent requests, that are not suitable as user features, document the boundaries of the service developers will provide and the process of how to run the task ([example](https://github.com/alphagov/content-publisher/blob/6fb72ab4038ae3150a777364ed51dfeadeaca47f/docs/edit-change-note-history.md)).

#### Optimise for maintainability, yet prioritise security

Likely the greatest technological struggle we’ve experienced in GOV.UK has been our ability to maintain the quantity of applications we’ve created. There are many things we’d compromise for ease of maintainability but the area we won’t compromise is security.

To produce maintainable applications, we encourage the following practices:

- build applications using similar technologies (unless there is a genuinely distinct need)
- consistent approaches across an application
- documentation of architectural decisions, domain concepts, support tasks and app limitations
- leverage open source/common industry approaches for problems that aren’t unique to our domain
- avoid superfluous applications that perform similar functionality, preferring a larger application over multiple small applications.

#### Understand the tooling you own; respect the ownership of others

Each GOV.UK repository should be owned by a team. GOV.UK has adopted a team based ownership approach to tools as we believe it results in better quality software, teams have a degree of autonomy in managing the improvement of software they own and the responsibility to fix defects can be easily established. Team members should know which software they own and what the [responsibilities of owning it](https://docs.publishing.service.gov.uk/manual/ownership-meaning.html) are. Owning teams should assist other teams that make use of that software or seek changes to the software and, should an owning team make changes that affect other teams, they should consult those teams.

Teams that are wanting to change software in repositories they don’t own should always involve the owning team - the degree of communication dependent on the scale of the change (i.e. seek a PR review for a small bugfix whereas you might want to have a meeting with a team to discuss a small feature). When teams need more substantial changes to apps they don’t own, these should ideally be done by the owning team as part of their roadmap and when this is not appropriate, the teams should agree on their approach to collaboration, communication and decision-making.

#### Paying down tech debt is a continuous process

Assume that in GOV.UK Publishing there will always be some degree of tech debt and that paying it down is never a single operation. Managing tech debt should be part of a process: a means to identify debts, an approach to prioritising paydown and how to celebrate the success of removing it.

Be careful in choosing to introduce tech debt for short term gain. The best time to paydown tech debt is just after it is introduced while it is fresh in memories and people understand the area. Debt that has been around for a long time can be much harder to justify the pay down as it easily falls into the realm of “we know it’s bad, but it’s been bad for 5 years so how can it be urgent?”.

#### Keep coding fun! Reduce developer pain points and help others make progress

Most of us started coding because it is fun and we want it to keep being that as part of working on GOV.UK Publishing. 

We can help contribute to this by making the experience of changing an app to be low friction, which involves chipping away at the little things that make a developer's life less enjoyable: flaky tests, painful setup tasks, poor performance and hard to read code.

The other key way we can help coding remain enjoyable is to have a good relationship with your colleagues. Being keen to help, available to review and willing to compromise are all valuable steps to help produce a healthy team environment.
