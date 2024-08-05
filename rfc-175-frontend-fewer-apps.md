---
status: proposed
implementation: proposed
status_last_reviewed:
---

# Consolidate Frontend Content-Rendering Apps

## Summary

This is a refinement of the suggestions in [RFC-174] about reducing the number of frontend rendering applications, reducing its scope to the applications that deal exclusively with rendering content items. By dealing only with the four applications that exclusively render content items, we improve standardisation and reduce maintenance costs, and the work is worthwhile even if we can only achieve sections of it. Because a large part of the problem and a lot of the solution remains the same, we have divided this RFC into two parts - an initial section that describes how we differ from [RFC-174], and a more verbose section detailing the approach. If you have already read or commented on [RFC-174], you can read the [How this proposal differs](#how-this-proposal-differs) section and skip the rest of the RFC. If you are new to this proposal, feel free to skip to the [Full Exploration of the Problem](#full-exploration) section.

## <a name="how-this-proposal-differs"></a>How this proposal differs from [RFC-174]

### Reduced Scope

We have reduced the scope of the RFC to just consider the 4 pure content rendering apps:

1. [collections]
2. [finder-frontend]
3. [frontend]
4. [government-frontend]

### Removed references to retiring router/router-api

Retiring router/router-api in [RFC-174] relied on us dealing with [smart-answers], a problem worthy of its own RFC. With the reduced scope we can’t easily retire the router and router-api, although it does still simplify other avenues for retiring router that we can potentially explore later.

### Removed references to retiring static

Again, retiring [static] by merging all the apps relies on all apps being merged, something that is far enough in the future that we’ve decided to explore other options for retiring [static]

## <a name="full-exploration"></a>Full Exploration of the Problem

### Applications overview
GOV.UK is served by multiple rendering applications (apps). Each app serves different groups of pages within the website.

There are currently 8 rendering apps for GOV.UK that are supported and maintained by GOV.UK teams, 4 of which are almost exclusively concerned with rendering content:

1. [collections]
2. [finder-frontend]
3. [frontend]
4. [government-frontend]

Each app is built in a similar way.

* written in Ruby on Rails
* no database
* relies on data from API calls to populate pages
* calls the content API from [content-store] to get the basic page data

Some make further calls, for example to [search-api] to populate lists of search results.

Having more than one app results in a number of issues.

### Multiple apps represents a barrier to understanding
Having multiple apps with some inconsistencies in how they are structured represents a difficulty for experienced developers as well as a high barrier to entry for new starters. Onboarding new team could be easier with fewer apps.

### High maintenance burden
Code dependencies are managed automatically through github with dependabot. When a breaking change to a shared dependency changes, a dependabot PR will be raised in each app, meaning that developers need to approve and merge that PR 4 times. Additionally, since the apps are deployed separately, this can lead to brief periods of visual inconsistency.
Rails upgrades must also be repeated separately for each app.

### Deployments can be overly complicated
Our current setup means that code changes often occur in one app and therefore several deployments must be carried out together to ensure that the user experience across the site remains consistent. This is difficult to achieve precisely because each application is different and can take a different amount of time to deploy.

This will likely be an issue when deploying any upcoming changes to the GOV.UK brand.

### Inconsistent testing approach
The test suite is inconsistent across the rendering applications, which means that developers need to be familiar with more test suites than necessary, increasing the maintenance burden.

Some apps use RSpec while others use Minitest. Some use Jasmine, some Cucumber and some Mocha. Many use the old controller tests, some have request tests, and some have both.

Even when applications use the same testing frameworks there are still a lot of inconsistencies in how the tests are set up, for example in how fixture files are used, or how `content-store` and `search-api` are stubbed.

### Local preview and sharing changes to GOV.UK is difficult
Manually testing user journeys from a page is difficult, particularly where code changes are spread across more than one application. To test locally, developers have to have multiple applications running which slows down their local machines. This prevents us from easily replicating and fixing user-facing errors.

Having fewer apps would also mean that GOV.UK Docker, our system for running apps locally, could be simplified. This simplification would carry over if and when GOV.UK Docker is replaced with local Kubernetes clusters for development.

Sharing changes for non-engineering disciplines to preview is also difficult. We currently use Heroku for previews but this is only possible when the changes being previewed involve a single application. Previewing a user journey that involves pages from more than one app cannot be done in Heroku because links from a page in one app do not link to another. For example, a journey from the homepage to a search page and then a mainstream browse page crosses multiple app boundaries, and the links would 404 in Heroku.

An alternative way of previewing is deploying branches to integration, but these branches are frequently overwritten by dependency updates so this is not a reliable alternative.

Previewing would be greatly simplified by having fewer applications.

### Translations
There is existing tech debt for [multiple frontend applications use the same translated phrases]. These are some of the existing issues that will be improved by having fewer rendering apps:

1. Different pages on the site can have different translations for the same English word
2. Some translations will be missing on pages rendered by different frontend applications
3. Difficult to get visibility on which phrases are translated and which ones aren't

## Proposal

We propose merging these four applications into a single rendering app. This will solve some of the issues in this RFC and open avenues to solve others in the future - for example, removing `router` cannot be done by completing this RFC, but becomes easier. Some benefits would be felt even if we could not complete the whole scope. Even if we only succeed in merging a single application, that would mean one fewer to maintain.

We can steadily move routes, controllers and models from the candidate (the app being merged) into the host (the app we are merging into) until the host is serving all the routes.

We propose using [frontend] as the host app. This is because:

* `frontend` contains some of the more complicated document types like licence_transaction and local_transaction, that have multiple pages and interactive elements, which would be harder to consolidate into another app
* `frontend` has a one-controller per document type layout, which is preferable for document types with multiple pages as it follows [rails conventions for controllers] to do the orchestration.

[government-frontend] was also considered for the host app, but not chosen because it has a more restrictive presenter pattern that works well for single-page document types. Even though `government-frontend` has many document types and accounts for 50% of the frontend traffic, it would be easier to move the single-page document types from `government-frontend` to `frontend` than it would to try and force the document types in `frontend` into the presenter pattern.

### Testing standardisation
We propose standardising around RSpec as the test suite for the frontend, ideally [modernising the tests], for example by switching to request tests rather than controller tests and system tests rather than feature tests. RSpec is the [preferred testing suite] on GOV.UK and is favoured by many developers because the tests and testing output are easier to read. Of the 4 applications only [government-frontend] uses minitest at this point, so its test suite could be converted route-by-route as it is merged into [frontend]

### Code structure
The code structure will be standardised. As well as using the [default Rails directory structure], we propose the following standard for additional classes (e.g. services, api calls). The standard expands on the [conventions] documented in the developer docs.

The host app will follow the default MVC structure of Rails applications, with some additional restrictions on what goes where that are frontend specific (listed below)

```
├── app
│   ├── assets
│   ├── controllers
│   ├── helpers
│   ├── models
│   ├── presenters
│   ├── views
├── config
│   ├── data
│   ├── locales
├── lib
│   ├── tasks
└── .gitignore
```

Under `/app`:

`helpers`
- General utility methods for a view.

`models`
- Frontend apps do not have database records, so models here are created to store data received from api calls (eg content items from content store), process data that will be written to apis (eg feedback items to zendesk), and information ingested from YAML/JSON/CSVs.

`presenters`
- Presentation related transformations on model data. It is a wrapper around a model for use in a view.

Under `/lib`

`tasks`
- Rake tasks

Use `lib` rather than `app/lib` for custom code that enhances the app but doesn’t fit into a directory in `app`

Under `/config`

`data`
- YAML, JSON, CSV config files. Data files should be placed here rather than under `/lib/data`.

`locales`
- Static content like lists of contact information should ideally be stored in the locale files to promote localisation.

Namespaces will be used to group functionality e.g. for StepBySteps, and resources in the routes file. This structure will be documented in README of the host app.
Each application will be analysed before being consolidated to ensure redundant code is not being moved over.

### How the proposal will be carried out
This is obviously a very large piece of work that will take some time to complete. We have identified the following steps that will be needed.

* Prepare `frontend` to be the host
    * audit `frontend` and make changes to the frontend directory structure to match “new layout”
    * remove redundant code from frontend (non-blocking)
    * remove publishing_api tasks from frontend (non-blocking)

* Write a roadmap for app consolidation
    * will be handled separately
    * might be simply the order in which applications will be merged into the host
    * or could be some apps merged together before merging into the host
    * or some routes merging ahead of others
* Consider and work on expected issues (see below)
* Work to merge remaining apps

### Steps as part of a merge
We anticipate that any merge will likely involve some or all of the following steps.

* Identify any issues with existing code
    * size these issues
    * either fix issues or record them as tech debt - we need to avoid trying to fix everything and concentrate on progressing consolidation
* Replicate the rendering from the candidate to the host
    * preserve the git history of the candidate app - add a permalink to the files being consolidated in the commit in the host app.
* Change content api
    * change the rendering app for the document type in the publishing app.
    * republish content
    * republish any special routes (things that don’t have a publishing app, like the homepage) - any special routes should be moved into special route publisher (we have an outstanding tech debt card relating to this)
* Optimise the frontend code
    * remove duplication
* Remove the routes from the candidate
* [Retire the candidate] once all routes have been removed

### Expected issues
Merging these four apps is not without difficulties and we acknowledge that a single app will present problems that our multiple apps do not.

* A Rails update for one larger app might be more complex than spread across individual apps.
* It won’t be possible to scale targeted parts of the stack (i.e. one of the existing apps) for expected increases in traffic.
* It’s only possible to test one branch of code in a test environment at once. If there’s only one repo for these four apps, only one change can be tested at a time.
* It will be harder to find the pull request history for the retired repositories.

In addition, we will need to address the following issues:

* The test suite will take longer due to more tests.
    * could potentially parallelise in CI
    * will need to consider approach for developer machines
* Need to reconfigure Kubernetes deployment. We should be able to drop the total number of pods.
    * optimise the number of pods needed in draft and production
    * currently in production there are
        * 4 pods for `frontend`
        * 6 for `government-frontend`
        * 4 for `collections`
        * 9 for `finder-frontend`
* Resolve the question around environment testing
    * rather than testing on integration, we should still be able to test multiple branches using preview apps
    * would need to get new search working in the preview apps

### After merging
Once a candidate has been merged, the following steps would be needed.

* Recalibrate Kubernetes deployment
* Move components from govuk_publishing_components into the app if only being used in the frontend
    * this information can already be found in our component auditing tools
    * need to consider which ones are used by publishing applications
* Update component auditing
* Decide how to handle app ownership and maintenance and what that means now we have fewer apps.
* Consider renaming `frontend`

[collections]: https://github.com/alphagov/collections
[finder-frontend]: https://github.com/alphagov/finder-frontend
[frontend]: https://github.com/alphagov/frontend
[government-frontend]: https://github.com/alphagov/government-frontend
[smart-answers]: https://github.com/alphagov/smart-answers
[static]: https://github.com/alphagov/static
[content-store]: https://github.com/alphagov/content-store
[search-api]: https://github.com/alphagov/search-api
[router]: https://github.com/alphagov/router
[router-api]: https://github.com/alphagov/router-api
[router and router-api]: https://docs.google.com/document/d/12IZ-wLJWZ8LqLuu9uRlOJRmuv3_yyaFdHYaz5enegfA/edit#heading=h.vl3h3daotiu2
[compatibility with the Mongo driver]: https://github.com/alphagov/router-api/pull/593
[use PostgreSQL]: https://trello.com/c/dOXADTQP/1802-spin-up-a-separate-stack-of-router-api-l
[slimmer]: https://github.com/alphagov/slimmer
[govuk_publishing_components]: https://github.com/alphagov/govuk_publishing_components
[parsed by Nokogiri]: https://github.com/alphagov/slimmer/blob/feaede3bd35bb049d2cd937852ecf1c1b0e46c2c/lib/slimmer/processors/body_inserter.rb#L17
[user research banner code]: https://github.com/search?q=org%3Aalphagov%20RecruitmentBannerHelper&type=code
[recent incident]: https://docs.google.com/document/d/1Owm-6WB7m3zAECY3Z4zxkvqRVNzA0mcrE-8Ut3SCNQA/edit#heading=h.p99426yo0rbv
[multiple frontend applications use the same translated phrases]: https://trello.com/c/HvDS54hm/26-multiple-frontend-applications-use-the-same-translated-phrases
[rails conventions for controllers]: https://guides.rubyonrails.org/action_controller_overview.html
[frontend]: https://github.com/alphagov/frontend
[government-frontend]: https://github.com/alphagov/government-frontend
[modernising the tests]: https://github.com/rspec/rspec-rails?tab=readme-ov-file#system-specs-feature-specs-request-specswhats-the-difference
[preferred testing suite]: https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html#testing-utilities
[default Rails directory structure]: https://guides.rubyonrails.org/getting_started.html#creating-the-blog-application
[conventions]: https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html#organising-your-code
[Retire the candidate]: https://docs.publishing.service.gov.uk/manual/retiring-an-application.html
[RFC-174]: https://github.com/alphagov/govuk-rfcs/pull/174

