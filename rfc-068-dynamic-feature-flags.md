## Problem

At the moment whenever we want to hide a functionality behind a feature flag (which normally involves setting up an Environment variable) we have to issue a PR against govuk-puppet, e.g:&nbsp;[https://github.com/alphagov/govuk-puppet/pull/5514/files](https://github.com/alphagov/govuk-puppet/pull/5514/files)

This is problematic because we can't turn on/off a feature flag instantly, govuk-puppet needs a deployment slot in the calendar, and after the deploy there's still roughly a 30min wait to spread the changes around the other machines.

## Proposal

I propose that we find a different way to achieve this.

We could use Flipper ([https://github.com/jnunemaker/flipper](https://github.com/jnunemaker/flipper)) with it's own database for feature flagging, and already comes with a UI interface.

This allow us to turn on/off an feature flag instantly and we no longer depend on another deploy to have a feature turned on/off.

