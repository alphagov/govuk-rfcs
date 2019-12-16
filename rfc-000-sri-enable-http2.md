# Changing SRI to allow for HTTP/2 to be enabled on GOV.UK

## Summary
HTTP/2 is the next iteration of the HTTP protocol. It can enable better web performance for our uses if implemented correctly. Around 14 months ago we trialed it on GOV.UK but found that it actually made performance worse for some users. There for it was disabled. I've reviewed the tests from then and stubbled upon what was causing the issue, so am proposing a fix to allow for it to be enabled in the future.

## Problem
When we tested the HTTP/2 in [November 2018](https://github.com/alphagov/govuk-puppet/pull/8297) I was unsure if this would have a positive or negative effect on our users so opted to run a set of tests using [WebPageTest](https://www.webpagetest.org/) and [Sitespeed.io](https://www.sitespeed.io/) to check see if the switchover was positive or negative.

Five test pages were selected, each with different content and templates:

* Homepage
* Start page
* Past Prime Ministers page
* Speech page
* Organisation page

The synthetic tests were conducted using different browsers, devices and connection speeds. To analyse if HTTP/2 was quicker I looked at the following metrics in Sitespeed.io / WPT:

* First visual change
* Visual complete 95%
* Last visual change
* Speed index
* Load time (fully loaded)

And for Lighthouse these metrics were examined:

* First Contentful Paint
* First Meaningful Paint
* Speed Index
* First CPU Idle
* Time to Interactive

For each set of tests a graph like the one seen below was created. The graph shows the time difference between each metric for HTTP/1.1 vs HTTP/2. Positive values show HTTP/2 took that much more time to complete the same metric:

![Example graph produced to compare HTTP/1.1 vs HTTP/2](rfc-000/nexus-5-results.png)

I've summarised the results from the tests below:

![Summary of results under cold cache conditions](rfc-000/cold-cache-summary.png)

As you can see the results show that for our setup, HTTP/1.1 wins in terms of performance. At the time I believed this was because of the "asset" domain we are using to server all other assets. But I've now revised that opinion.

### SRI interaction with HTTP/2
On GOV.UK we are using Subresource Integrity for all our CSS and JavaScript assets. And at the moment we are also setting the `crossorigin` attribute to `anonymous`. This is forcing the browser to open a second TCP connection in "anonymous mode" so it can download the CSS/JS from the assets domain. In doing so this is adding 100's on milliseconds of delay to the page rendering. This occurs even with the use of the `preconnect` hint.

Below you can see the delay in the waterfall while the 2nd TCP connection is established.
![The delay seen in the waterfall](rfc-000/h2-dns-annotated.png)

And this is what it could look like if we tweak our setup:

![](rfc-000/the-impact-annotated.png)

In the example test on a Nexus 5 device under 3G connection speeds we can bring the request of the CSS / JS file forwards by 750 ms. In turn this should speed up the whole waterfall and turn the summary list from red to green. This is achieved by the use of HTTP/2 connection coalescing, which can be seen taking place in the connection graph below:

![](rfc-000/connection-view.png)

This coalescing is under-utilised if "anonymous mode" is used on static assets.

### Order of events
Here's a quick run through of the order of events the browser is seeing under these conditions:

1. Initial connection to the server negotiated, HTML page downloads
2. Browser sees the `preconnect` header and examines the domain that is referenced
3. Browser sees that the origin and `preconnect` sub-domain are similar, so coalescing can occur
4. With this coalesced connection now open, the first image is sent by the server
5. The browser now sees that CSS requires SRI, and realises it doesn't have an "anonymous" connection established allowing it to be downloaded
6. Browser opens the "anonymous" connection (after some delay), and all other CSS / JS assets are downloaded using it
7. Other non-SRI assets continue to use the initial connection


## Proposal
There are a few options to allow us to fix this issue:

1. For CSS / JS assets change the `crossorigin` value from `anonymous` to `use-credentials`. This will allow us to still use SRI, but it will leverage the existing connection.
2. For CSS only, remove the SRI requirement completely. An attack on a domain under our control is minimal, and they are limited in what they can actually achieve by changing CSS, so it seems unnecessary.
3. Remove SRI for all assets being served, again due to the fact the domain is first party and under our control.

Personally I'd like to test option 1 first, then if not successful consider the other 2 options.

Once this work is completed, we can then go back to Fastly and ask them to enable HTTP/2 and test the results. 

**NOTE**: Staging and production are intertwined, so by enabling it on staging it will also enable it on production. As shown in our month trial back in November 2018, there's no issues with raised by this. Users will still be able to access all content. Older browsers will fall back to HTTP/1.1 if H2 isn't supported.

A list of where `crossorigin` is being used can be [seen here](https://github.com/search?q=org%3Aalphagov+%27crossorigin%3D%22anonymous%22%27&type=Code). And I'm happy to raise the PR(s) for these if we get consensus.