## Problem

We discovered that the EFG application had 2 Devise configuration files in production. This is because it uses alphagov-deployment to copy configuration files into place during deployment. Each of these Devise configuration files had a `secret_key` value (one was in the public repo and used for development, the other was from alphagov-deployment). By luck, we were using the value of the `secret_key` which was not public (this was due to the order that Rails loaded the initializers).

If we had been using the public value of the secret key this would have been a security incident for GOV.UK which may have resulted in all 3000 EFG users having their passwords reset.

## Proposal

"Secrets" are defined as any values which would result in a security incident if disclosed. These can include, but are not limited to, cookie encryption seeds and password encryption seeds.

### Configuration

This is a reinforcement of [RFC 26: 12-Factor Rails Apps](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+26%3A+12-Factor+Rails+Apps). Applications must retrieve their secrets from the environment, not from files.

### Default values for secrets

&nbsp;Application code must not contain default values for secrets. For example:

- 
```
Bad: GovernmentApp::Application.config.secret_token = 'ohqu1iejohTh9oophieFah9UeDik0neixizeeVooSuush1xu'
```
- 
```
Bad: GovernmentApp::Application.config.secret_token = ENV['SECRET_TOKEN'] || 'ohqu1iejohTh9oophieFah9UeDik0neixizeeVooSuush1xu'
```
- 
```
Good: GovernmentApp::Application.config.secret_token = ENV['SECRET_TOKEN']
```

### Maintaining dev-prod parity for secret configuration

Secrets must be configured in the environment for development as well as in production. An acceptable alternative to using environment variables in development is to use the [`config/secrets.yml` functionality available in Rails 4.1 and later](http://edgeguides.rubyonrails.org/4_1_release_notes.html#config-secrets-yml):

```
development: secret_key_base: development_example_secret_keyproduction: secret_key_base: ENV['SECRET_KEY_BASE']
```

This maintains close enough configuration between development and production without needing environment variables in every environment.

### Default behaviour when secrets are not present

Applications must fail to start if a piece of secret configuration is either not present in the environment or is set to an empty string. For example:

```
if ENV['DEVISE_SECRET_KEY'].blank? or ENV['DEVISE_PEPPER'].blank? raise 'Required Devise secrets are not present in the environment'end
```

