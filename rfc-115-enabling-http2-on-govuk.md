# Enabling HTTP/2 on GOV.UK

## Summary
Back in November 2018 we trialed the use of HTTP/2 on GOV.UK. According to quite a few sources, enabling HTTP/2 should improve web performance for users by introducing technology like multiplexed streams, HPACK header compression and stream prioritisation. Unfortunately it turned out that from our synthetic web performance testing it actually slowed the site down in many instances.

![Results from testing HTTP/1.1 vs HTTP/2.](rfc-115/cold-cache-summary.png)

We tested 5 different page types, on multiple devices and connection speeds and examined the following performance metrics to come up with a result:

* First visual change
* Visually complete 95%
* Last visual change
* Speed index 
* Load time (fully loaded)

And for Lighthouse reports these metrics were examined:

* First Contentful Paint
* First Meaningful Paint
* Speed Index
* First CPU Idle
* Time to Interactive

The RFC below discusses the problems with our current setup and suggests possible solutions. 

## Problems
### 1 - Sub Resource Integrity (SRI)

On GOV.UK we are using Subresource Integrity for all our CSS and JavaScript assets coming from the assets domain. The [SRI specification](https://www.w3.org/TR/SRI/#cross-origin-data-leakage) requires that the `crossorigin` attribute set to `anonymous` be used with SRI resources for security reasons related to data leakage from a credentialed TCP connection. This is forcing the browser to open a second TCP connection in 'anonymous mode' so it can download the CSS/JS from the assets domain. By doing so this is adding 100's of milliseconds of delay to the page rendering. This occurs even with the using the of the [`preconnect`](https://www.w3.org/TR/resource-hints/#fetching-the-resource-hint-link) hint, a browser feature intended to fix this issue.

This performance issue is occurring in both HTTP/1.1 and HTTP/2 as seen in the WebPageTest connection view waterfalls below:

#### HTTP/1.1
![The connection view can tell you a lot about how your connections are being utilised. Focus on each one in turn and see how much of the row is empty. This will show you the wasted time on each connection.](rfc-115/connection-view-annotated.png)

Here we can see 13 TCP connections being opened (6 'credentialed', 6 'anonymous', 1 third-party to Google Analytics). If we weren't didn't use SRI, or tweaked our setup by swapping to `use-credentials` instead of `anonymous` we can reduce this requirement down to 8 (6 'credentialed', 1 'anonymous' for fonts, 1 third-party to Google Analytics). This is the first step in web performance improvements for GOV.UK users on HTTP/1.1.

#### HTTP/2
Below you can see the delay in the waterfall while the 2nd TCP connection is established.

![The delay seen in the HTTP/2 waterfall chart](rfc-115/h2-dns-annotated.png)

And this is what it could look like if we tweak our setup:

![](rfc-115/the-impact-annotated.png)

In the example test above on a Nexus 5 device under 3G connection speeds, we can bring the request of the CSS & JS file forwards by 750 ms. This should speed up the whole waterfall and turn the results of the summary list above from red to green.

This is achieved through the use of HTTP/2 connection coalescing, which can be seen in action on GOV.UK from our trial below:

![](rfc-115/connection-view.png)

This coalesced connection is under-utilised if 'anonymous mode' is used on our static assets. Assets download slower because of [TCP slow start](https://en.wikipedia.org/wiki/TCP_congestion_control#Slow_start): one connection isn't used (which is already up to speed), another is delayed and forced to ramp up to download the critical CSS & JS assets. 

### 2 - Assets served with `Access-Control-Allow-Origin: *`
Unfortunately it isn't quite as simple as switching `crossorigin` from `anonymous` to `use-credentials`, as examining the [Fetch specification](https://fetch.spec.whatwg.org/) there's [information in the table (5th row down)](https://fetch.spec.whatwg.org/#cors-protocol-and-credentials) that states:

> `Access-Control-Expose-Headers`, `Access-Control-Allow-Methods`, and `Access-Control-Allow-Headers` response headers can only use `*` as value when request’s credentials mode is not "include".

The use of the wildcard (`*`) isn't allowed on a credentialed connection. If used it will block any requests and post an error message to the browser that looks like this:

> Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at ‘https://assets.example.com/script.js’. (Reason: Credential is not supported if the CORS header ‘Access-Control-Allow-Origin’ is ‘*’).

This is caused by our current NGINX setup on [these lines](https://github.com/alphagov/govuk-puppet/blob/962ea899e9c6778fe91e80074346912bd4314b10/modules/router/templates/assets_origin.conf.erb#L36-L38).

We should look at assets served using this header. Note: Webfonts will need to be served with this header due to their [unique CORS requirements](https://www.w3.org/TR/css-fonts-3/#font-fetching-requirements).


### 3 - The assets domain
Domain sharding for static assets is an anti-pattern under HTTP/2, and in our current setup isn't optimal for HTTP/1.1 either. We should consider removing the assets domain for our static assets (CSS, JavaScript, fonts, images). 

Although the use of [HTTP/2 connection coalescing](https://daniel.haxx.se/blog/2016/08/18/http2-connection-coalescing/) will reduce the performance impact of the the asset domain, its use very much depends on the browser implementation and is [notoriously flaky](https://bugs.chromium.org/p/chromium/issues/detail?id=1011685). Users on older versions of Safari (before 12), IE, and Edge 18 and below all don't support coalescing, so won't benefit from this optimisation. But as we've seen above the domain sharding isn't offering up any benefits anyway, so why not remove the need for connection coalescing for static assets. All browsers that support HTTP/2 will then receive the same benefits and experience. [95.7% of the UK population](https://caniuse.com/#search=http2) use a browser that supports HTTP/2, so most of our users will benefit from this change.

Once completed our connection graph will look similar to this:

![Example of an optimised connection graph](rfc-115/clean-connections.png)

The bulk of the page assets will be downloaded on the initial connection (www.gov.uk), with a secondary `anonymous` connection opened for the fonts. That's twelve connections under our current HTTP/1.1 down to just two in many cases.

At this point it is worth considering the removal of SRI on these assets, since it is security measure used to minimise the impact of changes in third-party code on a first-party website. Once the assets are all first-party, it serves no real purpose.

Removing the assets domain for static assets also clears a path for future web performance enhancements like [HTTP/3, QUIC (Quick UDP Internet Connection)](https://www.fastly.com/blog/why-fastly-loves-quic-http3) and 0-RTT. [HTTP/3](https://caniuse.com/#feat=http3) has no support at the moment as it currently sits behind browser flags. But at some point in the future it will be supported and the asset domain will need to be removed for static assets anyway to keep up with the latest protocol developments.

NOTE: As mentioned by @david-ncsc in [his comment](https://github.com/alphagov/govuk-rfcs/pull/115#issuecomment-567907397), there's probably a security benefit to keeping the uploaded files on a separate origin as defence against uploaded malicious files. We should therefore only remove the assets domain for CSS, JavaScript and the fonts.

## Proposal
### MUST
* Change the NGINX config to only serve font files (WOFF2, WOFF, EOT) with `Access-Control-Allow-Origin: *`. Code found for this [here](https://github.com/alphagov/govuk-puppet/blob/master/modules/govuk/templates/asset_pipeline_extra_nginx_conf.erb) and [here](https://github.com/alphagov/govuk-puppet/blob/962ea899e9c6778fe91e80074346912bd4314b10/modules/router/templates/assets_origin.conf.erb#L36-L38).
* Change `crossorigin='anonymous'` to `crossorigin='use-credentials'` for all CSS and JavaScript.

### SHOULD
* Serve static assets (CSS, JS, Fonts) from the origin (www.gov.uk).
