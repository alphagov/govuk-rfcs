---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# 144 More reliable emergency banner deployment

Author: Bill Franklin\
Date: November 2021\
Deadline: 1 December 2021

## Summary

When we publish the [emergency banner], we clear several caches which contain
the Static templates, with the intention that the banner will appear on all
www.gov.uk pages immediately.

Cache invalidation is complex and hard to debug, and is not a suitable tool for
displaying content immediately across the site.

Importantly, GOV.UK is not required to display the banner _immediately_.
There can be a 15 minute delay between publishing the banner and the banner
appearing on all www.gov.uk pages.

Proposed in this RFC:

1. we will reduce TTLs on pages to a consistent 5 minutes
1. we will not invalidate caches when updating the emergency banner, instead we will wait for 10 minutes

[emergency banner]: https://docs.publishing.service.gov.uk/manual/emergency-publishing.html#header

## Context

For greater reliability GOV.UK runs several caches.

At the edge, we run two main caches:

- Fastly (CDN) caches all www.gov.uk pages, which honours the [Cache-Control]
  header provided by Origin applications.
- The [mirror cache] crawls www.gov.uk and stores all pages in multiple S3 buckets
  and Google GCS for failover purposes when an Origin service is down and the
  Fastly grace period for cached content has ended.

On our Origin servers, we make use of several caches:

- Varnish (self-hosted on cache machines) also caches all www.gov.uk pages
  served by Frontend apps.
- Frontend apps use the Rails cache (backed by Memcached, Redis, or File cache)
  to [cache templates] served by Static for [60 seconds][slimmer-cache].
- Static templates are [cached][static-cache] a fourth time by the Static
  application, to enable Nginx to serve the templates.

## Problem

The emergency banner deploy process is unnecessarily fragile and hard to debug
due to the "display banner instantly" feature.

The "display banner instantly" feature is implemented using cache invalidation.
After updating the Static templates to include the emergency banner text,
the Jenkins job does an in-order purge of four layers of caches in which the
Static templates are stored.

The feature is necessary only because www.gov.uk pages generally set a cache TTL
of 30 minutes and we have assumed that emergency banners need to be displayed instantly.

The "display banner instantly" feature is not required, and when our
implementation (cache invalidation) fails it has been hard to debug.

[mirror cache]: https://docs.publishing.service.gov.uk/manual/fall-back-to-mirror.html
[Cache-Control]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching#the_cache-control_header
[cache templates]: https://github.com/alphagov/slimmer#caching
[slimmer-cache]: https://github.com/alphagov/slimmer/blob/b66fcbe9b667b2d946c5922ef42e619a6366c278/lib/slimmer.rb#L10
[static-cache]: https://github.com/alphagov/static/blob/main/app/controllers/root_controller.rb#L8

## Proposal

The following commitments aim to make the emergency banner deploy process more
reliable:

* We will remove the "display banner instantly" feature from the
  Deploy Emergency Banner job.
  This will involve removing the four cache invalidation sub-jobs.
* We will ensure that the emergency banner is displayed within 15 minutes.
  This will involve reducing the default caching time for GOV.UK pages from 30m to 5m.
  We will make all frontend apps observe the Content Store max-age directive on
  content items and will discourage having a cache TTL longer than 5m.
  We will automatically expire Static templates every 5 minutes.
* We agree that HTTP cache invalidation should be avoided.

### Reason for changes

**Reducing the default max-age for cached pages**

The emergency banner can be displayed within 15 minutes.
By reducing the TTL on all pages to 5 minutes or less, the emergency banner will
be displayed on www.gov.uk within 15 minutes.

This max TTL will not apply to Asset Manager resources such as PDFs.
Asset Manager is out of scope since assets are not rendered using Static templates.

**Consistent TTL on cached pages**

Currently the max-age directive for www.gov.uk pages is set to between
[5 seconds][random] and [12 hours][info-pages].
Most pages have a 30 minute TTL.

To make it easier to debug caching behaviour it is important that the `max-age`
directive for pages on www.gov.uk is consistent.

This will be achieved by changing the default `max-age` [set at Content Store][content-store-max-age]
to 5 minutes, and auditing frontend applications to ensure that this is honoured.

This could also be achieved by adding configuration to the govuk_app_config gem
or merging the frontend apps and retiring Static.
Some frontend apps already use Content Store's max-age directive so this is
the most straightforward way to achieve a consistent TTL on www.gov.uk pages.

[random]: https://github.com/alphagov/frontend/blob/2ecb332e1e9ddabd865cb8dadb42f70e9453694e/app/controllers/random_controller.rb#L20
[info-pages]: https://github.com/alphagov/info-frontend/blob/fad9a539f7b933c8a13a4d915de17d486c2beb7b/app/controllers/application_controller.rb#L18
[content-store-max-age]: https://github.com/alphagov/content-store/blob/a4ea0b2b29dec4d39423ecc6b62d257b37031662/app/controllers/content_items_controller.rb#L117-L131

**Removing cache invalidation logic from Emergency Banner Jenkins job**

Once the TTL on www.gov.uk pages is reduced to 5 minutes it will not be necessary
to purge the frontend application, CDN, or Varnish caches.

Therefore we can remove the cache-invalidation jobs from the Emergency Banner
Jenkins job.

Unfortunately Static's template cache does not automatically expire.
This requires us to run `rm -rf /public/templates` on all `frontend` machines
when updating the emergency banner.
To fix this we can have Static automatically expire the template cache every
5 minutes as implemented in https://github.com/alphagov/static/pull/2659.

## Consequences of proposals

### Pros

1. It will be simpler to explain how caching works: caches expire within
  5 minutes; the banner will appear on www.gov.uk pages within 10 minutes.
2. We won't need to maintain or debug cache invalidation behaviour

### Cons

1. It will take at least 5 minutes for the emergency banner to appear on www.gov.uk
1. For 5 minutes after deployment the emergency banner will appear on some pages
  but not on others as the objects in the CDN cache gradually expire.
1. Invalidating caches may become harder
1. Lower cache hit rate: At worst Origin may see a 6x increase in traffic.
  The increase is likely to be substantially lower than this, given most traffic
  is to extremely popular pages such as `/universal-credit`, and `/coronavirus`.
  We will monitor the effects on performance when rolling these changes out.

As caches expire, the banner will gradually appear on pages within a 10 minute window.
The "staggered" rollout of the banner is acceptable, but could be improved upon
if this becomes a requirement.
If we want the banner to appear immediately on all pages, we should not use
cache invalidation to achieve this.
Cache invalidation is hard to get right, particularly when the objects we wish
to invalidate exist in four layers of caching (and more than a dozen caches),
as we have seen in incidents related to cache invalidation.

Rather than using cache invalidation to immediately display a banner on all pages
we should implement this feature in another way.
It is out of scope of this RFC to discuss how this feature might be provided.

## Implementation

Detailed implementation information is out of scope for this RFC.

This work will be completed by Bill Franklin, as part of the Platform Reliability
service team. We anticipate this work should be completed in 1-2 weeks.

This is an operational change for GOV.UK Content Designers, so we will need to
do appropriate comms when making this change.

## Thoughts on future

This RFC could go further and address other cache challenges. These problems
are beyond the scope of the problem this RFC is seeking to solve.

When TTLs on pages are lower, there will be a stronger argument for retiring
the [cache-clearing-service] and other cache invalidation jobs.

A longer term solution for making Static less dynamic or replacing Static
is out of scope of this RFC.

[cache-clearing-service]: https://github.com/alphagov/cache-clearing-service
