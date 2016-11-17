## Problem

Apps and gems on GOV.UK have history followed different naming schemes. Recently we've established a pattern we're quite happy with, but we've never written that down.

This RFC is an attempt to write down the current conventions.

## Naming applications

Firstly, the&nbsp;[service manual has good guidance on naming things](https://www.gov.uk/service-manual/design/naming-your-service).

The most important rules:

- The name should be self-descriptive. No&nbsp;branding or puns (like Rummager, Needotron and Maslow)&nbsp;
- Use&nbsp; **dashes** &nbsp;for the URL and GitHub repo

**Publishing applications**

Applications that publish things are named **x-publisher**.&nbsp;

Good:

- specialist-publisher
- manuals-publisher

Not so good:

- publisher (too generic)
- contacts-admin (could be contacts-publisher)

**Frontend applications**

Applications that render content to end users on GOV.UK are named **x-frontend**

Good:

- government-frontend
- email-alert-frontend

Not so good:

- collections (could be collections-frontend)
- frontend (too generic)

**APIs**

.&nbsp;

Good:

- publishing-api
- email-alert-api
- router-api

Not so good:

- rummager (should be search-api)

**Admin applications**

Applications that "manage" things can be called **x-manager&nbsp;** or **x-admin** or **thing-doer.**

Good:

- search-admin
- local-links-manager
- content-tagger

No so good:

- signonotron2000
- maslow (needs-manager)

## Naming gems

- Use the official [Rubygems naming convention](http://guides.rubygems.org/name-your-gem/) - use underscores for multiple words.
- Use `govuk_` prefix if the gem is only interesting to projects within GOV.UK

Good:

- govuk\_sidekiq
- govuk\_content\_models
- govuk\_admin\_template
- vcloud-edge\_gateway  
  

Not so good:

- slimmer
- plek
- gds-sso (should be gds\_sso, or govuk\_sso)

