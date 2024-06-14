---
status: proposed
implementation: proposed
status_last_reviewed:
---

# Consolidate Frontend Apps

## Summary
We have too many frontend rendering applications. This increases complexity, reduces understanding and slows development. We propose consolidating our apps into a single app. This will improve standardisation, reduce maintenance costs and improve the developer experience.

## Problem

### Applications overview
GOV.UK is served by multiple rendering applications (apps). Each app serves different groups of pages within the website.

There are currently 8 rendering apps for GOV.UK that are supported and maintained by GOV.UK teams:

1. [collections]
2. [email-alert-frontend]
3. [feedback]
4. [finder-frontend]
5. [frontend]
6. [government-frontend]
7. [smart-answers]
8. [static]

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
Code dependencies are managed automatically through github with dependabot. Often a dependabot PR will be raised in each app, meaning that developers need to approve and merge that PR 8 times.

Many dependabot PRs are now automatically merged, but each app is deployed separately. This means that changes that impact users can lead to brief periods of visual inconsistency. It also makes deploying breaking changes (particularly where `static` is involved) more difficult.

Rails upgrades must also be repeated separately for each app. These upgrades can often involve a lot of work, particularly for major releases. This is especially problematic for applications that are less well maintained, have slightly different ways of doing things or are harder to test.

### Deployments can be overly complicated
Our current setup means that code changes often occur in one app and therefore several deployments must be carried out together to ensure that the user experience across the site remains consistent. This is difficult to achieve precisely because each application is different and can take a different amount of time to deploy.

This will likely be an issue when deploying any upcoming changes to the GOV.UK brand.

### Inconsistent testing approach
The test suite is inconsistent across the rendering applications, which means that developers need to be familiar with more test suites than necessary, increasing the maintenance burden.

Some apps use RSpec while others use Minitest. Some use Jasmine, some Cucumber and some Mocha. Many use the old controller tests, some have request tests, and some have both.

Even when applications use the same testing frameworks there are still a lot of inconsistencies in how the tests are set up, for example in how fixture files are used, or how `content-store` and `search-api` are stubbed.

### Duplicated assets and complex asset model
Our assets (CSS and JavaScript files) are well optimised but having multiple apps means that some problems remain. If a user journey involves more than one app this means that duplicate page assets can be downloaded, reducing the speed of the site.

For example if a user visits a page in one app that requires the button component CSS and then moves to a page on another app with the same component, that CSS file is downloaded once per page, rather than once.

We aim to build our pages and assets to be as performant as possible, but repeated downloads invalidate some of that effort. This situation happens for any repeated components across the estate, where each app will re-deliver CSS and JavaScript to the user unnecessarily.

### `router` / `router-api` are complicated and hard to maintain
[router] routes requests for pages on the site to the correct application. `router` is complicated and hard to maintain. Moving towards a single application will remove the need for `router` entirely.

`router` is a Go application that copies a database of URLs on GOV.UK from another application called [router-api]. `router` uses that database to route requests to the correct rendering application.

Go is not a language that many developers on GOV.UK are comfortable with, which makes updating the application harder.

The relationship between [router and router-api] is quite tangled. `router-api` is a Ruby on Rails application. The database that it shares with router is a Mongo database.  The version of Mongo we’re using is an old one, and has had to be pinned to keep [compatibility with the Mongo driver].

`content-store` registers routes in `router-api`. This means that the same content data is stored in multiple places and has the potential to get out of sync.

There was an attempt to switch `router-api` to [use PostgreSQL] but this was paused indefinitely due to other priorities and the complexity of the work.

### Local preview and sharing changes to GOV.UK is difficult
Manually testing user journeys from a page is difficult, particularly where code changes are spread across more than one application. To test locally, developers have to have multiple applications running which slows down their local machines.

Having fewer apps would also mean that GOV.UK Docker, our system for running apps locally, could be simplified or potentially removed entirely.

Sharing changes for non-engineering disciplines to preview is also difficult. This can be done by deploying branches to integration, but these branches are frequently overwritten by dependency updates.

We can use Heroku for previews but this is also complicated by multiple apps. Previewing a user journey that involves pages from more than one app cannot be done in Heroku because links from a page in one app do not link to another. For example, a journey from the homepage to a search page and then a mainstream browse page crosses multiple app boundaries, and the links would 404 in Heroku. Previews can be done using Heroku, but this would be greatly simplified by having only a single application.

