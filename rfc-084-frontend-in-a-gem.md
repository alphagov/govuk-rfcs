# Replace Static by a gem

Summary: This RFC proposes replacing the current system of sharing frontend code (via the Static application) with a system where we use a gem to do the same.

## Background

The system GOV.UK uses to share frontend code works like this: frontend applications use a [gem called Slimmer](https://github.com/alphagov/slimmer). Slimmer provides templates (layouts) and [GOV.UK components][cmps] to the Rails application by fetching a raw ERB template from the [Static application](https://github.com/alphagov/static). The template links to JS and CSS files that are also hosted by Static. This means that frontend changes can be rolled out across GOV.UK by changing and deploying Static. A number of caching layers make this approach performant. Slimmer makes changes to the rendered HTML like [adding meta tags][tags].

[cmps]: https://github.com/alphagov/static/blob/master/doc/static-components.md

## Problems with current approach

1. We can't test if the application actually works correctly with updated layout or components. If a component in Static is updated, we have to test applications to see if they still work. This can be done by rolling out the change on integration and see if the Smokey tests pass, or perform manual testing. Smokey is very high level and doesn’t have much coverage and manual testing is time-consuming and imprecise.
2. Doesn't allow interaction in tests. To prevent a dependency on a live service in tests, we stub out components in the test environment - they don’t render HTML, but dump the component input onto the page. Tests use this data to make sure that the input to the component is correct. This means we have to trust that the input to the component won’t change, there’s no explicit contract between the app and component.
3. Caching. There are a number of caching layers for components. This means that when a new version of Static is released, sometimes the HTML changes are still cached, but the new CSS and JS are returned to the user. This can cause unexpected results.
4. Forces awkward code in Static. Because we ship ERB templates, all logic needs to be embedded in the template. This forces us to [write code that we know goes against best practices][analytics-code] and style guides. To prevent this the [govuk_navigation_helpers gem](https://github.com/alphagov/govuk_navigation_helpers) was created to generate the input for the components.
5. Considerable learning curve for the architecture. Shipping raw ERB templates is not a well known technique in the industry. This causes a steep learning curve for new developers on GOV.UK.

[analytics-code]: https://github.com/alphagov/static/blob/master/app/views/govuk_component/analytics_meta_tags.raw.html.erb

## Proposal

Each frontend application will depend on 1 gem, `govuk_frontend_foo`. This gem:

- Provides the components with the JS/CSS
- Provides layouts (using components)

## Trade-offs & costs

There are 2 main costs associated with the proposal:

### Deployment

For each global change to the front end gem, we have to update and deploy all frontend applications.

We can mitigate this by:

- Implementing automated PRs for gem upgrades
- Add monitoring to prevent version drift
- Schedule regular weekly deploys
- Making it easier to deploy
- Making sure we only put global things into the gem. Things that are only used once can stay in the frontend application

### Duplicated asset downloads

Because there’s no more shared Javascript/CSS, each application will need to bundle everything it needs to render. For example, this means each application will ship their own version of jQuery to the user. This will make it slower and more data-expensive for a user to use the site.

Possible mitigations:

- "Deploy the gem". Every time a new version of the gem is released, we deploy the resulting bundle. The result will live on something like `assets.publishing.services/gem-foo-2.1.0/*`.
- Put large libraries and fonts separately on a CDN. In test environment we use a local copy, but in production we reference the external copy.

## Implementation

(Likely to change)

1. Add a component to [govuk_publishing_components][] to test that it works
1. Make sure all applications use govuk_publishing_components
1. Move existing components from Static to govuk_publishing_components

Second phase:

1. Solve the duplicated assets problem (above)
1. Create components for layouts
1. Migrate applications to component-based layout
1. Retire static

[govuk_publishing_components]: https://github.com/alphagov/govuk_publishing_components

## Alternatives considered

### Improving current system

Each of the problems mentioned can be mitigated or solved. For example, we can use the production Static in test runs.

### Use HTML fragments API

Another approach would be to start returning rendered HTML instead of Static. This is what what was [proposed in RFC71][rfc71].

[rfc71]: https://github.com/alphagov/govuk-rfcs/pull/71
[tags]: https://github.com/alphagov/slimmer/blob/master/lib/slimmer/processors/metadata_inserter.rb
