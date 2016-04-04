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

While we could just turn on the traffic replay and see what happens, but we'd rather have something more structured.

## Proposal

Github have a gem called&nbsp;[Scientist](https://github.com/github/scientist)&nbsp;for A/B testing critical code paths. This is in contrast to other libraries which aim to increase conversion.

The gem checks the result of the old code against the new, finding inconsistencies and performance problems.

The catch is that the code has to be free of side effects like writing to the database. &nbsp;Running code with side effects twice would lead to unexpected behaviour and bad data.

If we wanted to run these two paths of side-effect–having code we would need separate environments for each path. &nbsp;Our small- and micro-services can help us here, as we can run separate instances of applications which are changing and use the GDS API adapters as our point of test.

Another problem is that we don't want performance regressions to slow down our A-branch. &nbsp;Currently Scientist runs both paths in the same thread and checks both results at the end. &nbsp;We'd want to offload the B-branch to a worker and have the A-branch upload its results to a shared database (like Redis) so the worker can do the science outside the main request/response cycle.

This also provides time to do the more sophisticated checks that might be required to make sure a change hasn't caused problems. &nbsp;Have the right number of emails been sent (via a sandbox GovDelivery account)? &nbsp;What does the database look like? &nbsp;etc.

#### Required work

- We would need to make spinning up applications in standalone environments easier and more automated. &nbsp;We discussed changing Puppet to easily spin up a "B-branch" version of an app and its dependencies, but that seems to be as much or more work than being able to spin up in AWS or via Docker, so we'll likely take the latter approach.
- We would need to write some helper code to wrap Scientist in a way that enables the testing of side-effect code. &nbsp;This would likely take the form of a standard worker which can be expanded upon and some entry point code for the API adapters.

The strong benefit of this whole approach is to safely test alternate branches from the production environment. &nbsp;Since we'll be able to target our testing more carefully for both side-effect and functional code it might also remove the need for a fully-duplicated staging environment.

&nbsp;

&nbsp;

