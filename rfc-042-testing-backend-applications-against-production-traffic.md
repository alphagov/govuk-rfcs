&nbsp;

&nbsp;

---
status: "IN PROGRESS"
notes: "Closing for comments on ..."
---

## Problem

We replay frontend traffic from production to staging to expose problems with new code during deploy. We do not replay backend traffic of any kind, and we only replay frontend traffic for GETs.

We would like a way to expose new code to backend traffic from production.

Traffic which is not currently replayed falls into 2 groups:

1. Backend GET requests
2. Frontend and backend non-GET requests

Category 1 is easy to fix as the GET requests do not change state or cause any side-effects. Category 2 is more difficult.

Staging's data is not kept consistent with production because:

1. Data is sync'd nightly from production to staging
2. Developers often make small modifications in staging when testing a deploy.

Replaying requests if the data doesn't match could cause errors or other behaviour which would not happen in production.

Floods of errors could also make life tougher during deploys, masking more important problems with staging.

While we could just turn on the traffic replay and see what happens, here's a more structured approach.

## Proposal

Github have a gem called&nbsp;[Scientist](https://github.com/github/scientist)&nbsp;for A/B testing critical code paths. This is in contrast to other libraries which aim to increase conversion.

The gem checks the result of the old code against the new, finding inconsistencies and performance problems.

The catch is that the code has to be free of side effects.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

