# RFC 146 - Implement "Production Deploy Access"

## Summary

GOV.UK engineers currently have one of two levels of access: "Integration access" or "Production access".

This RFC proposes a middle level of access - "Production deploy access" - which allows engineers to deploy code but not administer related systems. This level of access should be granted to both civil servants and contractors as needed.

Engineers should be given "Production deploy access" once they've been working with us long enough for their tech lead to have confidence they understand how to use the access and where to get help if they need it.

To avoid confusion, the existing "Production" access level should be renamed to "Production Admin" access.

## Problem

There is [a defined set of rules for getting production access](https://docs.publishing.service.gov.uk/manual/rules-for-getting-production-access.html) which requires engineers to do two 2ndline support shifts before they can be granted access.

This can take a long time even in the best case, and doesn't work well in several common situations:

- contractors tend not to do 2ndline shifts, as it's outside their scope of work
- we make ad hoc access exceptions for senior hires (such as lead technical architects) who need some access to systems, but don't necessarily need full production admin access
- experience of doing 2ndline shifts is not necessarily the best preparation for working with production systems, particularly for frontend developers
- our process for when junior developers and apprentices should be given production access isn't clear

There have been numerous cases where teams with only a few people with production access are slowed down because deployments become a bottleneck.

[RFC 128 - Continuous Deployment](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-128-continuous-deployment.md) has in some ways made the situation worse. We wanted to make sure that rolling out continuous deployment didn't inadvertently weaken a policy, so we disabled merge access for people without production access on repositories which were continuously deployed.

There were [attempts at formalising this process around 2016](https://docs.google.com/document/d/1lo1JAkFIeWrIl-7bzkzps8rYi2hscV6IOpDzc8dhFLs/edit#). Unfortunately we didn't go into detail on why 2ndline shifts were required. The theory is that the logic went something like this:

- In the early days of GOV.UK our deployment pipeline and monitoring was immature
- This meant that debugging issues with deployments often required ssh access
- In turn, this meant that only people with ssh access were allowed to do deployments
- Because it's easy to make mistakes when using highly privileged access through ssh, we required people to do a couple of 2ndline shifts to make sure they knew what they were doing

Note that by this logic, the 2ndline requirements are defending against accidental mistakes, not against malicious access. We have separate defences against malicious employees (security clearance, probation etc.).

## Proposal

We should implement a new level of access - "Production Deploy Access". This level of access should include:

- Permission to deploy apps in Jenkins (ideally without Jenkins admin permission)
- Permission to merge continuously deployed applications
- Readonly access to AWS, Fastly, logging systems, etc.
- admin access to GOV.UK Signon (create and edit normal users)

This level of access should not include:

- ssh permission to production or staging
- admin access to the Deploy Jenkins in production or staging
- admin or poweruser access to AWS
- admin access to other systems (e.g. Fastly etc.)
- superadmin access to GOV.UK Signon (create and edit all user types and edit applications)

Engineers should be granted this level of access once they've got the required level of security clearance and have been working on GOV.UK for at least one full month. Access should be granted at the discretion of the engineer's tech lead. Before approving access, tech leads should ensure that the engineer:

- is aware of our processes and standards around code review
- understands the responsibilities that releasing code brings with it
- knows how to roll back to an older release if there are any issues
- knows how to get help from someone with more access if they need it

These rules should be the same for contractors and civil servants at all levels. Junior and apprentice developers should be given production deploy access once their tech lead feels it's appropriate.

The rules for gaining Production Admin Access should remain the same - engineers will still be required to complete two 2ndline shifts.

## Consequences

We will update the [Rules for Getting Production Access](https://docs.publishing.service.gov.uk/manual/rules-for-getting-production-access.html) to match the outcome of this RFC.

We will create a new GitHub Team for the middle level of access, so we'll have "GOV.UK", "GOV.UK Deploy", and "GOV.UK Production".

We will set up the staging and production deploy Jenkins instances to allow people in the GOV.UK Deploy GitHub Team to trigger builds.

The bottleneck of needing people with production access to merge and deploy code will be substantially widened, since it will be much easier to give people deploy access.

## Appendices

### Access Levels

[This spreadsheet gives the levels of access we expect people to have](https://docs.google.com/spreadsheets/d/1oqy7tKpB8mHBhHQ9jAZu0NR0GKKZXOqtQGBKHYVnpmk/edit#gid=0).
