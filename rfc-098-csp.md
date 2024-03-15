---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
status_notes: RFC may not be accurate in the implementation details.
---

# RFC 98: Implement Content Security Policy

## Summary

This RFC proposes to configure a Content Security Policy for GOV.UK.

## Background

We'd like to implement a Content Security Policy (CSP) on www.gov.uk.

> The HTTP Content-Security-Policy response header allows web site administrators to control resources the user agent is allowed to load for a given page. With a few exceptions, policies mostly involve specifying server origins and script endpoints. This helps guard against cross-site scripting attacks (XSS).

https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

CSP works by sending a header with each HTTP response. It looks something like this:

```
Content-Security-Policy: default-src 'self' assets.publishing.service.gov.uk;
```

The above will cause the browser to reject any scripts that aren't on the current domain (`self`) or `assets.publishing.service.gov.uk`. It will also reject Javascript loaded via `<script>` tags.

For an example close to home, GOV.UK Verify use the following policy:

```
$ curl -si 'https://www.signin.service.gov.uk/start' | grep 'Content-Security-Policy:'
Content-Security-Policy: default-src 'self'; font-src 'self'; img-src 'self'; object-src 'none'; script-src 'self' 'unsafe-eval' 'sha256-+6WnXIl4mbFTCARd8N3COQmT3bJJmo32N8q8ZSQAIcU=' 'sha256-G29/qSW/JHHANtFhlrZVDZW1HOkCDRc78ggbqwwIJ2g=' 'unsafe-inline'; style-src 'self' 'unsafe-inline'
```

It's implemented [in the verify-frontend Rails app](https://github.com/alphagov/verify-frontend/blob/5a12b82e8cf4dc202335e52a8e6875ad5179420d/config/application.rb#L46-L55).

### Why CSP

We've got 2 things in mind that CSP will help with:

- It an extra defence against cross-site scripting vulnerabilities, such as the one [we saw earlier this year on finder-frontend](https://github.com/alphagov/govuk_publishing_components/pull/283).
- Publishers use [Govspeak](https://github.com/alphagov/govspeak) in publishing applications to mark up their content. When the content is published, it's converted into HTML. The resulting HTML is persisted in the content-store for the frontends to use (which [we have to trust](https://github.com/alphagov/government-frontend/search?q=html_safe)). This means that if the the content-store is compromised we could be serving malicious HTML from the frontends. CSP mitigates against that by limiting the type of things the browser will run.

## Problem

We have 3 options for adding the header to the HTTP response: on the CDN, in the application, and in Nginx.

- **Configure in CDN** - configure Fastly so it sends the header on each request. This is what [we've done during our initial experimentation](https://github.com/alphagov/govuk-cdn-config/pull/94).
- **Configure in app** - configure the Rails apps to send the header. This is [what verify-frontend does](https://github.com/alphagov/verify-frontend/blob/5a12b82e8cf4dc202335e52a8e6875ad5179420d/config/application.rb#L46-L55).
- **Configure in Nginx** - configure Nginx so it sends the header on each request. This is what [is done to set up STS](https://github.com/alphagov/govuk-puppet/blob/8f5152e86fb6b105817bd977752c18c603395585/modules/nginx/files/etc/nginx/add-sts.conf).

### Trade-offs

| | Configure in CDN | Configure in app | Configure in Nginx |
| --- | --- | --- | --- |
| Deployment | The CDN is easily and fast to deploy | Slow to roll out and iterate. We'd probably add it to `govuk_app_config`, which requires a version bump in ~15 applications. Allows staged rollout. | Slow deployments via Puppet |
| Policies | The CSP header is set consistently for all of the requests, even ones that aren't served from a Rails app like [Licensing](https://github.com/alphagov/licensify) | Allows per-app custom policies - for example, whitelisting [webchat domains only for contact pages](https://github.com/alphagov/govuk-cdn-config/pull/96/commits/913202a1de8f4993b1ff4605553d7328b9e8e640) | Allows sharing of CSP between the frontend apps and publisher apps |
| Development | It doesn't work locally - your app will work in development and on Heroku, but might not work on integration, staging, and production | Works locally just like in production. We'll have to update the CSP in development to allow `localhost` and `dev.gov.uk` domains | Works locally if using the VM (doesn't work on Heroku or non-VM) |

## Proposal

We'll configure the CSP header each application.

We're optimising for safety and incremental rollout, at the cost of consistency across GOV.UK, and completeness.
