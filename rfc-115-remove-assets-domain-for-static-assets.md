# Serving CSS, JS, and fonts 

This is a continuation of a discussion in [RFC-114 (adjust SRI implementation to allow for HTTP/2)](https://github.com/alphagov/govuk-rfcs/pull/114).

## Summary
The GOV.UK asset domain was probably implemented as a way of optimising HTTP/1.1 performance when domain sharding was considered "best practice". It is now a blocker for the upgrade to HTTP/2, and may actually be harming HTTP/1.1 performance. This RFC is a proposal to remove the asset domain (assets.publishing.service.gov.uk) for our static assets and serve all CSS, JS, images and fonts off the main origin (www.gov.uk).

## Problem
HTTP/2 is the latest stable iteration of the HTTP protocol. It sets out to fix performance issues present in HTTP/1.1. New features include [HPACK header compression](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/), [multiplexing streams over a single TCP connection](https://developers.google.com/web/fundamentals/performance/http2#request_and_response_multiplexing).

Due to a browsers 6 connection limit to a URL, an "optimisation" was to use a number of domains and thus allow more simultaneous connections to load assets in parallel. This comes with a number of issues:

* TCP connections are expensive (especially under HTTPS)
	* DNS lookup, TCP slow start, HTTPS handshake 
* Prioritisation is broken when downloading assets cross-domain:
	* Each connection has no visibility of what each is doing
	* Bandwidth won't be being used effectively due to lack of correct prioritisation
* Browser vendors choose 6 connections for a reason, anything beyond that most likely leads to diminished returns.

HTTP/2 solves many of these issues by streaming files across a single TCP connection.

The problems with HTTP/1.1 connections can be seen in the "connection view" in the following [WebPageTest run](https://www.webpagetest.org/result/181010_CQ_13c6a6e982262e3288c3538f5f64de77/1/details/#waterfall_view_step1) (Nexus 5 - Chrome - 3G / Past Prime Ministers page):

![Connection view for GOV.UK Prime Ministers page](rfc-115/connection-view-annotated.png)

1. **Request 1**: Connection established to www.gov.uk, but it is only used for downloading the HTML. The connection is open but never used again. This is a wasted TCP connection.
2. **Request 2**: In this instance we are losing 1.3 seconds waiting for the connection to the assets domain to be established (DNS lookup + TCP negotiation + SSL negotiation). 
3. **Requests 2-5, 8**: These are "anonymous" connections as the fonts / CSS / JS are only downloaded. Once these have downloaded we have a huge amount of empty space behind which could be utilised if allowed too (`use-credentials`)
4. **Requests 7-9, 12**: These are credentialed connections that are being opened specifically to download the images on the page. Heavily utilised.
5. **Prioritisation**: The highest priority assets on the page after the HTML is the CSS then JS (request 2,3,4,5). There is a distinct overlap of these requests with the image downloads (request 6,7). Precious bandwidth is being used to download images where it is better spent on high priority assets.

We have 12 TCP connections open for this page under HTTP/1.1 (excluding GA). If we implement the changes in [RFC 114](https://github.com/alphagov/govuk-rfcs/pull/114) we can bring this down to 6. This connection view above clearly shows that we aren't benefiting from the sharded domain, it is actually making things worse in terms of performance. Broken prioritisation, expensive TCP negotiations, under-utilised TCP connections.

So with this RFC I'm proposing we remove the assets domain for static assets. Upon enabling HTTP/2 it will bring those 6 connections down to 2: 

1. **Non-credentialed TCP connection**: for the HTML, CSS, JS and images.
2. **Anonymous TCP connection**: Only used for the fonts. This is part of the font spec, CORS must be enabled even for font's hosted on the same domain. This can't be avoided. We will still use the `preconnect` header to set this up as quick as possible.

With the assets domain being used for static assets, the two connections can **only** happen if a browser supports [HTTP/2 connection coalescing](https://daniel.haxx.se/blog/2016/08/18/http2-connection-coalescing/) - which promises fewer TLS handshakes and reduced overall latency since connections can be reused. 

Connection coalescing very much depends on the browser implementation and is [notoriously flaky](https://bugs.chromium.org/p/chromium/issues/detail?id=1011685). Users on older versions of Safari (before 12), IE, and Edge 18 and below all don't support coalescing, so won't benefit from this optimisation. But as we've seen above the domain sharding isn't offering up any benefits anyway, so why not remove the need for connection coalescing for static assets. All browsers that support HTTP/2 should then receive the same benefits and experience. And since [95.7% of the UK population](https://caniuse.com/#search=http2) use a browser that supports HTTP/2, most of our users will benefit from this change.

Once completed our connection graph should look similar to this:

![Example of an optimised connection graph](rfc-115/clean-connections.png)

The bulk of the page assets will be downloaded on the initial connection (www.gov.uk), with a secondary `anonymous` connection opened for the fonts. Twelve connections down to two in many cases.

Removing the assets domain for static assets also clears a path for future web performance enhancements like HTTP/3, QUIC (Quick UDP Internet Connection) and 0-RTT. [HTTP/3](https://caniuse.com/#feat=http3) has no support at the moment as it currently sits behind browser flags. At some point in the future it will be supported and the sharding removal will need to be made anyway to keep up with the latest protocol developments.

## Proposal

Work with @kevindew and the GOV.UK team to phase out the assets domain. Quoting a comment from [RFC 114](https://github.com/alphagov/govuk-rfcs/pull/114#issuecomment-567009902):

> The sort of things I think we'd need for switching the domains the CSS and JS are served from would be:
> 
> Add proxy passes to the www nginx file, similar to https://github.com/alphagov/govuk-puppet/blob/226ed02b70932650b4fc478d2971e33e77b9fd45/hieradata/common.yaml#L1388-L1402 and probably prefix them all with /assets.
> 
> Then in a frontend app we'd need to tell them to not use a special asset host and change the asset path to /assets/:app-name.
> 
> Then the slightly tricky point would be the static app that'd need to explicitly be told to use the web root as the asset host.
> 
> Those steps would probably get you the whole way to the goal but would leave behind some cleaning up tasks for static hostname and asset-managers dual meaning of using asset-root. There's probably a couple of other snags.

Starting with a spike to dig into the complexity then evaluate how feasible it is. It's a job that will need to be done eventually, it just depends if it is something we can accommodate now.

More detailed architecture examination can be seen in [this comment](https://github.com/alphagov/govuk-rfcs/pull/115#issuecomment-567422813). Number 1 is the priority for this RFC. 2 and 3 are purely nice to haves at a later date should we have the time / resources to complete them.