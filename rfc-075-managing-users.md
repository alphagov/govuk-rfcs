# Managing users on GOV.UK

## Summary

Create a central repository of users in GOV.UK. Use that to verify that the
correct people have access.

## Context

Tech staff on GOV.UK can have access to dozens of things, like SSH access, GitHub organisation membership, and AWS accounts. When someone leaves access is revoked [using a check list][leaver] in a leavers card on the 2nd line Trello.

## Problem

1. The leavers process is slow and manual (and a bit boring). This means sometimes leavers aren't removed as quickly as we want.
2. The process of removing people from access lists is based around making _changes_. There is no system in place that verifies that everyone who currently has access is actually allowed to. This means that if someone processes a leaver ticket and forgets a step, a user account can linger around forever.
3. We'd like to use [GitHub teams for authentication to our Jenkins][jenk]. There are some concerns around that because it's very easy to add people to teams, and there is little visibility around the membership changes.

[jenk]: https://github.com/alphagov/govuk-puppet/pull/5910

## Proposal

We make a central list of GOV.UK users. We use this list to periodically verify that only the correct people have access. We do this by creating a Jenkins job that alerts Slack and Icinga if there are unexpected users with access to something.

This will make the leavers process more deterministic. It also prevents people from being added to the GitHub team outside our normal process.

There are a number of potential extensions to this, like adding an expiry date to the user accounts, which means we would get alerted when to remove a user (a concept that bob found in Gitlab).

## Implementation

This is a proof of concept:

<https://github.com/alphagov/govuk-user-reviewer/tree/prototype>

It defines a list of users like this:

```yaml:
- username: johndoe
  github_username: john-code
```

The script in the repo will check:

1. SSH access to (old) CI machines
1. SSH access to mirrors
1. SSH access to backup machines
1. SSH access to integration
1. Access to Jenkins
1. Access to AWS in integration, staging & production (via Terraform)
1. GitHub team membership (the GOV.UK team)

These aren't all the places access lists are defined (see the [rest of the leaver ticket template][leaver]), but it's a start. Once our credential repos are moved to public GitHub, production access can also be checked. Possibly we could create an endpoint for Signon to allow us to verify the admins/superadmins.

[leaver]: https://trello.com/c/PmVyofn8/3-template-leaver-dev-webops
