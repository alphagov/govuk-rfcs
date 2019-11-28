# Include specific component assets in applications

## Problem and background

The [current method for including the components](https://github.com/alphagov/govuk_publishing_components/blob/master/docs/install-and-use.md#4-include-the-assets) in a frontend application (such as `government-frontend`) is to include `_all_components.scss` and `_all_components_print.scss` in the Sass of that application. This has some benefits:

- once the application is configured to use the gem, no further configuration is needed
- all components are automatically included in the application

This also has some detriments:

- all components are included regardless of whether they are used, so unused CSS/JS will be included
- only publically facing components can be added to the gem, or unused CSS/JS would be included (we now have components that need to be shared across only private applications that use the gem)

## Proposed solution (Sass)

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

It should be possible to configure the gem so that both this new approach to consuming Sass and the old approach co-exist, so we don't have to upgrade all the apps at once.

## Proposed solution (Javascript)

We can do something similar with Javascript, however the initialisation of specific modules may be more complicated and require more thought. Additionally knowing whether or not to include jQuery could be difficult.

It should be possible to configure the gem so that both this new approach to consuming JS and the old approach co-exist, so we don't have to upgrade all the apps at once.

## Finding which components are in use

Adding a not-in-use component into an application with this new model would be a relatively safe procedure, as the developer would notice immediately if the styles and Javascript for that component had not been included in the application. However for the future it would be useful if we had some kind of tool that helped us to avoid leaving components unstyled or non-functional.

We could search through the code base and write a test for that application to ensure the right assets are being included. This test would need to be kept up to date as components are added and removed.

We could also look at altering the component guide to either mark components in use or put them in a separate list. That way we could look at the component guide for an application and immediately know which components are in use and which are not.

## Certainty that a component renders correctly in isolation

If the component model is changed so that only some of the components could be included by an application we would need certainty that they would render correctly in isolation. At the moment the CSS for all components is included as a single file, so it all works.

Separating out these styles is problematic due to each component's dependence on external mixins and variables (from govuk-frontend and the gem itself). An application can `@import button` only so long as it also imports other stuff beforehand.

If we wanted to test a component truly in isolation (in the component guide page for that component) we'd need a CSS file that only included the styles for that component. The output for this would be inappropriate for use in applications so we might end up having two stylesheets for each component, which wouldn't be ideal.

(The Design System site shows each component inside an iframe, but this seems to include all component styles in the iframe, not just the styles for that specific component. Iframes also pose problems with regard to setting an appropriate height)

## Pros and cons

Pros:

- an application only has to include the components it needs
- the size of the CSS file for each application is reduced (assuming the application uses some but not all of the components. If it uses all of the current components then there's no change)

Cons:

- we have to be vigilant to ensure components in applications are included properly and not accidentally removed

Unanswered questions:

- how do we include only the required Javascript?
- how does the component guide look in an application that is only using some of the components? Do those unused components appear unstyled? Or not appear?

## Implementation

### Testing

Testing should remain broadly the same. Tests will exist for each component and when the tests are run in the gem all tests should be run. We might need to rewrite the initialisation for some of the Javascript tests depending on decisions made regarding JS inclusion.

### Backwards compatibility

For a new release we could keep the existing `_all-components.scss` file so we don't break any applications that still rely on it. This would be removed at a later date once all applications have been updated to use the agreed new system.

## Next steps

Spike it locally.

