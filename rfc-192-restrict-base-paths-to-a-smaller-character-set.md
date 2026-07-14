---
status: accepted
implementation: in progress
status_last_reviewed: 2026-07-14
---

# Restrict base paths to a smaller character set

## Summary

The validations we run on base paths on GOV.UK are too permissive, making it difficult to easily
filter out invalid ones. The systems we currently have for filtering valid requests vary across
different apps, and are not in line with the intuition of our developers. We propose restricting
base paths to a much smaller character set (`a-z 0-9 . / -`). 99.8% of our content items are
compliant with this restriction already.

## Problem

The restrictions we've placed on what constitutes a valid base path are currently pretty permissive ([seen in publishing-api]). There's a straightforward length restriction (Elasticsearch, used by [search-api-v1] can't handle paths longer than 511 chars), but the characters allowed are quite broad. They allow upper and lowercase letters, a selection of special characters including `@`s and `%` signs followed by hexadecimal codes. This presents a few problems.

1) It's hard for frontend apps to deal quickly with obvious penetration attempts like `GET /find-local-council/%20HTTP/1.1%0D%0X-header:%20attempt`. This is clearly not a reasonable URL, but it _might_ be, so frontend apps have to pass it on to content-store (or the GraphQL endpoint), for them to reject it. And
although content-store _does_ have code to handle requests like these before they get to a database call, it's not clear that's actually the correct behaviour. This URL _is_ valid according to our current validations, so there aren't safe rules to reject it.
2) The inclusion of characters in both cases means that we can potentially (and do in fact) have content items with base paths that rely on case. Potentially
a publishing app could write separate content items to gov.uk/example and gov.uk/Example and they would behave differently. Instinctively people tend to assume
that urls are case-insensitive, and we have previously put code in to [handle people typing with their caps lock on]. But this has led to an even odder situation
in which gov.uk/EXAMPLE, GOV.UK/EXAMPLE, gov.uk/example would all resolve to the same content item, but gov.uk/Example would not.

Analysis of items in content store shows that the regex `/^\/$|^(\/[a-z0-9.-]+)+$/` matches the base paths of all but 2126 content items (out of around 1,008,000), so we have a de facto standard which is adhered to by 99.8% of our content items. If we can somehow handle the remaining 2126 gracefully, we could lock down the allowed paths to only the smaller set, allowing frontend apps to safely reject a number of dubious calls they currently have to handle. We would also be able to put simpler rules into nginx that would lowercase all incoming paths, not just those that are entirely in upper case - this might allow us to retire a number of current redirects as well.

One way of graceful handling would be to allow the potentially invalid urls to continue to be used, but only as redirects. Redirects are currently handled entirely within router, so wouldn't requite any special handling in the frontend apps - only short url manager would have to be excluded from restrictions.

Fortunately, of the 2126 potentially invalid base paths, all but 131 of them already are redirects, reducing the amount of work significantly. 20 of them are invalid only because they include upper case characters, which means if we allowed nginx to lowercase all paths before passing them through, we could lowercase them without breaking links. 96 are invalid because they include `_`s, which we could reasonably redirect to a path with `-`s.  There are two with both underscores _and_ upper case characters, which we could handle with a combination of the above techniques. Finally there are 13 that are content blocks, which seem to have base_paths of the format `/content-blocks/content_block_<type>/<slug>` - since content blocks are few at the moment, it would perhaps be possible to convert these to use dashes in the second part of the path.

### Accents and other languages

