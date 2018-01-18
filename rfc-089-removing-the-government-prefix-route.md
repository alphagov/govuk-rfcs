# Removing the /government prefix route

## Summary

The /government prefix route is a large source of uncertainty, and
because of this uncertainty it is quite difficult to work out what
specific content still uses it. Changing the way the traffic is
handled could offer a methodical way of tracking what the remaining
work is to make the /government prefix route redundant.

## Problem

The /government prefix route is a large source of uncertainty in the
context of the rest of the routing on GOV.UK. It's hard to tell what
it's responsible for, and thus what work needs doing to get Whitehall
content to manage it's own routes.

Also, while I think it would be possible in the router to have
separate handlers for /governement as an exact route, and /government
as a prefix route, this isn't supported in either the Publishing API
or Router API. This means that /government (the exact path) is
currently stuck being rendered by whitehall-frontend.

## Proposal

There are some known groups of content rendered by whitehall-frontend
for which the routing information isn't explicitly set in the
Publishing API.

However, even if that were fixed, due to the nature of the problem,
the uncertainty of what this prefix route is responsible for, it would
be hard to tell what routing information is missing from what content.

### Action Plan

To make it possible to measure and track what requests are still being
managed by the /government prefix route, the traffic to
whitehall-frontend could be split at the router.

Instead of all traffic going directly to whitehall-frontend, a new
virtual host, say whitehall-frontend-prefix-route could be created,
which like the whitehall-frontend virtual host would reverse proxy to
the whitehall-frontend. The rendering app for the special-route at
/government would then be changed to whitehall-frontend-special-route,
to direct traffic handled by the prefix route to this new virtual
host.

This wouldn't change the experience for users, but would allow
tracking what successful requests are being made through the
whitehall-frontend prefix route. If there comes a time when all the
recent requests haven't been successfull (e.g. all responded to with a
404 status), then this would suggest that the routing information for
content rendered by whitehall-frontend is complete enough to do
without the /government prefix route.
