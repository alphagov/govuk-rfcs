# Service API responses should provide classes

## Summary

When frontend service make a request to a publishing service, they should,
where useful, receive classes in response.

For example, when finder-frontend requests a finder content item from
the content store, a FinderContentItem might be returned, rather than JSON.

```
content_item = GdsApiAdapters::ContentStore::ContentItem.find('/government/organisations/hm-treasury')
content_item.kind_of? GdsApiAdapters::ContentStore::ContentItem
=> true
content_item.instance_of? GdsApiAdapters::ContentStore::OrganisationContentItem
=> true
content_item.title
=> 'HM Treasury'
content_item.is_live?
=> true
content_item.first_published_at.class
=> DateTime
content_item.links.ordered_child_organisations.first.class
=> GdsApiAdapters::ContentStore::OrganisationContentItem (lazy loaded)
```

This will bring a number of benefits, including application consistency,
keeping things DRY, easier communication between services, and making API responses immutable.

## Problem

Applications repeat code to handle GdsApiAdapters responses. For example, the ContentItem class appears in a number of different apps. I found some similar implementations:

- [collections](https://github.com/alphagov/collections/blob/master/app/models/content_item.rb),
- [finder-frontend](https://github.com/alphagov/finder-frontend/blob/master/app/models/content_item.rb)
- [email-alert-api](https://github.com/alphagov/email-alert-api/blob/master/app/models/content_item.rb)
- [content-tagger](https://github.com/alphagov/content-tagger/blob/master/app/models/content_item.rb)
- [govuk_publishing_components](https://github.com/alphagov/govuk_publishing_components/blob/master/lib/govuk_publishing_components/app_helpers/taxon_breadcrumbs.rb#L47)
- [support-api](https://github.com/alphagov/support-api/blob/master/app/models/content_item.rb)
- [content-store](https://github.com/alphagov/content-store/blob/master/app/models/content_item.rb)
- [govuk-content-navigation](https://github.com/alphagov/govuk-content-navigation/blob/master/lib/ruby/content_item.rb)
- [govuk_navigation_helpers](https://github.com/alphagov/govuk_navigation_helpers/blob/master/lib/govuk_navigation_helpers/content_item.rb)
- [govuk-services-prototype](https://github.com/alphagov/govuk-services-prototype/blob/master/app/models/content_item.rb)

Benefits:

- Apps would be more consistent - easier to work with.
- Keeps apps DRY and more focused on a specific purpose.
- Would make API responses effectively immutable (dissuades manipulation of hash responses).
- Would establish a more explicit contract between services.
- Classes that mirror the schemas, like FinderContentItem or PeopleContentItem,
  would make it easier to implement specialist behaviour across services.
- We could add ActiveRecord-like behaviour to classes returned by GDS API,
  like `ContentItem.find(:content_id)`.
- Repeated logic, like cacheing and statsd timers. E.g. finder-frontend caches content items,
  and monitors response times for content items but we want this implemented in
  more places (needed to do this in each app).
- Easier monitoring of performance of requests (as above).
- Can lazy load links / taxons and so on as classes. Makes it easier to get linked
  stuff. E.g. Education child taxons can be lazy loaded in:
  `ContentItem.where(path: '/education').child_taxons`.

Cons:

- It's a lot of setup work.
- We may end up with lots of not very often used classes.
- The schema and GdsApiAdapters could become out of sync.
- Updating the classes might break dependent applications (though this is
  potentially a benefit - as it will expose this)
- GdsApiAdapters might get a bit bloated.

## Proposal

GdsApiAdapters should, where useful, return classes in addition to JSON.

It should be possible to fetch a content item in this kind of way: `GdsApi::ContentStore::ContentItem.fetch(:content_id)`

It should be possible to do `Services.content_store.content_item(:base_path)`
and get back an instance of a `ContentItem` class, with methods like `base_path`.

It should be possible to receive instances of specific classes, like `FinderContentItem`, with methods like `facets` which returns instances of the `Facet` class/schema.

We should make it possible to access the underlying JSON responses.

We could do this first for `GdsApi::ContentStore` requests and expand it to other requests.
