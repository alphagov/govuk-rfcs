---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# Include specific component assets in applications

## Summary

The govuk_publishing_components gem provides shared components to frontend applications on GOV.UK - chunks of consistent and reusable frontend such as buttons and form elements.

The gem adds the CSS and JS for all components into an application, even if they're not used. This RFC proposes changing the gem to allow only required components to be included, to reduce unnecessary page weight.

## Problem

The [current method for including the components](https://github.com/alphagov/govuk_publishing_components/blob/master/docs/install-and-use.md#4-include-the-assets) in a frontend application (such as `government-frontend`) is to include `_all_components.scss` and `_all_components_print.scss` in the Sass of that application. This has some benefits:

- once the application is configured to use the gem, no further configuration is needed
- all components are automatically included in the application

This also has some detriments:

- all components are included regardless of whether they are used, so unused CSS/JS will be included
- only publically facing components can be added to the gem, or unused CSS/JS would be included (we now have components that need to be shared across only private applications that use the gem)

## Proposal

Instead of including all of the component Sass, each application should be configured to only include the components that it needs. For example, in an applications `_application.scss`:

```
// currently
@import 'govuk_publishing_components/all_components';
```

```
// proposed
@import "govuk_publishing_components/component_support";
@import 'govuk_publishing_components/components/accordion';
@import 'govuk_publishing_components/components/button';
// (etc.)
```

The component_support sass file would include any needed `govuk-frontend` imports plus any mixins or variables from sass in the gem. A similar solution could be applied to print styles for components.

This solution would allow us to add any components we like to the gem without worrying that they are needlessly adding page weight to the publicly facing GOV.UK.

The component guide will not change as it imports the sass for components itself. However it cannot give full confidence that a component will appear correctly in an application, see the isolation section below.

We will configure the gem so that both this new approach to consuming Sass and the old approach co-exist, so we don't have to upgrade all the apps at once. The old approach will then be deprecated as we migrate apps.

### Javascript

We should also be able to include only the required Javascript in each application, using a similar mechanism to the above. JS modules will be initialised using the existing code for initialisation.

Currently some component JS relies upon jQuery and some does not. We will therefore need to include jQuery if component JS is required (eventually we plan to remove this dependency).

JS tests should remain the same. Tests will exist for each component and when the tests are run in the gem all tests should be run.

We will configure the gem so that both this new approach to consuming JS and the old approach co-exist, so we don't have to upgrade all the apps at once. The old approach will then be deprecated as we migrate apps. If a change to the JS proves problematic, we could continue to use the current approach - this should not block the rollout of changes to the Sass model.

### Finding which components are in use

Adding a not-in-use component into an application with this new model would be a relatively safe procedure, as the developer would notice immediately if the styles and Javascript for that component had not been included in the application. For the future we will need a tool that avoids leaving components unstyled or non-functional.

We can modify the component guide to tell us which components are in use by the current application.

We could also write a test for that application to ensure the right assets are being included. This test would need to be kept up to date as components are added and removed.

### Certainty that a component renders correctly in isolation

If the gem is changed as proposed it would be helpful to test that all components will render correctly in isolation, but we don't know how to solve this problem now. We will rely on manual testing and vigilance until a better solution is found.

One option could be to build a page in the component guide with each component rendered in isolation using iframes, and apply visual regression testing to it. It's worth noting that components have in the past rendered correctly in the guide but not in applications due to conflicts with an application's styles, so testing in isolation cannot provide 100% certainty that a component will work outside of the guide.

## Benefits and drawbacks

Benefits:

- the size of the CSS and JS included in each application is reduced (assuming the application uses some but not all of the components. If it uses all of the components then there's no change)
- possible compilation performance benefits
- will be backwards compatible, so we can roll it out in our own time
- component guide remains the same
- we will be able to add components into the gem that are not used by the publicly facing GOV.UK, without any negative impacts

Drawbacks:

- inconsistent approaches to JS and Sass
- no means to test a component is styled correctly in isolation
