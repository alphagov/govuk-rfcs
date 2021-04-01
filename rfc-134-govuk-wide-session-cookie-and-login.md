# A GOV.UK-wide session cookie & login

## Summary

We propose introducing a new cookie, `__Host-govuk_account_session`,
which will be an essential cookie, but only set when a user signs in
to use personalised parts of GOV.UK (currently just the Transition
Checker).

Similarly to how our A/B tests work we will manage this cookie at the
Fastly layer, in Varnish Configuration Language (VCL), and use custom
request headers to pass the cookie value to our apps. We will also use
custom response headers to set a new cookie value.

We will create a new app to provide the internal account-supporting
API, and extend frontend to handle the login and logout process.

## Problem

The GOV.UK Account team have launched an experiment on the Transition
Checker, allowing users to sign up to save their
results. [finder-frontend sets a session cookie][ff-session]—an
encrypted cookie—containing the user ID and OAuth tokens used to
update the data we hold on them.

This works fine for one app, but there are problems with this approach
when we try to scale to more than one app.

[ff-session]: https://github.com/alphagov/finder-frontend/blob/5b6101e8eb027028a102ab96bcef6ff752b9c558/app/controllers/sessions_controller.rb#L23-L28

### We need to pass cookies to our apps

Our Nginx configuration blocks most cookies, [which we disabled for
the Transition Checker][tc-cookie-pr]. If multiple apps need to
consume the session cookie, then this blocking will be disabled for
ever-increasing chunks of GOV.UK.

[tc-cookie-pr]: https://github.com/alphagov/govuk-puppet/pull/10788

### Apps need to share the same session cookie

It's no good if the user has to log into each part of GOV.UK
individually.  For example, say we personalise taxon pages: a user
shouldn't have to log into finder-frontend (for the Transition
Checker) and collections (for the taxon pages) separately.

There needs to be one session shared across them all.  If we use Rails
session cookies for this, we need to make sure all apps use the same
encryption key.

### Which app handles logging in and out?

If there is one session cookie used for all of GOV.UK, which app sets
that?

Somewhere there needs to be a login controller and a logout controller
which manipulate the cookie. These controllers will redirect the user
to the GOV.UK Account system to do the actual authentication, but we
need something on www.gov.uk itself to set the cookie.

### Non-personalised parts of GOV.UK won't manipulate the session cookie

It's unlikely that all of GOV.UK will be personalised, so there will
be islands of personalised content.  Currently there is the Transition
Checker.  Maybe next will be some guidance pages, or something else.
We want to keep the user's session alive while they are browsing the
non-personalised parts of GOV.UK, otherwise we risk this bad
experience:

1. The user logs in to use some personalised part of GOV.UK.

2. The user then spends 30 minutes (or whatever we use for the session
   duration) viewing non-personalised parts of GOV.UK, but without
   leaving the site.

3. The user then tries to use another personalised part of GOV.UK, but
   their session has expired, because the non-personalised parts
   weren't bumping the expiration time on every page view.

### We can't cache as effectively

The Fastly docs have some [comments on the risks of cookies][fastly-cookies-risks]:

> Cookies can lead to undesirable outcomes.  At worst, if a cookie
> header is forwarded to your backend server, the backend uses the
> cookie value to generate personalized content, and that content is
> then cached by Fastly, a user may end up receiving content intended
> for someone else.  A theoretical solution to this, adding a Vary:
> Cookie header to the response, leads to another bad outcome: the
> response is most likely not cacheable at all, and Fastly will
> forward all requests to your backend.

[fastly-cookies-risks]: https://developer.fastly.com/reference/http-headers/Cookie/

## Proposal

### Set a session cookie on www.gov.uk

We'll set a new cookie, `__Host-govuk_account_session`, on www.gov.uk.

This cookie will hold:

- The OAuth access token
- The OAuth refresh token

The access and refresh tokens are opaque and difficult-to-guess
strings.

This cookie is a secure, [domain-locked][], session cookie:

```
Set-Cookie: __Host-govuk_account_session=<value>; secure; httponly; samesite=lax; path=/
```

It can be expired, logging a user out, by re-setting it with
`max-age=0`.

