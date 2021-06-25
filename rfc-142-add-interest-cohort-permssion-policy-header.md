# Add Interest cohort permission policy header

## Summary

Federated Learning of Cohorts is a new technology that exists in versions of Chrome 89+. Its purpose is to replace third party cookies used for tracking and targeting advertising by assigning Chrome users to groups (or cohorts) depending on their browser history. These cohorts can be used for targeted advertising by Google and other advertising networks.

Once enabled, FLoC calculates a hash based on a user's browser history. This hash is synced with the Google servers and is used alongside other Chrome metrics and a FLoC ID is created. Chrome downloads a global FLoC data set to examine if the FLoC ID should be used for exposing ads to a specific user.

## Problem

In the short term the addition of FLoC actually increases the amount of information available to external observers, as FLoC can be used in conjunction with 3rd party cookies, as well as traditional browser fingerprinting techniques. When these techniques are used together, an observer's ability to identify an individual user increases. FLoC also circumvents some mitigations already put in place to limit data shared across domains. Browsers are rolling out partitioned storage, which restricts observers to only see information from their single domain. As the FLoC ID is generated from the browser history from a range of sites, FLoC actually results in the leaking of more data. This results in the observer seeing more information than they would without FLoC enabled.

The FLoC specification specifically mentions that it “will never be able to prevent all misuse”, and the GOV.UK domain contains guidance and links to subjects that would be considered very sensitive for users, e.g.:

- Universal credit login
- Bankruptcy
- Birth, marriage, deaths
- Disability
- Crime, justice and the law

The FLoC specification does suggest that for sensitive categories:

> As a first mitigation, the browser should remove sensitive categories from its data collection. But this does not mean sensitive information can’t be leaked.

However it does not guarantee sensitive information can't be leaked.

To ensure information isn't leaked, an [explicit header can be set](https://github.com/WICG/floc#opting-out-of-computation).

## Proposal

To safeguard our users' sensitive browsing data, GOV.UK should explicitly set this header.

We have 3 options for adding the header to the HTTP response: on the CDN, in the application, and in Nginx.

- **Configure in CDN** - configure Fastly so it sends the header on each request.
- **Configure in app** - configure the Rails apps to send the header.
- **Configure in Nginx** - configure Nginx so it sends the header on each request.

### Trade-offs

| | Configure in CDN | Configure in app | Configure in Nginx |
| --- | --- | --- | --- |
| Deployment | The CDN is relatively easy and fast to deploy | Slow to roll out and iterate. We'd probably add it to `govuk_app_config`, which requires a version bump in multiple applications. Allows staged rollout. | Slow deployments via Puppet |
| Policies | The header is set consistently for all of the requests, even ones that aren't served from a Rails app like [Licensing](https://github.com/alphagov/licensify) | Allows us to target per app and potentially per document type | Allows setting the header for the frontend apps and publisher apps |

### Preferred option

We'll configure the following header in NGINX to ensure we cover frontend apps as well as publishing apps across GOV.UK.

```
Permissions-Policy: interest-cohort=()
```
