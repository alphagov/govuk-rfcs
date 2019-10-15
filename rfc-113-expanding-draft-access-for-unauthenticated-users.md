# Expanding draft access for unauthenticated users to allow multi-page fact checks

## Summary

To view content on the [GOV.UK draft stack][govuk-draft] users have to either
be authenticated with [GOV.UK signon][signon] or have a token that grants
them access to that piece of content. Sensitive content is flagged as
access limited, this limits drafts to authenticated users that meet a criteria
(user id or organisation id) or users that have a valid token.

The reason for granting unauthenticated access is to make it easier for
non-GOV.UK editors to fact check content, avoiding the overhead of needing a
GOV.UK signon account and avoiding them having access to all of draft GOV.UK.
Evidence suggests that without a simple process to fact check, editors will
instead turn to a poorer fact check experience (for example, screenshots or
pasting content into an email).

This RFC makes a proposal to expand the unauthenticated access from a single
piece of content to scenarios where content can span multiple pages from
differing publishing applications. This is needed to support the fact checking
of a step-by-step where a step-by-step is both a page and embedded content
that appears on other pages. To review a step by step thoroughly the fact
checker should have access to all these pages and their associated assets.

This proposal suggests the use of a session cookie to store an auth-bypass
token so multiple pages and their assets can be accessed. Access to content
will be granted by using Publishing API [link expansion][] to share an
auth-bypass id, whereas asset access will be provided via a flag within a token
that grants access to any draft assets. This token will not allow bypassing
any access limits set up on the related content or assets.

Key terminology that is used in this RFC:

- **content:** A GOV.UK resource that is available on the [Content Store][]
  at a particular path.
- **asset:** A supporting file resource for GOV.UK content stored on
  [Asset Manager][]; typically images, pdf, Microsoft Office files, etc.
- **auth-bypass id:** A string of data that is used to match whether a
  user is granted access to a particular resource without authentication,
  this is not shown to end users.
