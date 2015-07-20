##### **Problem**

We have recently experienced two incidents ( and&nbsp;) where sections of GOV.UK started returning HTTP 404 responses for content which was previously valid. &nbsp;No automated monitoring picked up these incidents - we'd like to have automated monitoring if this happens in future.

**Proposal**

The plan is simply to monitor a list of pages on GOV.UK to ensure that they return valid responses. &nbsp;All else in this RFC is details.

A page on GOV.UK which returns an HTTP 2xx response should very rarely start returning an HTTP 404 response. &nbsp;(The only exceptions to this are accidental publishes - see later for discussion of them). Ignoring the accidental publish exceptions, the only valid responses for a page which has been returning an HTTP 2xx are:

- HTTP 2xx or 3xx
- HTTP 410 ("Gone")

If such a page returns any other HTTP 4xx response, we are very likely to have a persistent problem which is immediately affecting users (it won't be hidden by our CDN and caching layers), and requires urgent manual intervention.

If such a page returns an HTTP 5xx response, we probably have a temporary problem; it may be being hidden from users by the CDN caching. We should alert if such responses are unusually frequent.&nbsp;

## Getting a list of pages to monitor

There are various possible sources of lists of pages to monitor.

### GA

We currently have a nightly jenkins job which runs to fetch from GA the number of page loads for every page on GOV.UK. &nbsp;This is used to update the "popularity" field in the search index. &nbsp;The code for this is in the&nbsp;[search-analytics](https://github.com/alphagov/search-analytics) github repository.

The downloaded data could also be used to populate a list of pages which have received traffic in the last fortnight. GA information includes the response status code for the pages, so could be filtered to only return pages which are currently returning a 2xx response.

The requests made to GA could be extended to also fetch the frontend app serving each page, and could be extended to populate a list of the top pages by traffic for all time. &nbsp;(Fetching all pages by all-time traffic is possible, but would produce a heavily sample response, ie, many pages would be omitted if you asked GA for this directly.)

**Problems** :

- Pages which aren't visited won't be represented in this output.
- Need to implement fetching status code and frontend app together with the other data.

### Search index

The search index contains a list of pages on the site. &nbsp;This is used to populate the "sitemap" pages.&nbsp;The list of pages in the search index could be used for the monitoring.

**Problems:**

A failure of the search index system which lost some documents from it could plausibly cause some pages on the site to start returning 4xx errors, or erroring. &nbsp;However, this wouldn't be detected if the monitoring used the same list of documents.

However, the search index could be used in the same way as suggested for GA above, as a source of URLs to add to a list held in a separate system.

### Content store

The content store apps (perhaps the content-register part of this app cluster) could return a list of routes registered for a particular path.

**Problems** :

As with the search index, if the content store lost information on a page, we wouldn't get alerts if the content store was also the source of the list of pages to monitor.

Also, we want to monitor all the urls that are active on the site: a content store item may represent content spread across multiple urls, and there may be no easy way to get a list of all the urls that the item can be accessed at.

### Direct from apps

The individual apps could generate lists of their pages to be monitored.

**Problems:**

There are a lot of apps, and custom code would need to be written and maintained for each one. &nbsp;This is probably a non-starter.

## What to do with the lists of pages

The result of fetching this data could either be written directly to a file in some shared system (eg, S3, or a git repo) or explicitly copied to all machines which need them to run the monitoring smoke test.. &nbsp;Monitoring apps could then query this index to get lists of documents to check. &nbsp;If a shared system was used, the list of pages fetched each day could be merged with the list of pages which were already present.

Using a git repository for this monitoring would have the nice property that false positives could be resolved by manually editing the repository to remove incorrect entries. &nbsp;Further, it would produce a history of which pages were live on the site at a particular time.

**Recommendation: use a git repository**** , pushing updates to it nightly. &nbsp;Have nagios monitoring on the timestamp of the last push to this repository.** I don't see any reason that such a repository couldn't be open access. &nbsp;I would imagine this git repository containing a single, large, CSV file, with one line per page on the site. (in sorted order by base\_path,&nbsp;

## Where to run the monitoring

We want monitoring on high-traffic pages to run frequently.

Checks should be run avoiding caches - so we need to ensure that they don't put too high a load on the apps themselves.

&nbsp;

**Question** : should smokey run these tests?&nbsp;Or should we have a separate persistent app?

One advantage of a persistent app is that &nbsp;which gradually covers all pages? &nbsp;Or do statistical sampling (pick N of the "not highest traffic" pages)

## Accidentally reverted pages

Some pages are accidentally published, and then have to be reverted.&nbsp;This normally only happens to comply with legal obligations.

We'll make two assumptions about accidentally published pages:

- accidentally published pages will always be reverted within 7 days (which seems reasonable, since there's little point reverting such pages after longer, as they'll certainly be in various web archives).
- no accidentally published pages will have received "high" traffic (ie, within the top 100 pages served by their frontend app, say).

To avoid making false-positive alerts about such pages, we'll exclude any such pages; ie, any pages which haven't been published for more than 7 days, unless they're in the top 100 pages served by their app. This information is available from analytics.

These assumptions aren't "watertight", but if violated will result in false positive alerts. We'd probably want to know about such problems anyway, and I think they'll very rarely be incorrect assumptions, so this seems likely not to be a problem. We can iterate the thresholds if they do turn out to be a problem.

&nbsp;

&nbsp;

&nbsp;

