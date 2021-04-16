# Application Healthchecks

## Summary

We currently use application healthchecks for three things:

- For load balancing, to determine if an instance is ready to serve
  requests.
- For continuous deployments, to determine (along with other smoke
  tests) if a release can be automatically pushed to production.
- For alerting, so that 2ndline know if an instance has a problem
  which needs manual intervention to fix.

We implement healthchecks using the [`GovukHealthcheck`][] module in
[govuk_app_config][].

Currently, a healthcheck response is always served with an HTTP status
of 200, and indicates in the body whether the instance's status is
"ok", "warning", or "critical".  However, AWS load balancers use the
HTTP status, not the response body, to determine whether an instance
is healthy.  So we will continue to send requests to an instance which
is in a "warning" or "critical" state.

This RFC proposes that we standardise on our healthchecks returning a
200 or a 500 status code, which has some further ramifications on
monitoring and alerting (discussed below).

A full list of healthchecks which will need updating is given at the
end of the document.

## Problem

We overload the meaning of "healthcheck", and cover both *application
health* as well as *instance health* with our `/healthcheck`
endpoints.  This introduces confusion, and means that we cannot
currently use healthchecks in load balancing.

Here are some examples of healthchecks which are suitable for load
balancing and for post-deployment checks:

- [`GovukHealthcheck::ActiveRecord`][]
- [`GovukHealthcheck::Mongoid`][]
- [`GovukHealthcheck::RailsCache`][]
- [`GovukHealthcheck::Redis`][]
- [`GovukHealthcheck::SidekiqRedis`][]

If an app can't talk to a backing service it relies on, then it
probably can't be trusted to handle any requests.  One of these
healthchecks failing could indicate a networking or a configuration
issue.

Here are some examples of healthchecks which are unsuitable for load
balancing or for post-deployment checks:

- [`GovukHealthcheck::SidekiqQueueCheck`][], this is an abstract check
  which other checks extend.
  [`GovukHealthcheck::SidekiqQueueLatencyCheck`][] is an instance of
  this check.
- [`GovukHealthcheck::ThresholdCheck`][], this is another abstract
  check which other checks extend.
  [`GovukHealthcheck::SidekiqRetrySizeCheck`][] is an instance of this
  check.
- [`Healthcheck::ApiTokens`][] in [signon][], which reports that an
  API token needs rotating.

If one of these healthchecks fail, the app instances themselves are
probably fine.  The problem is elsewhere.

Two of these indicate capacity problems outside of the instance, and
the third is an alert that a manual maintenance procedure needs to be
performed some time in the next two months.  They all share the
property that if one instance reports a failure, all will.  This makes
them unsuitable for load balancing purposes.

Even if we don't make our healthchecks suitable for load balancing, as
GOV.UK moves towards continuous deployments, we will end up in
situations where an automatic deployment is aborted because of
something unrelated to the change being deployed.  That's not good.

A healthcheck should check that the instance is running and isn't
completely broken.  That's all.

## Proposal

I propose that we adopt these definitions:

> A *liveness healthcheck* is an HTTP endpoint which MUST return an
> HTTP status of 200.
>
> A *readiness healthcheck* is an HTTP endpoint which MUST return an
> HTTP status of either 200 (if the instance may receive requests) or
> 500 (if it should not).  It MAY also return details in the response
> body as a JSON object.

And furthermore that we commit to deprecating the `/healthcheck`
endpoint and implementing the new healthchecks at endpoints
`/healthcheck/live` and `/healthcheck/ready`.

This new approach to readiness healthchecks is more suitable for our
three purposes than before:

- For load balancing, an unhealthy app will be taken out of the pool.
- For continuous deployments, we can check the HTTP status rather than
  read the response body.
- For alerting, we can continue to read the response body.

We get no immediate benefit from the liveness healthcheck, but will do
when we have replatformed.

Adopting these definitions gives us some migration work to do.  We
can't start serving non-"ok" healthchecks with an HTTP status of 500
right now, as some of our healthchecks are unsuitable for load
balancing.

We will need to implement the proposal in stages:

1. List all the healthchecks which need changing, because they don't
   indicate a critical failure of the app (done, see the appendix)
2. For each such healthcheck:
   - remove it if it's not adding value, or
   - add a separate alert if it is
3. For each application:
   - serve a liveness healthcheck on `/healthcheck/live`
   - serve a readiness healthcheck on `/healthcheck/ready`