### `static` and `slimmer` are complicated and inflexible
GOV.UK page layouts are rendered by `static` using the [slimmer] gem. This includes the header and footer common to all pages, even though the code for those elements comes from [govuk_publishing_components]. Having a single application would allow us to remove our dependency upon `static`.

`static` and `slimmer` are both quite complicated and not well understood among the current developer community. The details are beyond the scope of this document, but several specific problems can be identified.

#### The system is not designed for dynamic content
The page template generated by `static` is passed as a string which is then [parsed by Nokogiri] into an object. This means that the header and footer can’t be dynamic without complex workarounds. This has presented problems with any efforts to integrate www.gov.uk with the One Login programme.

#### Code locations are scattered
The code for the page layout consists of components from `govuk_publishing_components`. Unlike other components that are called from applications directly they are rendered by `static`. This is overly complicated - if there was a single app, the layout components for that app would be included in it, and making changes would involve a single pull request. Currently this involves 3 pull requests, including publishing a new version of the components gem.

##### Case study
The recent upgrade from Universal Analytics to Google Analytics 4 (GA4) often involved far more complexity than would be needed with a single application. The analytics code lives in `govuk_publishing_components`, but is included in `static`, and directly called through components in `govuk_publishing_components`, that are included in applications.

This meant that for some changes to the GA4 code, a total of 5 pull requests were involved, far more than would be needed with a single application. These were: code change in the gem, new release of the gem, dependabot PR in static, dependabot PR in the application plus change to the application.

This also complicated testing because our local development environment of GOV.UK Docker is prone to caching issues where changes in JavaScript are not visible. In extreme cases the only way to ensure changes were visible was to completely rebuild the docker environment, which on slower machines could take hours.

#### Common layouts, but duplicated code
Some code is duplicated across our architecture. The [user research banner code] is duplicated in four apps because it is rendered in the body of our pages and can’t be rendered in one place by `static`.

#### Making changes to the layout is hard
Having more than one application makes changing the layout far more complicated than necessary.

##### Case study
The action required in a [recent incident] was to remove an email form field from the feedback component in the footer of all pages and replace it with a link to a survey. This fix should have involved two simple steps: remove the offending form field, and get the URL of the current page and include it in a new link. This should have been easy, but took three lead developers and two 2nd line developers five hours to implement.

This was because of the time it took to get the frontend stack running locally to be able to test the changes. It required a local application pointing at a local version of static, each using a local version of `govuk_publishing_components`. The feedback form is part of `govuk_publishing_components, but part of the layout called from static.

This was also because the feedback form included custom JavaScript to get the current page URL. This was not clear to those handling the incident and caused a delay in solving it. With a single application, the current page URL could be handled internally with standard Ruby helpers, making the implementation and solving the problem far simpler.

### Translations
There is existing tech debt for [multiple frontend applications use the same translated phrases]. These are some of the existing issues that will be addressed by having a single rendering app:

1. Different pages on the site can have different translations for the same English word
2. Some translations will be missing on pages rendered by different frontend applications
3. Difficult to get visibility on which phrases are translated and which ones aren't

## Proposal

We propose merging the apps into a single rendering app. This will solve some of the issues in this RFC and allow us to solve others in the future - for example, removing `static`.

We propose merging all apps into an existing app. The benefit of this is that even if we aren’t able to consolidate all of the applications, we would still reduce the maintenance burden for each app merged. We also won’t have created anything new, and won’t have to manage any extra conflicting patterns.

We can steadily move routes, controllers and models from the candidate (the app being merged) into the host (the app we are merging into) until the host is serving all the routes.

We propose using [frontend] as the host app. This is because:

* `frontend` contains some of the more complicated document types like licence_transaction and local_transaction, that have multiple pages and interactive elements, which would be harder to consolidate into another app
* `frontend` has a one-controller per document type layout, which is preferable for document types with multiple pages as it follows [rails conventions for controllers] to do the orchestration.

[government-frontend] was also considered for the host app, but not chosen because it has a more restrictive presenter pattern that works well for single-page document types. Even though `government-frontend` has many document types and accounts for 50% of the frontend traffic, it would be easier to move the single-page document types from `government-frontend` to `frontend` than it would to try and force the document types in `frontend` into the presenter pattern.

### Testing standardisation
We propose standardising around RSpec as the test suite for the frontend, ideally [modernising the tests], for example by switching to request tests rather than controller tests and system tests rather than feature tests. RSpec is the [preferred testing suite] on GOV.UK and is favoured by many developers because the tests and testing output are easier to read.

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
│   ├── services
│   ├── views
├── config
│   ├── data
│   ├── locales
├── lib
│   ├── tasks
└── .gitignore
```

