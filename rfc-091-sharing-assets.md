---
status: unclear
implementation: abandoned
status_last_reviewed: 2024-03-04
status_notes: We're currently thinking about consolidating apps as a better alternative to changing the way we share assets.
---

# Sharing assets

## Summary

We need to share assets to make sure users only have to download a thing once. To do this, we'll upload each application's assets to the same location.

## Problem

In [RFC84 we proposed replacing Static with a gem](https://github.com/alphagov/govuk-rfcs/pull/84). One of the architectural challenges with this approach is that by moving assets (like CSS, JS and images) into the gem, the assets won't be shared for users. This means that users visiting GOV.UK would have to download assets multiple times, depending on what app renders the page.

## Proposal

We upload the assets to a central location. For example, if both `collections` and `government-frontend` have a file named `foo.css`, they will upload the file to `assets.publishing.service.gov.uk/shared/foo.css`.

Because [Rails fingerprints assets](http://guides.rubyonrails.org/asset_pipeline.html#what-is-fingerprinting-and-why-should-i-care-questionmark), the asset actually uploaded will be `assets.publishing.service.gov.uk/shared/foo-8d811b8c3badbc0b0e2f6e25d3660a96cc0cca7993e6f32e98785f205fc40907.css`, unless the files are different, in which case they'll have different fingerprints and won't overwrite.

As part of this solution we'd need a way to ensure or encourage different frontend apps to use assets in a way that is shareable. For example, applications could include a separate stylesheet with all the component styles (`components.css`), which would be shared across apps.

How to achieve this:

* In govuk-app-deployment, we configure capistrano to precompile the assets and then upload the resulting files to a central location.
* Proxy assets.publishing.service.gov.uk/shared to this location
* Point applications to use this URL as asset host so that it's used in production

Upsides

* We remove Nginx config to proxy to individual applications, perhaps removing some hops
* Whenever there's an asset to share, it will be shared automatically. If an application copies an image from another app, on production they'll have the same URL.
* Each application ensures that its own assets are present on the shared bucket.
* Applications don't serve files anymore.

Downsides

* We'll end up with a directory full of assets which are of unknown origin.

## Alternatives

### 1. Do nothing

The simplest solution is to not share assets between applications. This would have significant impact on the user, especially if the font will be distributed in the gem.

### 2. Deploy the gem

This would work roughly that every time we publish a new gem version, we'll deploy the resulting assets to a central place. In production apps point to that shared asset URL instead of

* Disparity between development and production
* Inevitable deploy dependency - the gem deploy needs to happen before the application is deployed