4. Update govuk-puppet and govuk-aws to use `/healthcheck/ready`
   instead of `/healthcheck`
5. Remove the `/healthcheck` endpoint from every app.
6. Change `GovukHealthcheck` to serve the appropriate HTTP status
   code.

As part of (2), we will remove the "warning" state some of our
healthchecks return.

### Why separate healthchecks?

Separate liveness and readiness healthchecks are a common best
practice.  They are separate because they serve different purposes:

- Liveness is used by the container orchestrator (such as [Amazon ECS][],
  which we are replatforming to) to determine if an instance has
  crashed or entered some other unrecoverable state, and must be
  restarted.

- Readiness is used by the network load balancers to determine if an
  instance should be sent traffic.

For example, let's say we have an application which uses a database,
and that due to some transient fault (like a network partition) some
of the instances cannot reach the database.  We do not want to send
traffic to those instances, so their readiness healthchecks should
fail.  But restarting the instances won't resolve the problem, as it's
an issue with the underlying infrastructure, so we don't want their
liveness healthchecks to fail.  We want the instances to keep running,
so that when the transient fault recovers, they can quickly begin
serving traffic again.

On the other hand, let's say an instance exhausts all its memory, and
can't handle any inbound requests at all.  The liveness (and
readiness) healthcheck will fail, due to timing out, and ECS will
restart the instance.

### Remove the "warning" state

There are four possible semantics we could assign the "warning" state:

| # | State    | Allows automatic deployments? | Allows requests to be sent to the instance? |
| - | -------- | ----------------------------- | ------------------------------------------- |
|   | ok       | yes | yes |
| 1 | warning  | yes | yes |
| 2 | warning  | yes | no  |
| 3 | warning  | no  | yes |
| 4 | warning  | no  | no  |
|   | critical | no  | no  |

- If we go for option 1, then "warning" is the same as "ok".
- If we go for option 2, then "warning" will let us deploy unusable releases.
- If we go for option 3, then "warning" will block deployments.
- If we go for option 4, then "warning" is the same as "critical".

The most sensible option is 3, which is our current behaviour.

But does it really gain us anything over having separate alerts for
the specific condition we need to know about?

By removing the "warning" state, we will remove some spurious alerts
which don't add value, and add more specific alerts for ones which do.

### Gaps in metrics

Some of the unsuitable healthchecks correspond to conditions we need
to alert about.  Some can be directly implemented as Icinga checks by
drawing on data we already report to graphite, but others will need
new metrics to be made available first.

[Prometheus][], which we are adopting in the replatforming work, is a
pull-based metrics gathering tool, which nicely solves the problem of
how to get application state into an alert.  But we're not
replatformed yet, so until then we may need to do something like
email-alert-api, which [has a worker to push metrics to graphite][].

## Appendix: Healthchecks which need changing

The following healthchecks need updating before `GovukHealthcheck` can
serve an HTTP status of 500:

| App or Gem | Check | Reason |
| ---------- | ----- | ------ |
| [govuk_app_config][]  | [`GovukHealthcheck::SidekiqQueueCheck`][]           | checks for a capacity issue |
| [govuk_app_config][]  | [`GovukHealthcheck::SidekiqQueueLatencyCheck`][]    | checks for a capacity issue |
| [govuk_app_config][]  | [`GovukHealthcheck::SidekiqRetrySizeCheck`][]       | checks for a capacity issue |
| [govuk_app_config][]  | [`GovukHealthcheck::ThresholdCheck`][]              | checks for a capacity issue |
| [content-publisher][] | [`Healthcheck::GovernmentDataCheck`][]              | a failure doesn't seem to totally impair the instance |
| [finder-frontend][]   | [`Healthcheck::RegistriesCache`][]                  | a failure doesn't seem to totally impair the instance |
| [publisher][]         | [`Healthcheck::ScheduledPublishing`][]              | checks for a capacity issue |
| [publishing-api][]    | [`Healthcheck::QueueLatency`][]                     | checks for a capacity issue |
| [search-api][]        | [`Healthcheck::ElasticsearchIndexDiskspaceCheck`][] | checks for a capacity issue |
| [search-api][]        | [`Healthcheck::RerankerHealthcheck`][]              | checks for an error which is gracefully handled |
| [search-api][]        | [`Healthcheck::SidekiqQueueLatenciesCheck`][]       | checks for a capacity issue |
| [signon][]            | [`Healthcheck::ApiTokens`][]                        | checks for an upcoming maintenance task |

