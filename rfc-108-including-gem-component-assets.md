# Include specific component assets in applications

## Summary

The govuk_publishing_components gem provides shared components to frontend applications on GOV.UK - chunks of consistent and reusable frontend such as buttons and form elements.

The gem only allows all components to be included in an application, even if they're not used by that application. This RFC proposes changing the gem to allow only required components to be included, to reduce unnecessary page weight.

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

This solution would allow us to add any components we like to the gem without worrying that they are needlessly adding page weight to the publically facing GOV.UK.

We will configure the gem so that both this new approach to consuming Sass and the old approach co-exist, so we don't have to upgrade all the apps at once. The component guide itself will import all of the component scss to ensure everything appears correctly.

### Javascript

We should also be able to include only the required Javascript in each application. Specific JS modules must be initialised (unlike with Sass) and the specifics of how this will work have yet to be determined. However, if a change to this proves impractical, we could continue to use the current approach - this will not block the rollout of changes to the Sass model.

Currently some component JS relies upon jQuery and some does not. We will therefore need to include jQuery if component JS is required. Eventually we plan to remove this dependency, at which point this can be looked at again.

Testing should remain broadly the same. Tests will exist for each component and when the tests are run in the gem all tests should be run. We might need to rewrite the initialisation for some of the Javascript tests depending on decisions made regarding JS inclusion.

We will configure the gem so that both this new approach to consuming JS and the old approach co-exist, so we don't have to upgrade all the apps at once.

### Finding which components are in use

Adding a not-in-use component into an application with this new model would be a relatively safe procedure, as the developer would notice immediately if the styles and Javascript for that component had not been included in the application. For the future we will need a tool avoids leaving components unstyled or non-functional.

We can modify the component guide to tell us which components are in use by the current application.

We could also write a test for that application to ensure the right assets are being included. This test would need to be kept up to date as components are added and removed.

### Certainty that a component renders correctly in isolation

If the gem is changed as proposed we would need certainty that components will render correctly in isolation. At the moment the CSS for all components is included as a single file, so it all works.

Separating out these styles is problematic due to each component's dependence on external mixins and variables (from govuk-frontend and the gem itself). An application can `@import button` only so long as it also imports other stuff beforehand.

If we wanted to test a component truly in isolation (in the component guide page for that component) we'd need a CSS file that only included the styles for that component. The output for this would be inappropriate for use in applications (because each component will need some common Sass, which would introduce duplication).

(The Design System site shows each component inside an iframe, but this includes all component styles in the iframe, not just the styles for that specific component. Iframes also pose problems with regard to setting an appropriate height)

## Benefits and drawbacks

Benefits:

- the size of the CSS file for each application is reduced (assuming the application uses some but not all of the components. If it uses all of the current components then there's no change)
- possible compilation performance benefits
- will be backwards compatible, so we can roll it out in our own time
- component guide remains essentially the same

Drawbacks:

- inconsistent approaches to JS and SCSS
- no means to test a component is styled correctly in isolation
