# Remove Subresource Integrity (SRI) from the GOV.UK assets domain

## Summary
Due to the security requirements of SRI, `crossorigin="anonymous"` is required for these assets. This forces browsers to open a separate TCP connection to download this resource. Since TCP connections are expensive to open and maintain, this practice has a negative effect on frontend performance. 

## Problem
Running [Web Page Test](https://www.webpagetest.org/) (WPT) against a number of pages across GOV.UK reveals that the browser is having to open a greater number of TCP connections due to the use or SRI, and more specifically the `crossorigin="anonymous"` attribute attached to the CSS and JavaScript references. This attribute is mandatory for [security against cross origin policy violations](https://shubhamjain.co/til/subresource-integrity-crossorigin/). The use of the `crossorigin="anonymous"` forces the browser to open a brand new TCP connection to ensure that no user credentials are shared across the connection. This can be seen in the images below:

### Homepage
In this example 11 TCP connections are being opened when the browser default for [HTTP/1.1 in many browsers is 6](https://docs.pushtechnology.com/cloud/latest/manual/html/designguide/solution/support/connection_limitations.html). Since opening TCP [connections is expensive](https://hpbn.co/building-blocks-of-tcp/#three-way-handshake), this will be having a negative effect on performance.

![homepage-connection-view.png](/rfc-112/homepage-connection-view.png)

Full test can be [seen here](https://www.webpagetest.org/result/190507_AG_6f6760e331bba9bb6ff6e9fcad9b7743/1/details/#waterfall_view_step1). 

### Past Prime Ministers page
The same issue can be seen on the Past Prime ministers page, where 13 TCP connections are opened instead of the default 6 a browser usually does. As can be seen in the bandwidth graph the connection isn't being fully utilised, this is probably due to the TCP slow start is an algorithm that each TCP connection uses.

![past-pm-connection-view.png](/rfc-112/past-pm-connection-view.png)

Full test can be [seen here](https://www.webpagetest.org/result/190916_1B_9a4a73442aedc3f89de4ae77cce6e656/1/details/#waterfall_view_step1)

### HTML size
A very minor point, but adding the `crossorigin="anonymous" integrity="sha256-wLi6ixZSqsrSmNdPJHUiYBh/U4tQxAwkhPfzM8vDzys="` to the 12 resource requests across a page could be adding an extra 1KB to the HTML size (although GZipping will minimise this).

### HTTP/2
Will HTTP/2 solve this issue? Since HTTP/2 multiplexes assets over different streams on a single TCP connection. Unfortunately not. Requests without credentials use a separate connection as mentioned in the article [here](https://jakearchibald.com/2017/h2-push-tougher-than-i-thought/#requests-without-credentials-use-a-separate-connection). So even when we eventually enable HTTP/2 we will have the same issue where an anonymous connection will be opened.

## Proposal
I'm proposing we disable SRI for all assets from the `https://assets.publishing.service.gov.uk` domain. Since this is a domain under our control it is highly unlikely that a MITM attack will occur. Assuming an attacker gets that far they would most likely be able bring the whole site down anyway due to the level of access they would need. Removing SRI will then allow us to remove the mandatory `crossorigin="anonymous"`, which will then allow the browser to open and reuse connections as they are intended (and hit the maximum of 6 connections).

For assets that do come from a third-party domain, they should still have SRI enabled.