Notes:

- [asset-manager][] isn't using `GovukHealthcheck`, but it has [an equivalent implementation][].
- [content-data-admin][] has a nonstandard healthcheck which reports an error to Sentry.
- [finder-frontend][] has a `/healthcheck` and a `/healthcheck.json` which do different things.
- Various apps don't have any healthcheck endpoint at all.
- Various apps have a healthcheck endpoint which is just `proc { [200, {}, []] }`.

[`GovukHealthcheck`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck.rb
[`GovukHealthcheck::ActiveRecord`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/active_record.rb
[`GovukHealthcheck::Mongoid`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/mongoid.rb
[`GovukHealthcheck::RailsCache`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/rails_cache.rb
[`GovukHealthcheck::Redis`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/redis.rb
[`GovukHealthcheck::SidekiqQueueCheck`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/sidekiq_queue_check.rb
[`GovukHealthcheck::SidekiqQueueLatencyCheck`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/sidekiq_queue_latency_check.rb
[`GovukHealthcheck::SidekiqRedis`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/sidekiq_redis.rb
[`GovukHealthcheck::SidekiqRetrySizeCheck`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/sidekiq_retry_size_check.rb
[`GovukHealthcheck::ThresholdCheck`]: https://github.com/alphagov/govuk_app_config/blob/b5f76dd7920ccee294c6e862336265980c9eb323/lib/govuk_app_config/govuk_healthcheck/threshold_check.rb
[`Healthcheck::ApiTokens`]: https://github.com/alphagov/signon/blob/694b123062218bf87e457b4b0f36d76c2fe3045d/lib/healthcheck/api_tokens.rb
[`Healthcheck::GovernmentDataCheck`]: https://github.com/alphagov/content-publisher/blob/c1b0d0e1bb05413dd2102ec1eadb485344890c7f/lib/healthcheck/government_data_check.rb
[`Healthcheck::ScheduledPublishing`]: https://github.com/alphagov/publisher/blob/2f63ea01c6b504b0a50657f5d3bbbbd3c6542257/app/models/healthcheck/scheduled_publishing.rb
[`Healthcheck::QueueLatency`]: https://github.com/alphagov/publishing-api/blob/c0c69997d1a1c63bdea3581655dd4c3146281443/app/models/healthcheck/queue_latency.rb
[`Healthcheck::SidekiqQueueLatenciesCheck`]: https://github.com/alphagov/search-api/blob/339220141d28d3496af85ab5e40c3fe457c4051d/lib/healthcheck/sidekiq_queue_latencies_check.rb
[`Healthcheck::RerankerHealthcheck`]: https://github.com/alphagov/search-api/blob/339220141d28d3496af85ab5e40c3fe457c4051d/lib/healthcheck/reranker_healthcheck.rb
[`Healthcheck::ElasticsearchIndexDiskspaceCheck`]: https://github.com/alphagov/search-api/blob/339220141d28d3496af85ab5e40c3fe457c4051d/lib/healthcheck/elasticsearch_index_diskspace_check.rb
[`Healthcheck::RegistriesCache`]: https://github.com/alphagov/finder-frontend/blob/60d0fb2d10e503e33c4e4c3da86731d4700b532f/app/lib/healthchecks/registries_cache.rb

[govuk_app_config]: https://github.com/alphagov/govuk_app_config
[asset-manager]: https://github.com/alphagov/asset-manager
[content-data-admin]: https://github.com/alphagov/content-data-admin
[content-publisher]: https://github.com/alphagov/content-publisher
[finder-frontend]: https://github.com/alphagov/finder-frontend
[publisher]: https://github.com/alphagov/publisher
[publishing-api]: https://github.com/alphagov/publishing-api
[search-api]: https://github.com/alphagov/search-api
[signon]: https://github.com/alphagov/signon

[an equivalent implementation]: https://github.com/alphagov/asset-manager/blob/e8b25f21a72948117c7dcb084491af26b949805a/app/controllers/healthcheck_controller.rb
[Prometheus]: https://prometheus.io/
[has a worker to push metrics to graphite]: https://github.com/alphagov/email-alert-api/blob/master/app/workers/metrics_collection_worker.rb
[Amazon ECS]: https://aws.amazon.com/ecs/
