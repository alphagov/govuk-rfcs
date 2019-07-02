# RFC 106: Use Docker for local development

## Summary

Adopt a Docker-based approach for local development instead of the Vagrant VM.

## Problem

We currently rely on the Vagrant development VM for the day to day dev cycle.

- It has [many documented issues](https://docs.publishing.service.gov.uk/manual.html#development-vm)
- Changes to puppet often result in a broken VM, because the infrastructure team don't use it.
- We are adopting more cloud-based services into our stack, like S3 and Amazon's Elasticsearch. This means that our development environment doesn't look like production anymore, but we still need code in govuk-puppet.
- It's hard to keep updated. Running the puppet command will often error and take a long time.
- GOV.UK is moving to a containerised infrastructure (likely the [GDS Supported Platform](https://github.com/alphagov/gsp) (GSP))

## Possible approaches to local development

- An approach based on **Docker and docker-compose**. Ben Thorner has a working prototype called [govuk-docker](https://github.com/benthorner/govuk-docker) and we have the [end-to-end tests](https://github.com/alphagov/publishing-e2e-tests) running in the same. Other GDS programmes like GOV.UK Pay use this approach.
- An approach based on **GNU Guix** package manager, which Chris Baines uses via govuk-guix.
- Because they are read-only, frontend applications on GOV.UK can be **run against production** using the startup.sh --live flag.
- Developers on the GOV.UK PaaS work by developing against a **remote set of services** - we’d run many versions of GOV.UK in the cloud, which developers can use in development.
- Applications can be run locally by **installing dependencies manually**. This is what some of GOV.UK’s Linux users do.
- The RE team has been working on local development tooling called **[gsp-local](https://github.com/alphagov/gsp/blob/master/docs/gds-supported-platform/getting-started-gsp-local.md)**.

Approach | Pro | Cons
-- | -- | --
Vagrant VM | Can look like production | Resource intensive, brittle
Docker | Aligns with future hosting. Reproducible (with caveats). | Slow because on a Mac it needs a VM. Development won’t match production/CI exactly until we migrate onto a container-based platform.
Guix | Is almost feature complete (runs Signon, TLS) | Technology unknown in GOV.UK
Against production | Low setup, fast | Only works for frontend applications. Still needs local install. Limits you to testing one application at a time.
Remote dependencies | Low setup. Can match Production exactly in terms of technologies used | Expensive, no offline development
Manual install | Fast in development | Lots of setup, brittle
gsp-local | GOV.UK will move to the GSP at some point | Multiple new layers of technology, quite new

## Proposal

We'll adopt a Docker based local development environment. Docker is widely supported in the community and is most aligned with our tech strategy. In the long term we might replace it with a local environment of the GDS Supported Platform.

## Impact and follow up work

We'll commit to doing these things:

- Document how to test puppet locally using Vagrant now that the development VM is going away.
- Come up with a process of ownership so that the tooling improves over time.

Things we'll need to look out for:

- Make sure we can limit the number of dependencies we run, to avoid having the environment being too resource intensive.
- Our local development will diverge more from our production environment. This might lead to more testing on integration. We should be sure this is viable and doesn't become a blocker if lots of people are testing things at the same time.
