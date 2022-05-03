# Allow SpeedCurve to capture user HTTP Protocol Data

## Summary

We use Speedcurve RUM to capture detailed user performance data on GOV.UK. Fastly ammounced [HTTP/3 + QUIC](https://twitter.com/fastly/status/1520139864032874497) is now availabe for all customers for free as it is now out of beta. We already have an [RFC in draft](https://github.com/alphagov/govuk-rfcs/pull/139) about enabling this on GOV.UK.

But before we enable HTTP/3 + QUIC on GOV.UK I'd like to be able to capture what protocol a user is using via SpeedCurve. This will alow us to quantify if the change has made any difference for users (especially those on unreliable connections). I feel this could be a great bit of research / PR for how we are improving performance for all users of GOV.UK, no matter what their connection or device.

## Problem

Data capture to quantify the change from HTTP/2 + TCP to HTTP/3 + QUIC.

## Proposal

Describe your proposal, with a focus on clarity of meaning. You MAY use [RFC2119-style](https://www.ietf.org/rfc/rfc2119.txt) MUST, SHOULD and MAY language to help clarify your intentions.

I'd like to include a small piece of JavaScript in the current SpeedCurve RUM implimentation that will only fire when a user accepts the cookie banner. This JavaScript will look at the current HTTP protocol the user is using and push this anonymous data into SpeedCurve using their API. 

This will then give us an additional dimention in the SpeedCurve GUI with which to compare before / after the change is made.

The actual JavaScript is small and will have 0 effect of page performance as it is simply reading a string value from an object in a supporting browsers [Navigation Timing Level 2 API](https://www.w3.org/TR/navigation-timing-2/).

The actual code to include looks like this:

```js
// check see if browser supports navigation timing API and has the HTTP protocol information.
if(typeof window.performance.timing === "object" && performance.getEntriesByType('navigation')[0].nextHopProtocol === "String"){
	// returns "h1", "h2", "h3"
	var http-protocol = performance.getEntriesByType('navigation')[0].nextHopProtocol;
	// push the users protocol data into SpeedCurve RUM
	LUX.addData("http-protocol", http-protocol)
}
```

Once this code is added, we should then have information about what protocol the user used and the difference it made to the performance, allowing us to compare aggregate data for HTTP/2 and HTTP/3 users over a set period of time (likely 1-2 months).