## Problem

I think there are two somewhat related problems that I'd like to see
addressed.

Pull Requests by Dependabot, that the guidance describes as requiring
a review from two people are being merged with a single review.

Pull Requests by Dependabot are up for long amounts of time, without
being merged, including those that could be time sensitive like
security fixes.

## Proposal

I think a step forward in addressing both problems would be to not
treat Dependabot as an external contributor when reviewing Pull
Requests, and amend the guidance on reviewing and merging Pull
Requests to permit merging Pull Requests by Dependabot with a single
review.

## Rationale

Currently, Pull Requests by Dependabot are viewed as coming from an
external contributor, and as such, should be reviewed by two people
employed by GDS, working on GOV.UK.

However, Dependabot is already a special case in the following ways:

 - It's an automated service, not a person raising the Pull Requests
 - Dependabot pushes changes directly to the repositories hosted on
   the alphagov GitHub organisation, rather than using a fork of the
   repository
 - It should only be changing files in the repositories relating to
   the versions of dependencies (Gemfile and Gemfile.lock in the case
   of Rubygems/Bundler)

Therefore, to try and decrease the amount of time Pull Requests remain
open, and reduce the amount of time spent reviewing them, the proposal
is to amend the guidance to only require a single review on GitHub.

Since the introduction of Dependabot, merging Pull Requests with only
a single review has been happening, including when this doesn't adhere
to the guidance. Having more approvals than necessary is good, but
having fewer doesn't match up with the current guidance, so this
change would make the guidance and practice line up better.
