# Draft Stack Rummager

## Summary

RFC 86 proposes setting up a instance of [Rummager][rummager] for the
[draft stack][draft-stack-docs].

## Problem

The [draft stack (content preview)][draft-stack-docs] part of GOV.UK
relies in places on the [rummager service (Search API)][rummager].

There is only one instance of this service, which is primarily used
for the live stack, but is also currently used from some services on
the draft stack (see [govuk-puppet][puppet-frontend-rummager-config]).

The current Rummager instance may expose some associations between
live content and draft content (e.g. draft mainstream browse pages or
taxons), depending on the internal index which is used for the live
content. However, the current trend is that associations with draft
content will be supported for less live content, as more types of
content are migrated to the `govuk` index (see [ADR
4][rummager-adr-4]), as the process of populating this index does not
involve fetching draft content from the Publishing API.

Having some way of including draft content in the responses from
Rummager on the draft stack would make the draft stack more
useful. Previewing pages that use Rummager for some of the data won't
give an accurate representation of what the page would look like if
the relevant content is published.

## Proposal

The proposal made here to improve the user experience on the draft
stack, is to setup a draft instance of rummager, populated with the
appropriate content via the Publishing API, and then switch to using
this from draft services.

[rummager]: https://github.com/alphagov/rummager
[draft-stack-docs]: https://docs.publishing.service.gov.uk/manual/content-preview.html
[puppet-frontend-rummager-config]: https://github.com/alphagov/govuk-puppet/blob/3a874ba1afec98c0aeb7f34c9fe34128340e7363/modules/govuk/manifests/node/s_draft_frontend.pp#L24
[rummager-adr-4]: https://github.com/alphagov/rummager/blob/master/doc/arch/adr-004-transition-mainstream-to-publishing-api-index.md