One possible concern with the restriction is that we're limiting base paths to english characters. But since GOV.UK is currently a website in English that supports non-English content (ie we can handle non-English content, but the page surrounds are always in English), limiting urls to english characters seems reasonable. The only additional language we're required to support is Welsh, and the written form of Welsh is made entirely of English characters. Welsh does support accents, but it appears to be acceptable in slugs to substitute non-accented versions of the characters (this is what the Welsh government site does: go to https://www.llyw.cymru/ and hover over `Y môr a physgodfeydd` for an example - the URL is https://www.llyw.cymru/y-mor-a-physgodfeydd). It seems reasonable that we do the same thing (indeed, Whitehall already replaces accented characters with their unaccented versions).

### Router and Short URL Manager

For the initial part of the work, we can lean on the fact that [router] can handle redirects without sending them to another app. The non-compliant base paths are either already redirects or can be replaced with redirects. This means that the frontend apps can be strict about what they're taking without losing URLs that are already "in the wild" - these will simply be caught by router and redirected to compliant apps.

Since we'll still want to manage these non-compliant base paths, [short-url-manager] (the standard management tool for redirects) will be exempted from the new base_path restrictions - that is, it will still be possible to create and manage otherwise invalid base_paths, but _only through [short-url-manager]_.

## Proposal

We accept that base_paths:
- MUST NOT be longer than 511 characters
- MUST start with a `/`
- MUST contain only the characters `a-z`, `0-9`, `.`, `-`, and `/`.
- MUST NOT contain two / or dot characters in a row (in any combination: `//` `..` `./` and `/.` are all invalid)

The only exception allowed to this is for content items of `schema_name: redirect`

### Work required to support this RFC

#### 1. Rules are enforced on new items
- A validation method is added to [gds-api-adapters] which tests a base path passed to it against the new restriction. This becomes the source of truth.
- [publishing-api] uses this method to validate new base paths on everything except redirects, which enforces the rules on new items coming in from all publishing apps.
- OPTIONALLY the regex in [publishing-api]'s schemas is updated to ensure it matches the new restriction (although the one in [gds-api-adapters], shared between apps, should be considered the source of truth about the restriction) _(benefit: additional cross-test, cost: potential for drift, additional effort)_
- OPTIONALLY publishing apps can replace any internal validation they run on base paths with the new method from gds-api-adapters _(benefit: publishing apps could fail fast, and wouldn't call [publishing-api] with invalid base paths. cost: additional effort)_
- OPTIONALLY [gds-api-adapters] methods which write to publishing API can include the new method and fail fast _(benefit: as above, but publishing apps wouldn't have to call the new method themselves to fail fast. cost: additional effort)_
- OPTIONALLY Uses of [gds-api-adapters] are audited, and we ensure that any app calling the upgraded methods handles GdsApi::InvalidUrl appropriately. _(benefit: we ensure that there aren't unexpected failures in the future where an app calls without understanding it may get an immediate failure from the API client. cost: additional effort, plus we could capture these when they fail via sentry - it's not too awful to leave this until it affects users because even if fixed they wouldn't be getting the page they were looking for.)_

...at this point, all _new_ base_paths coming into the system are compliant.

#### 2. Cleaning up / preparing existing items
- content block base paths to be altered to `/content-blocks/<content block schema name with dashes instead of underscores>/<slug>`
- Items in content store/publishing API that are not redirects and include underscores to be reslugged to replace the underscores with dashes, with the underscore version remaining as a redirect.
- Items in content store/publishing API that are not redirects and include upper case characters in their base_path are reslugged to be lower-case only, with the mixed case version remaining as a redirect

...at this point, all non-compliant paths are redirects, and all non-redirects have a compliant path.

#### 3. Update NGINX rules to enforce lower-case in all situations
- nginx is configured to make all paths lowercase before passing them through (not just paths that are _entirely_ in upper case)
- Items in content store that exist only as mixed-case redirects can be deleted at this point. (including those added as redirects to lower-case in step 2).

...at this point, all paths in the system are compliant except for those handful that include underscores and odd characters, but they are still handled by their existing redirects. OPTIONALLY we could also look at the very weird redirects and determine if they're still valid (ie are they solving a real problem, or are they from typos in [short-url-manager])

## Benefits of implementing the RFC

- All apps will share a single view of what a valid base path is (through the shared method in [gds-api-adapters]), reducing mismatches between publishing apps and the publishing platform. The current gap between what publishing apps, the platform, and the frontend apps consider valid base_paths is both a security risk in itself and a source of unexpected errors and toil.
- Improved security for frontend apps, and reduced internal traffic. Rather than having to pass them through and rely on [content-store] or [publishing-api] catching them, frontend apps will be able to trivially reject attack attempts such as those includeding:
    - Encoded control characters
    - Path traversal attempts
    - Malformed requests
- GOV.UK's handling of mixed case URLs in requests will be simplified (every call including upper-case letters will be replaced with the lower-case variant), reducing surprise behaviour.
- It will also be proactive, reducing the number of direct interventions necessary when an advertising campaign includes mixed case in the contact URL.
- We will be able to get rid of redirects that only exist to handle mixed case.

## The Future

One remaining question is what we should do if [router] is retired? The trend towards app consolidation may result in a situation where non-redirect routing is so simple that it can be handled entirely in nginx (that is, a handful of known prefixes are routed by nginx static rules, and everything else goes to Frontend). In that case, Frontend would have to have an additional pass before routing to content store to identify redirects. Nearly 20% (188k) of content items in content-store are redirects, so this is clearly not a trivial task. But it would be exactly the same question as what we do with the rest of those redirects, so it at least adds no additional complexity to the question of [router] retirement.

[gds-api-adapters]: https://github.com/alphagov/gds-api-adapters
[handle people typing with their caps lock on]: https://github.com/alphagov/govuk-puppet/pull/4524
[publishing-api]: https://github.com/alphagov/publishing-api
[router]: https://github.com/alphagov/router
[search-api-v1]: https://github.com/alphagov/search-api
[short-url-manager]: https://github.com/alphagov/short-url-manager
[seen in publishing-api]: https://github.com/alphagov/publishing-api/blob/7e2bf9ef7e7721067a1fc2ef7c2b2ad8aa411c61/content_schemas/formats/shared/definitions/paths.jsonnet#L1-L15
