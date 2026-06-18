---
status: draft
implementation: draft
status_last_reviewed:
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

Analysis of items in content store shows that the regex `/^\/$|^(\/[a-z0-9._-]+)+$/` matches the base paths of all but 2126 content items (out of around 1,008,000), so we have a de facto standard which is adhered to by 99.8% of our content items. If we can somehow handle the remaining 2126 gracefully, we could lock down the allowed paths to only the smaller set, allowing frontend apps to safely reject a number of dubious calls they currently have to handle. We would also be able to put simpler rules into nginx that would lowercase all incoming paths, not just those that are entirely in upper case - this might allow us to retire a number of current redirects as well.

One way of graceful handling would be to allow the potentially invalid urls to continue to be used, but only as redirects. Redirects are currently handled entirely within router, so wouldn't requite any special handling in the frontend apps - only short url manager would have to be excluded from restrictions.

Fortunately, of the 2126 potentially invalid base paths, all but 131 of them already are redirects, reducing the amount of work significantly. 20 of them are invalid only because they include upper case characters, which means if we allowed nginx to lowercase all paths before passing them through, we could lowercase them without breaking links. 96 are invalid because they include `_`s, which we could reasonably redirect to a path with `-`s.  There are two with both underscores _and_ upper case characters, which we could handle with a combination of the above techniques. Finally there are 13 that are content blocks, which seem to have base_paths of the format `/content-blocks/content_block_<type>/<slug>` - since content blocks are few at the moment, it would perhaps be possible to convert these to use dashes in the second part of the path.

### Accents and other languages

One possible concern with the restriction is that we're limiting base paths to english characters. But since GOV.UK is currently a website in English that supports non-English content (ie we can handle non-English content, but the page surrounds are always in English), limiting urls to english characters seems reasonable. The only additional language we're required to support is Welsh, and the written form of Welsh is made entirely of English characters. Welsh does support accents, but it appears to be acceptable in slugs to substitute non-accented versions of the characters (this is what the Welsh government site does). It seems reasonable that we do the same thing (indeed, Whitehall already does this).

## Proposal

We accept that base_paths MUST NOT be longer than 511 characters, MUST start with a /, and MUST contain only the characters `a-z`, `0-9`, `.`, `-`, and `/`.

The only exception allowed to this is for content items of `schema_name: redirect`

- A validation method is added to [gds-api-adapters] which tests a base path passed to it against the new restriction. This becomes the source of truth.
- [gds-api-adapters] methods which are passed a base path use this new method to validate their paths and return GdsApi::InvalidUrl before calling the underlying service.
- Uses of [gds-api-adapters] are audited, and we ensure that any app calling the upgraded methods handles GdsApi::InvalidUrl appropriately.
- [publishing-api]'s base_path validator is updated to use the new validation method from [gds-api-adapters]
- OPTIONALLY we update the regex in [publishing-api]'s schemas to ensure it matches the new restriction (although the one in [gds-api-adapters], shared between apps, should be considered the source of truth about the restriction)
- nginx is configured to make all paths lowercase before passing them through (not just paths that are _entirely_ in upper case)
- content block base paths to be altered to `/content-blocks/<content block schema name with dashes instead of underscores>/<slug>`
- Items in content store/publishing API that are not redirects and include underscores are reslugged to replace the underscores with dashes, and the underscore version remains as a redirect.
- Items in content store/publishing API that include upper case characters in their base_path are reslugged to be lower-case only.

[gds-api-adapters]: https://github.com/alphagov/gds-api-adapters
[handle people typing with their caps lock on]: https://github.com/alphagov/govuk-puppet/pull/4524
[publishing-api]: https://github.com/alphagov/publishing-api
[search-api-v1]: https://github.com/alphagov/search-api
[seen in publishing-api]: https://github.com/alphagov/publishing-api/blob/7e2bf9ef7e7721067a1fc2ef7c2b2ad8aa411c61/content_schemas/formats/shared/definitions/paths.jsonnet#L1-L15