This cookie cannot be set on the `gov.uk` domain, so service domains
will need to re-authenticate and manage their own sessions.  This RFC
is just about authentication and attribute use on www.gov.uk itself.
The cross-government single-sign-on part of this work is out of scope.

[domain-locked]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Cookie_prefixes

#### Session duration

The cookie is a session cookie.  We will not implement any server-side
expiration mechanism, though if needed we can revoke or expire the
refresh tokens.

#### ID tokens

We will not store an OpenID Connect [ID token][] in the cookie.
Instead the internal API app will make a UserInfo request to look up
subject identifiers using the OAuth access token.

[ID token]: https://openid.net/specs/openid-connect-core-1_0.html#IDToken

#### Security considerations

Access tokens have a short lifespan, and will only have access to:

- Read from the OpenID Connect UserInfo endpoint, which returns data
  about the current user.

- Write to an internal API app (not exposed to the internet) which,
  like our other API apps, will be authenticated with Signon bearer
  tokens.

Refresh tokens have a long lifespan, but using one requires the OAuth
client credentials, which are only made available to the internal API
app.

### Use custom HTTP headers to pass the cookie around

[Fastly's best practices for cookies][fastly-cookies-practices]
suggest parsing cookies into custom headers and using these headers
for caching purposes, rather than caching based on the entire
`Set-Cookie` header (which in our case also contains
non-account-related things like A/B test bucket assignment, Google
Analytics session ID, and cookie consent preferences).

In addition, we have nginx configuration to strip out `Set-Cookie`
headers.  By using custom headers we keep that logic in place,
ensuring we can't make a mistake and start setting a cookie from one
of our apps inappropriately.

We will introduce two new headers:

- `GOVUK-Account-Session`: holds the session cookie value.  Set by
  Fastly to pass the cookie to our apps, set by our apps to create a
  new cookie.

- `GOVUK-Account-End-Session`: set by our apps to expire the cookie.

We will need to make two changes to our VCL.

[fastly-cookies-practices]: https://developer.fastly.com/reference/http-headers/Cookie/#best-practices

#### Changes to `vcl_recv`

When receiving a request, extract the cookie value and pass it in the
header:

```vcl
set req.http.GOVUK-Account-Session = req.http.Cookie:__Host-govuk_account_session;
```

#### Changes to `vcl_deliver`

If the response depends on the user session, it must either:

1. Set a `Vary: GOVUK-Account-Session` header, or
2. Set headers to prevent caching entirely

When delivering a response to the user, set a new cookie with a new
expiration time, and disable shared caches outside of Fastly (both
Fastly and the user's browser can still cache the page) if the
response depended on the session:

```vcl
if (resp.http.GOVUK-Account-End-Session) {
  add resp.http.Set-Cookie = "__Host-govuk_account_session=; secure; httponly; samesite=lax; path=/; max-age=0"
  unset resp.http.GOVUK-Account-End-Session;
} else if (resp.http.GOVUK-Account-Session) {
  add resp.http.Set-Cookie = "__Host-govuk_account_session=" + resp.http.GOVUK-Account-Session + "; secure; httponly; samesite=lax; path=/"
}

if (resp.http.Vary ~ "GOVUK-Account-Session") {
  unset resp.http.Vary:GOVUK-Account-Session;
  set resp.http.Cache-Control:private = "";
}

unset resp.http.GOVUK-Account-Session;
```

### Extend frontend to manage the auth process

It's weird to have the login and logout controllers for GOV.UK as a
whole located under `/transition-check`.

We will instead add the following endpoints to frontend:

- `GET /sign-in`: initiates the OAuth flow with the accounts system
  and sends the user on a consent journey.  Accepts these parameters:

    - `_ga`: cross-domain tracking parameter to pass to the accounts
      domain (optional)
    - `redirect_path`: path on GOV.UK to redirect back to after
      authenticating (optional, default: `/`)
    - `state_id`: see below (optional)

  This calls `GET /api/oauth2/sign-in` to get the URL to redirect the
  user to.

- `GET /sign-in/callback`: where the accounts system sends the user
  back to.  Sets the `GOVUK-Account-Session` response header if the
  user successfully signed in.  Redirects the user back to the
  `redirect_path`.

  This calls `POST /api/oauth2/callback` to create the session.

- `GET /sign-out`: sets the `GOVUK-Account-End-Session` response
  header.  Accepts these parameters:

    - `redirect_path`: path on GOV.UK to redirect back to after
      signing out (optional, default: `/`)

These endpoints are just part of redirection flows, they have no
visible response.

### Create a new app to provide internal APIs

We will create a new app—called account-api, which will live on a new
machine class called personalisation—to manage sessions and to handle
OAuth interactions with the GOV.UK Account system.

The app will serve these internal endpoints:

- `GET /api/attributes`: looks up and returns some attributes from the
  user's account.  Accepts these parameters:

    - `session`: the `GOVUK-Account-Session` header value
    - `attributes`: list of attribute names

  Returns either a 401 (if the access and refresh token have expired /
  been revoked) or a hash of attribute names and values and a
  `GOVUK-Account-Session` with a fresh access token, if the old one
  expired.

- `PATCH /api/attributes`: sets some attribute values on the user's
  account.  Accepts these parameters:

    - `session`: the `GOVUK-Account-Session` header value
    - `attributes`: hash of attribute names and values

  This is a partial update.  Attributes *not* named in the hash keep
  their previous values.

  Returns either a 401 (if the access and refresh token have expired /
  been revoked) or a new `GOVUK-Account-Session` with a fresh access
  token, if the old one expired.

- `GET /api/oauth2/sign-in`: returns a URL to redirect the user to, to
  initiate the OAuth login/consent flow.  Accepts these parameters:

    - `redirect_path`: (optional, default: `/`)
    - `state_id`: (optional)

- `POST /api/oauth2/callback`: returns a session value, if the user
  has successfully authenticated.  Accepts the parameters from the
  OAuth response, which will depend on the flow we use.  For example,
  if we use the `code` flow, the parameters will be `code` and
  `state`.

- `POST /api/oauth2/state`: sets some attribute values that will be
  persisted if the user creates a new account, regardless of whether
  the user returns to GOV.UK.  Accepts these parameters:

    - `attributes`: hash of attribute names and values

    Returns an ID which can be passed to `/sign-in`.  The record
    expires after 1 hour.

### How the Transition Checker will work

Here are a few examples of how the Transition Checker will work with
endpoints moved to frontend and to account-api:

#### Clicking the "Sign in" link in the header

1. The link sends the user to `/sign-in?redirect_path=...&_ga=...`

2. The user is redirected to the GOV.UK Account service domain

3. The user authenticates (registers or signs in)

4. The user is redirected to `www.gov.uk/sign-in/callback?...`

5. The internal API app validates the OAuth response and returns the
   value for the session header.

6. The `GOVUK-Account-Session` response header is set

7. The user is redirected to `redirect_path`

#### Clicking the "Create a GOV.UK account" button on the results page

1. The button sends the user to a new controller in finder-frontend,
   which:

   - Calls `/api/oauth2/state` with the user's answers, generating an ID
   - Redirects the user to `/sign-in?state_id=...&redirect_path=...&_ga=...`

2. The new app passes the state attributes to the accounts system

3. The user is redirected to the accounts system, auths, and is sent
   back (as in steps 2, 3, and 4 above)—but if the user registers, the
   accounts system saves the provided attribute values

4. The new app creates the session and sends the user to the
   `redirect_path` (as in steps 5, 6, and 7 above)

This set-some-attributes-on-register flow is necessary because we
display a confirmation page after the user signs up.  This page
welcomes the user, says we've sent them a confirmation email, and
gives a link back to the service.  We want to persist the attributes
even if the user does not click that link.

We plan to remove the `state_id` mechanism when we retire the
Transition Checker experiment.

### Local development

A Fastly-managed cookie won't work when running GOV.UK apps locally.

To support that use-case, if `Rails.env.development?`, the new app
will set an unencrypted `govuk_account_session` cookie, on the domain
`dev.gov.uk`, which contains the session information, in addition to
sending the response headers.
