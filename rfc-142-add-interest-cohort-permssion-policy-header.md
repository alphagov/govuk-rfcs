---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# Add Interest cohort permission policy header

## Summary

Federated Learning of Cohorts is a new technology that exists in versions of Chrome 89+. Its purpose is to replace third party cookies used for tracking and targeting advertising by assigning Chrome users to groups (or cohorts) depending on their browser history. These cohorts can be used for targeted advertising by Google and other advertising networks.

Once enabled, FLoC [calculates a hash based on a user's browser history](https://raw.githubusercontent.com/google/ads-privacy/master/proposals/FLoC/FLOC-Whitepaper-Google.pdf). This hash is synced with the Google servers for the [FLEDGE phase](https://adtechexplained.com/fledge-explained/) of the experiment and is used alongside other Chrome metrics when a FLoC ID is created. Chrome downloads a global FLoC data set to examine if the FLoC ID should be used for exposing ads to a specific user. The FLEDGE phase involves collecting data from [users who meet the following criteria](https://github.com/WICG/floc#qualifying-users-for-whom-a-cohort-will-be-logged-with-their-sync-data) to help train the algorithms they have written for assigning users to interest cohorts. During final implementation the FLoC ID will be generated on a user's device with no server exchanges taking place (for the hash phase).

## Problem

Although documentation mentions the use of sensitive categories in the FLoC specification, it openly admits that:

> Some people are sensitive to categories that others are not, and there is no globally accepted notion of sensitive categories…. It should be clear that FLoC will never be able to prevent all misuse.

At the moment, since this is a small origin trial it is simply opt-in for certain origins. These origins will most likely use advertising, hence why they have signed up to test it. But it is unknown if this will be the case in the future.

In the short term the addition of FLoC actually increases the amount of information available to external observers, as mentioned in [this article from Mozilla](https://blog.mozilla.org/en/mozilla/privacy-analysis-of-floc/):

> It’s possible for a tracker with a significant amount of first-party interest data to operate a service which just answers questions about the interests of a given FLoC ID.

FLoC benefits those observers with lots of first-party data (i.e. Google) and can be far more beneficial than cookies. It allows those companies to understand new interests without the need for trackers to be present on all sites a user visits, but the key here is that they already are aware of the tie between that cohort <> interest via first-party data.

FLoC also circumvents some mitigations already put in place to limit data shared across domains. Browsers are rolling out partitioned storage, which restricts observers to only see information from their single domain. As the FLoC ID is generated from the browser history from a range of sites, FLoC actually results in the leaking of more data. This results in the observer seeing more information than they would without FLoC enabled. See “FLoC leaks more information than you want” in [Mozilla’s Privacy analysis of FLoC]( https://blog.mozilla.org/en/mozilla/privacy-analysis-of-floc/).

It’s also worth noting that privacy lobbies are concerned with FLoC. The Electronic Frontier Foundation (EFF) published articles “[Don't Play in Google's Privacy Sandbox](https://www.eff.org/deeplinks/2019/08/dont-play-googles-privacy-sandbox-1)” and “[Google’s FLoC Is a Terrible Idea](https://www.eff.org/deeplinks/2021/03/googles-floc-terrible-idea)”. They highlight privacy issues related to fingerprinting, Cross-context exposure (as mentioned above), as well as other areas they are concerned about beyond privacy. These including how targeted advertising can be used for for exploitation, discrimination, and harm.

Since the FLoC specification specifically mentions that it “will never be able to prevent all misuse”, and the GOV.UK domain contains guidance and links to subjects that would be considered very sensitive for users, e.g.:

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

For applications on the PaaS, we'll set the header at the application level.
