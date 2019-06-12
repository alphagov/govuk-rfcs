## Problem

The current naming scheme for our different environments is confusing and does not match the standard definitions. We need to come up with a set of definitive names that avoid confusion and allow us and our publishing users to distinctly identify particular environments.

### Proposal

| Environment name | Live URL | Preview URL | Existing environment name | Existing live URL |
| ---------------- | -------- | ----------- | ------------------------- | ----------------- |
| Production       | www.gov.uk (www.publishing.service.gov.uk) | www-preview.publishing.service.gov.uk | Production | www.gov.uk |
| Staging          | www.staging.publishing.service.gov.uk | www-preview.staging.publishing.service.gov.uk | Staging | production.alphagov.co.uk |
| Integration      | www.integration.publishing.service.gov.uk | www-preview.integration.publishing.service.gov.uk | Preview | preview.alphagov.couk |

This involves reassigning some existing names for other purposes, and using some completely new names. In particular, what is currently known as the "Draft" stack becomes "Preview". This has two benefits:

- It matches what editors are expecting to do - that is, preview their content before making it live.
- It weans them off using the separate environment that we currently call "preview", allowing us to rename it to match its actual intended usage, which is for integration&nbsp;testing.

Note that the transition will not be as painful as it could be, as no editors are currently using "draft". The main re-education task will be to stop thinking of "preview" as a scratchpad that gets reset regularly, but as somewhere to actually preview content that is going to be live.

Also note that thanks to some reconfiguration that Infrastructure are doing as part of the move away from Skyscape, the domain name for all environments will change from "alphagov.co.uk" to "publishing.service.gov.uk". Since we retain control of alphagov, we will be able to redirect as appropriate.

In addition, this work will give a specific URL to the staging environment, rather than using the production domain and having to edit the hosts file.
