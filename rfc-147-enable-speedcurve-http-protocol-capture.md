---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# Allow SpeedCurve to capture user HTTP Protocol Data

## Summary

We use Speedcurve RUM to capture detailed user performance data on GOV.UK. Fastly ammounced [HTTP/3 + QUIC](https://twitter.com/fastly/status/1520139864032874497) is now availabe for all customers for free as it is now out of beta. We already have an [RFC in draft](https://github.com/alphagov/govuk-rfcs/pull/139) about enabling this on GOV.UK.

But before we enable HTTP/3 + QUIC on GOV.UK I'd like to be able to capture what protocol a user is using via SpeedCurve. This will alow us to quantify if the change has made any difference for users (especially those on unreliable connections). I feel this could be a great bit of research / PR for how we are improving performance for all users of GOV.UK, no matter what their connection or device.

## Problem

Data capture to quantify the change from HTTP/2 + TCP to HTTP/3 + QUIC.

## Proposal

I'd like to include a small piece of JavaScript in the current SpeedCurve RUM implimentation that will only fire when a user accepts the cookie banner. This JavaScript will look at the current HTTP protocol the user is using and push this anonymous data into SpeedCurve using their API. 

This will then give us an additional dimension in the SpeedCurve GUI with which to compare before / after the change is made.

The actual JavaScript is small and will have a negligible effect of page performance as it is simply reading a string value from an object in a supporting browsers [Navigation Timing Level 2 API](https://www.w3.org/TR/navigation-timing-2/).

The actual code to include looks like this:

```js
// use the LUX.addData method to capture HTTP protocol information.
LUX.addData("http-protocol", performance.getEntriesByType('navigation')[0].nextHopProtocol);
```

We should report the contents of `performance.getEntriesByType('navigation')[0].nextHopProtocol` using the `LUX.addData()` function - SpeedCurve have some good example of this [in their recipes][1].

Once this code is added, we should then have information about what protocol the user used and the difference it made to the performance, allowing us to compare aggregate data for HTTP/2 and HTTP/3 users over a set period of time (likely 1-2 months).

[1]: https://support.speedcurve.com/recipes/track-size-for-a-single-resource