Under `/app`:

`models`
- Frontend apps do not have database records, so models here are created to store data received from api calls (eg content items from content store), process data that will be written to apis (eg feedback items to zendesk), and information ingested from YAML/JSON/CSVs.

`services`
- Api calls for search and content-store, and apis external to GOV.UK

`presenters`
- Presentation related transformations on model data. It is a wrapper around a model for use in a view.

`helpers`
- General utility methods for a view.

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
    * convert frontend tests to RSpec
    * modernise the tests
    * audit `frontend` and make changes to the frontend directory structure to match “new layout”
    * remove redundant code from frontend (non-blocking)
    * remove publishing_api tasks from frontend (non-blocking)
* Merge `feedback` into `frontend`
    * use as a test case and use that to inform our next steps
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
Merging all of our apps together is not without difficulties and we acknowledge that a single app will present problems that our multiple apps do not.

* A Rails update for one large app might be more complex than spread across individual apps.
* The scaling of a single app might become more costly.
* It won’t be possible to scale targeted parts of the stack (i.e. one of the existing apps) for expected increases in traffic, instead the whole site will need to be scaled.
* It’s only possible to test one branch of code in a test environment at once. If there’s only one repo, only one change can be tested at a time.
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
        * plus 2 or 3 per app for the others
    * scaling up the pods for a single app will use more resources
* Resolve the question around environment testing
    * rather than testing on integration, we should still be able to test multiple branches using preview apps
    * would need to get new search working in the preview apps

### After merging
Once a candidate has been merged, the following steps would be needed.

* Recalibrate Kubernetes deployment
* Move components from govuk_publishing_components into the app if only being used in the frontend
    * this information can already be found in our component auditing tools
    * need to consider which ones are used by publishing applications
* Begin work to remove static, slimmer and router (to be considered separately from this RFC)
* Update component auditing
* Decide how to handle app ownership and maintenance and what that means now we have fewer or only one app
* Consider renaming `frontend`

## Other options to explore

We write this knowing that new technologies are constantly emerging that may prove useful in this area. One such technology is [Rails Engines], which allows you to wrap a specific Rails application or subset of functionality and share it with other applications or within a larger packaged application.

As a separate piece of related work, we propose exploring Rails Engines as follows.

### Option 1: Engines in existing app
To consider converting the existing apps into engines that can be mounted inside a single host app. This would allow us to keep separate repos for each current application while still simplifying the overall architecture.

Advantages of Engines:

* Separate repos provide a natural encapsulation of code/tests, meaning that a test suite could be kept for just the routes mentioned in the engine, keeping test suites run times lower.
* As with a monolith, Layouts could be in the “host” app, simplifying the engine code and allowing us to remove the static/slimmer app/gem complexity.
* As with a monolith, the single host app would be the only one that had to be deployed, allowing us to reduce the number of apps/config in Kubernetes.
* Re-engineering into engines would allow us to split functions in a more granular way than they have been with apps - for instance, it might make sense for frontend to be more than one engine, perhaps an engine for homepage, an engine for simple smart answers, and an engine for location-based content types like places and local_transactions, etc.

Disadvantages of Engines:

* We’d still have to know exactly which engine served a given route, so there’s still a little knowledge overhead in working out where changes/fixes would need to be made.
* Little existing experience with engines in GOV.UK (the component guide is an engine, but it doesn’t get changed much and isn’t used outside of development)

### Option 2: Engines in new app
If option 1 proves fruitful, we’ll consider whether it’s feasible to make a generic host app (either an existing app  hollowed out, or a new app) that can host a configurable number of engines. This would give us the advantage of the engine system but with the ability to scale a little more granularly (if most traffic was going to the finder engine, an app which only included the hosting engine could be deployed, allowing scaling of only finder functionality). It’s worth noting that there would be routing implications for this solution, so it’s not necessarily a viable option.



[collections]: https://github.com/alphagov/collections
[email-alert-frontend]: https://github.com/alphagov/email-alert-frontend
[feedback]: https://github.com/alphagov/feedback
[finder-frontend]: https://github.com/alphagov/finder-frontend
[frontend]: https://github.com/alphagov/frontend
[government-frontend]: https://github.com/alphagov/government-frontend
[smart-answers]: https://github.com/alphagov/smart-answers]
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
[Rails Engines]: https://api.rubyonrails.org/v7.1.3.2/classes/Rails/Engine.html
