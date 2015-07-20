##### **Problem**

We have recently experienced two incidents ( and&nbsp;) where sections of GOV.UK started returning HTTP 404 responses for content which was previously valid. &nbsp;No automated monitoring picked up these incidents - we'd like to have automated monitoring if this happens in future.

**Proposal**

The plan is simply to monitor a list of pages on GOV.UK to ensure that they return valid responses. &nbsp;All else in this RFC is details.

A page on GOV.UK which returns an HTTP 2xx response should very rarely start returning an HTTP 404 response. &nbsp;(The only time this should happen is when something has been accidentally published, and has to be reverted for legal reasons. &nbsp;We'll consider how to handle accidentally reverted pages later in this RFC.). &nbsp;Ignoring the accidental publish exceptions, the only valid responses for a page which has been returning an HTTP 2xx are:

- HTTP 2xx or 3xx
- HTTP 410 ("Gone")

If such a page returns any other HTTP 4xx response, we are very likely to have a persistent problem which is immediately affecting users (it won't be hidden by our CDN and caching layers), and requires urgent manual intervention.

If such a page returns an HTTP 5xx response, we probably have a temporary problem; it may be being hidden from users by the CDN caching. We should alert if such responses are unusually frequent.&nbsp;

## Getting a list of pages to monitor

There are various possible sources of lists of pages to monitor.

Get from GA, nightly?

Get from search? &nbsp;(Sitemaps?)

Get from /random?

## Where to run the monitoring

FIXME - details.

Smokey should run checks on high traffic pages every 5 minutes.

Should we have a separate persistent app which gradually covers all pages? &nbsp;Or do statistical sampling (pick N of the "not highest traffic" pages)

## Accidentally reverted pages

We'll make two assumptions about accidentally published pages:

- accidentally published pages will always be reverted within 7 days (which seems reasonable, since there's little point reverting such pages after longer, as they'll certainly be in various web archives).
- no accidentally published pages will have received "high" traffic (ie, within the top 100 pages served by their frontend app, say).

To avoid making false-positive alerts about such pages, we'll exclude any such pages; ie, any pages which haven't been published for more than 7 days, unless they're in the top 100 pages served by their app. This information is available from analytics.

These assumptions aren't "watertight", but if violated will result in false positive alerts. We'd probably want to know about such problems anyway, and I think they'll very rarely be incorrect assumptions, so this seems likely not to be a problem. We can iterate the thresholds if they do turn out to be a problem.

&nbsp;

&nbsp;

&nbsp;

