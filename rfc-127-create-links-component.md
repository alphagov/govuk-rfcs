# Links component in GOVUK Publishing components

## Summary

Create a HTML hyperlink component to standardise the use of links within GOVUK.

## Problem

Links styles across GOVUK are not consistent and often security factors are not considered when using links within GOVUK. This is often due to the lack of frontend developers available in teams. 

Sometimes security issues are not known by Developers and fixing them across multiple applications can add a lot of techincal debt - one recent example is the `target="_blank"` vulnerbility (https://www.manjuladube.dev/target-blank-security-vulnerability). Use of `target="_blank"` can be seen here: https://github.com/search?q=org%3Aalphagov+%27target%3D%22_blank%22%27&type=Code

There are also certain styles that have been introduced in GOVUK that does not exist in the GOVUK Frontend Design system.

<img src="https://raw.githubusercontent.com/alphagov/govuk-rfcs/add-components-link/rfc-127/Screenshot%202020-06-15%20at%2016.37.10.png" />

GOVUK Design system docs on links: https://design-system.service.gov.uk/styles/typography/#links

## Proposal

Add new hyperlink component into the GOVUK Publishing components.

The component should include:
- GOVUK Design system styles
- Security attributes for using different types of links
- Different types of link such as: Destructive, Inverse etc.

### Implementation plan

1. Create component
2. Start using new component going forward for all links
3. Decline any new PRs which do not use the component
4. Migrate all links within applications to use component
