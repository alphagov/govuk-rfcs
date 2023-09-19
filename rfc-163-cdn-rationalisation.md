# Simplify our CDN config, and standardise on Terraform for deployment

## Summary

- Where possible, relocate logic from the CDN layer to other parts of the stack
- Standardise on Terraform for CDN configuration

## Problems

We currently configure our Fastly services using [Fastly's custom fork](https://developer.fastly.com/learning/vcl/using/) of the VCL domain-specific language, within [govuk-fastly](https://github.com/alphagov/govuk-fastly).

We also have a work-in-progress CloudFront distribution that we can use for failover in the event that Fastly experiences an outage. This is due to be merged soon in alphagov/govuk-infrastructure#929.

In its current state, our CDN configuration is highly complex and does many things, making it brittle and difficult to maintain, and hampering efforts to ensure parity between the two CDNs.

Its current approach to testing also leaves a lot to be desired. In its previous guise as `govuk-cdn-config`, we simply [ran RuboCop over the repo](https://github.com/alphagov/govuk-cdn-config/blob/5bff7b9d3b7ef51b493bb00e609fc714da2dc67a/Rakefile#L8), [verified that the VCL rendered from our ERB templates matched what we expected](https://github.com/alphagov/govuk-cdn-config/blob/5bff7b9d3b7ef51b493bb00e609fc714da2dc67a/spec/www_vcl_erb_spec.rb), and [verified that our hand-written Ruby deploy scripts work](https://github.com/alphagov/govuk-cdn-config/blob/5bff7b9d3b7ef51b493bb00e609fc714da2dc67a/spec/deploy_service_spec.rb). The new repo, `govuk-fastly`, currently lacks tests and continuous integration entirely.

The lack of feature parity between the two CDNs presents us with several issues:

- Lack of clarity or confidence around what works in Cloudfront (e.g. developers have to be aware of this when building things, SMT need to be reminded of impact failover will have, we may be more hesitant in triggering the failover, etc.)
- Complexities also introduced downstream (e.g. if we failover and A/B testing stops working, data analysts now need to scrub out the failover period in their analysis)
- We're less likely to drill the failover in Production to ensure it works (as it will cause a somewhat degraded experience)
- It restricts our ability to consider a multi CDN strategy where traffic is split between two CDNs simultaneously 

A number of the things that we currently handle at the CDN level might perhaps be better handled at other places in the stack. By moving things out of the CDN layer, we could minimise the amount of duplicated effort in maintaining equivalent but different configurations for each CDN.

Fastly have recently introduced an edge compute platform called [Compute@Edge](https://www.fastly.com/products/edge-compute). This platform would allow us to express our CDN logic in a programming language, using an SDK provided by Fastly, instead of having to grapple with VCL. This could make it easier to maintain the functionality that can't be relocated to other parts of the stack, as well as allowing us to set up integration tests for our CDN logic. We are not (yet) proposing migrating to Compute@Edge, but if and when we decide to do so, it will be easier if there is less functionality to migrate.

Across GDS we are standardising on infrastructure as code, and the use of Terraform to describe this infrastructure. We should standardise on Terraform for CDN deployment across all of our services.

## Proposal

### Where possible, relocate logic from the CDN layer to other parts of the stack

Please see the [appendix](rfc-163/relocating-logic-from-cdn.md) for specific examples of what functionality we are proposing to move, and where we are proposing to move it to. Note however that this is not an exhaustive list, and is subject to change; the main point is that we want to move as much functionality out of our CDN services as possible, to make them easier to maintain.

### Standardise on Terraform for CDN configuration

Platform Engineering have already migrated most of our Fastly services to Terraform, with the new code living in [`govuk-fastly`](https://github.com/alphagov/govuk-fastly) and [`govuk-fastly-secrets`](https://github.com/alphagov/govuk-fastly-secrets). The service domain redirect service (which handles redirecting from https://service.gov.uk to https://www.gov.uk), and the TLD redirect service (which handles redirecting from https://gov.uk to https://www.gov.uk) should also be migrated to this new repo.

The data.gov.uk Fastly services are [already deployed with Terraform](https://github.com/alphagov/govuk-aws/tree/main/terraform/projects/fastly-datagovuk) - we may want to consider migrating this code from `govuk-aws` to `govuk-fastly`, to keep all of our Fastly configuration in one place.

The Apt service should no longer be needed once all of our EC2 infrastructure has been decommissioned, and so it makes little sense to refactor or migrate this code.

## [Appendix: Proposal for relocating logic from the CDN layer to other parts of the stack](rfc-163/relocating-logic-from-cdn.md)