- **auth-bypass token:** A [JSON Web Token](https://jwt.io/) that is used to
  encrypt an auth-bypass id and is available to end users.
- **access limited:** A term used to denote draft GOV.UK resources that are
  only accessible by particular users, users in a particular organisation or
  by users that have a token to access them.
- **step-by-step:** A particular document type on GOV.UK which is
  both a page in it's own right and a collection of pages that comprise
  the guidance ([example](https://www.gov.uk/learn-to-drive-a-car)).

[govuk-draft]: https://draft-origin.publishing.service.gov.uk
[link expansion]: https://github.com/alphagov/publishing-api/blob/0ed88b14193f85b1b85b495a7c2617493b3c3ed2/doc/link-expansion.md
[signon]: https://github.com/alphagov/signon
[Content Store]: https://github.com/alphagov/content-store
[Asset Manager]: https://github.com/alphagov/asset-manager

## Problem

GOV.UK editors produce step-by-steps that need fact checking by people who
may not have a GOV.UK signon account. A step-by-step is represented on
GOV.UK as a [step-by-step navigation page](https://www.gov.uk/learn-to-drive-a-car)
with pages that [represent guidance for individual steps][part-of-sbs] and
show the progress within the step-by step. These guidance pages may be
published by any GOV.UK application and may be drafts at the time of
the step-by-step being fact checked. The process of fact checking a
step-by-step involves accessing all of these pages.

The current process to provide unauthenticated access to a GOV.UK draft is to
use an auth-bypass token which allows access to a single content item. In
the context of a step-by-step this can be used to allow access to the
step-by-step navigation page but none of the related pages. This
is not considered adequate by existing editors so is not used for the
fact checking process.

Instead, step-by-steps are fact checked by the use of creating and sharing a
dedicated Heroku application for each step-by-step that needs fact checking.
This is done by someone manually saving each draft page to a HTML file and
then wiring all of these up into an application. This is a cumbersome and time
consuming process, that we believe can be improved.

[part-of-sbs]: https://www.gov.uk/legal-obligations-drivers-riders?step-by-step-nav=e01e924b-9c7c-4c71-8241-66a575c2f61f

## Proposal

In considering how this problem can be resolved questions were raised about
ownership of resources (content and assets) and the rights editors have to
grant - or restrict - access on the draft stack of GOV.UK. Three publication
states were considered - live, draft and access limited -  and their privacy
expectations were defined:

- **Live**: This resource is publicly available on live GOV.UK, there are no
  privacy expectations.
- **Draft**: This resource is available to users with GOV.UK signon accounts,
  access is restricted from the wider internet however it is not considered
  private.
- **Access limited**: this resource is available to a limited set of users
  by an option in the publishing application (for example, Whitehall allows
  limiting content to a users organisation) and a limited number of GOV.UK
  admins. There is an expectation that this resource will be kept private
  from users who do not meet the criteria.

These were then used to form conclusions on the level of access a
step-by-step editor should be able to grant to a fact checker.

The editor should be able to grant access to a fact checker to view the
draft step-by-step navigation page via an auth-bypass token, this should allow
the fact checker to bypass access limits on the content and any assets created
for it.

Content that is linked as part of a step-by-step-navigation (and assets that
are associated with that content) may be published by any publishing application
and by any organisation. A step-by-step editor can grant a fact checker access
to view live and draft resources on the draft stack, however this cannot be
used to provide access to access limited content and assets as this would
break the expectations of privacy.

To provide access across a selection of pages an auth-bypass token would be
stored in a session cookie this would allow maintaining this token across
multiple requests without appending a query string (this cookie
technique is already used for providing an [auth-bypass token to Asset
Manager][asset-manager-auth-bypass]). To provide the auth-bypass id to
supporting pages the Publishing API link expansion system would be used
for particular document and link types.

With access granted to pages users may experience problems viewing them
due to lacking permission to access assets owned by those pages - this would
be seen most visually with broken images. As there isn't a linking system
between assets and content it is impossible to maintain accurate links, thus
an auth-bypass token can grant access to all draft assets for the duration of
a session. Access limited assets must not be accessible in this circumstance
unless the asset contains an auth-bypass id that matches the token.

If there is a need to preview access limited content as part of a fact check
then individual links will have to be provided for those pages.

### Consequences

To support this functionality a number of changes are required in the GOV.UK
stack, these are intended to be non-specific to the step-by-step problem and to
support similar functionality for future GOV.UK content.

- Authenticating Proxy will be changed to recognise auth-bypass tokens that are
  present in cookies.
- Asset Manager will be changed to recognise the presence of a flag in an
  auth-bypass token that will grant an unauthenticated user access to a draft
  asset that is not access limited. Fact checkers are not expected to be able
  to exploit this access given sensitive assets should be access limited and
  the URLs of assets are relatively unpredictable.
- Currently Authenticating Proxy and Asset Manager do not check whether an
  authenticated user has access to a resource if an auth-bypass token is
  present. This introduces potential confusion when this token is provided by
  a session cookie and could prevent an authenticated user viewing other parts
  of draft GOV.UK. To counter this both apps will be changed to consider both
  authentication and auth-bypass token when considering access to resources.
- Content Store will be updated to allow an auth-bypass id to be present in the
  links of a content item, this will be checked against a user provided
  auth-bypass id for content items that are not access limited.
- Publishing API will be changed to support the sharing of auth-bypass ids for
  an edition through link expansion rules.
- Publishing API and Content Store will have their access limit code decoupled
  from auth-bypass ids. This will be done to remove a frequent source of
  confusion that conflates the separate processes of access limiting and
  auth-bypass.
- Collections Publisher will be changed to include a flag in auth-bypass tokens
  that provide access to all draft assets that are not access limited. To
  reflect the increased access of a token they will be given an expiry time
  (anticipated to be 1 month). Collections Publisher will also be updated to
  include origin information in the token (such as creator id and content id)
  to allow a token to be audited. The [auth-bypass token
  documentation][auth-bypass-token-docs] will be updated to
  reflect this as the best practice for future auth-bypass tokens.

### Rejected alternative approaches

There were a number of alternative ideas which were considered to provide fact
checking for step-by-steps and were ultimately rejected. This is a quick
compilation of them and the reasons why they were rejected.

#### Providing a link to preview the embedded part of a step-by-step distinct from the content

This would involve creating a page which shows just the step-by-step
navigation component that is embedded on linked pages. This was deemed
insufficient as fact checkers are often comparing the step-by-step navigation
with the context of the specific guidance pages.

#### Providing a means to embed the step-by-step component into live content

This would involve a means of injecting the step-by-step navigation component
into live GOV.UK pages via JavaScript. This would prevent a fact checker of a
step-by-step from viewing any draft content except the step-by-step
navigation itself. This was quickly rejected as it was considered to be a
common scenario for the pages that are part of a step-by-step
to also be drafts.

#### Exclude asset access from fact-checking

Assets are the area of access that provide the most complication since they
are distinct from the Publishing API link system. An option was to exclude
them from the access checks and have them return forbidden errors if a
step-by-step page used them - this would typically be most noticeable on an
embedded image.

This option was rejected due to it leaving a problem that could be easily
anticipated and likely having to fall to a support team to resolve or explain
whenever it occurs.

#### Providing a fact checker access to all resources on the draft stack that are not access limited

An approach that was considered was to allow a fact checker to have access
to all pages on the draft stack that are not access limited. This would grant
them similar access to an authenticated user. This offered the advantage that
it allows simplifying the logic involved in checking tokens and is consistent
with privacy expectations.

This was rejected since it was a significant departure from the existing access
allowed to a fact checker through an auth-bypass token and may require
considerable communication and consultation time. It remains a viable option
but should be considered as part of a consideration of whether there should be
more accountability and/or simplicity in draft access.

#### Determining which assets a page has to set auth-bypass ids on them

An ideal scenario for asset access would be for it to mirror the system used
for content access as discrepancies between them are a source of complication
and future confusion. To achieve this it was pondered whether there were ways
to share auth-bypass ids with assets in a similar way to how link expansion can
share them between linked content.

An approach to achieve this would be to have Publishing API check content
for asset presence at the point of sending it to the draft content store and
then updating the assets with the relevant auth-bypass ids. Doing this would
require Publishing API to have a dependency on Asset Manager and to have the
means to identify and manage assets.

This approach was rejected due to it risking adding substantial complexity
to Publishing API in order for it to have the means to identify and manage
assets. It was also considered undesirable to couple Asset Manager and
Publishing API since they are currently able to operate distinctly.

#### Automating the generation of a Heroku preview with a GOV.UK signon account

This would involve using a special GOV.UK signon account to download the pages
of the step-by-step and then create a small app that can be hosted on Heroku.
This was rejected due to having a high level of complexity and being
unconventional compared to other GOV.UK apps.

[asset-manager-auth-bypass]: https://github.com/alphagov/asset-manager/commit/7ff9e4bc694850d4bdf1287e388fbf4ac2b1841b
[auth-bypass-token-docs]: https://github.com/alphagov/authenticating-proxy/blob/56939ebb83481076811edcadff60f3a086d2961e/README.md#generating-a-auth-bypass-token
