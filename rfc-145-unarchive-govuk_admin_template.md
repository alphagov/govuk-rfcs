---
Author: Ryan Brooks
Date: January 2022
Deadline for decision: 21st January 2022 # Placeholder, we'll give a week once the PR is ready for review
---
# Unarchive govuk_admin_template Bootstrap project
## Summary

The [govuk-admin-template](https://github.com/alphagov/govuk_admin_template) gem has been deprecated for a while, and new GOV.UK admin applications should be built using the [layout component in govuk_publishing_components](https://govuk-publishing-components.herokuapp.com/component-guide/layout_for_admin). Ideally, we would have migrated all our applications to use the new Design System and publishing components, however there are still several in active use which still rely on govuk-admin-template. The GitHub project is archived, and is therefore read-only.

This RFC proposes un-archiving the project to allow iterative accessibility fixes to be applied to live applications.

Importantly, this RFC _does not_ propose removing the deprecation notice, or advocate for significant development of govuk_admin_template. It is intended as a stop-gap that acknowledges the slow pace of migration to the Design System, and its intention is to yield accessibility fixes for users prior to those migrations taking place.

## Problem

When [govuk-admin-template](https://github.com/alphagov/govuk_admin_template) was deprecated and made read-only back in July 2018, we anticipated projects would be swiftly migrated to the GOV.UK Design System. There are many benefits to this, and projects should still aim to be migrated.

Three and a half years on, we still have [18](#projects-using-govuk_admin_template) projects referencing govuk-admin-template. This includes many publishing apps, most prominently [Whitehall](https://github.com/alphagov/whitehall).

Several accessibility issues have been identified our publishing applications which stem from govuk-admin-template. Some of these are relatively easy fixes, however we can't apply them because the repository is read-only.

## Proposal

With the intention of enabling quick wins for some perennial accessibility issues, we propose:

1. We will un-archive [govuk-admin-template](https://github.com/alphagov/govuk_admin_template) on GitHub, making it possible to release new versions of the gem with accessibility fixes.

2. GOV.UK developers may release new versions of the gem to address accessibility and usability issues.

3. Developers are still advised to migrate pages and applications to the GOV.UK Design System where practical.

## Consequences

- By improving accessibility in the govuk-admin-template, there may be less impetus to migrate to the GOV.UK Design System. We believe the immediate benefits to users outweighs this concern. All applications are still expected to be migrated, and it's important that we retain senior management buy-in for the migration. 

- By enabling fixes in the underlying gems, we can start iteratively improving some of our oldest and most painful systems.

## Appendices

### Projects using govuk_admin_template

> It's not possible to filter archived repositories in GitHub search yet, but manually filtering [this search](https://github.com/search?p=3&q=org%3Aalphagov+%22gem+govuk_admin_template%22&type=Code) yields:

- [collections-publisher](https://github.com/alphagov/collections-publisher)
- [contacts-admin](https://github.com/alphagov/contacts-admin)
- [content-tagger](https://github.com/alphagov/content-tagger)
- [imminence](https://github.com/alphagov/imminence)
- [local-links-manager](https://github.com/alphagov/local-links-manager)
- [manuals-publisher](https://github.com/alphagov/manuals-publisher)
- [maslow](https://github.com/alphagov/maslow)
- [publisher](https://github.com/alphagov/publisher)
- [search-admin](https://github.com/alphagov/search-admin)
- [search-performance-explorer](https://github.com/alphagov/search-performance-explorer)
- [service-manual-publisher](https://github.com/alphagov/service-manual-publisher)
- [short-url-manager](https://github.com/alphagov/short-url-manager)
- [signon](https://github.com/alphagov/signon)
- [specialist-publisher](https://github.com/alphagov/specialist-publisher)
- [support](https://github.com/alphagov/support)
- [transition](https://github.com/alphagov/transition)
- [travel-advice-publisher](https://github.com/alphagov/travel-advice-publisher)
- [whitehall](https://github.com/alphagov/whitehall)
