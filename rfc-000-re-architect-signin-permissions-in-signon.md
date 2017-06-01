# Re-architect signin permission in signon

## Summary

Change the 'signin' permission in signon to be one that signon itself checks for as part of the oauth handshake and reject users trying to login to applications they don't have access to.

## Problem

In signon all apps have a 'signin' permission and the UI for managing permissions on a user strongly suggests that if the user is not granted this permission for an application they will not be able to access that application.  The reality is that it is up to the applications themselves to care about the 'signin' permission via the gds-sso gem and the `require_signin_permission!` controller method.

This means that for some applications unchecking the "has access to?" box for a user will block them from logging in, but for others it won't.  There's nothing in signon that can explain this to an admin, because signon doesn't know which applications are coded to use `require_signin_permission!` and which allow any signon user.  Only applications that a user has explicit 'signin' permission for are listed on their dashboard so signon users may not even know they have access to an application that allows all users because it won't be listed if they haven't been granted 'signin' permission.

More importantly, for those apps that allow any signon user we have no mechanism to stop a user from accessing that application other than suspending their entire account and blocking them from using all applications that use signon.

## Proposal

The proposed solution is that signon handles the 'signin' permission during the oauth handshake and applications cannot circumvent this.  This means that the existing signon UI represents the truth of the situation and all applications a user has access to will be listed in their dashboard.  To cater for those applications that do want to allow all users to access them signon will provide bulk permission granting and default permission granting functionality.

* Signon MUST check for 'signin' permission during the oauth handshake with an application and reject users that do not have this permission.
* Signon MUST allow a super admin to grant permissions to all users in one go.
* Signon SHOULD allow super admins to mark permissions for an application as 'default' meaning it is added to all new users.
* gds-sso SHOULD deprecate `require_signin_permission!`.
* applications using signon SHOULD be audited to make sure they will continue to function after these changes are made
* applications using signon SHOULD be audited to collect the set of default permissions that should be created and bulk granted to all existing users

