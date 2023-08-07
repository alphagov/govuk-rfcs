# Simplify our CDN config, and standardise on Terraform for deployment

## Summary

- Where possible, relocate logic from the CDN layer to other parts of the stack
- Standardise on Terraform for CDN configuration

## Problems

We currently configure our Fastly services using [Fastly's custom fork](https://developer.fastly.com/learning/vcl/using/) of the VCL domain-specific language, within [govuk-cdn-config](https://github.com/alphagov/govuk-cdn-config). We deploy this code using [custom Ruby scripts](https://github.com/alphagov/govuk-cdn-config/tree/main/lib).

We also have a work-in-progress CloudFront distribution that we can use for failover in the event that Fastly experiences an outage. This currently lives in [the `cdn` branch of govuk-aws](https://github.com/alphagov/govuk-aws/tree/cdn/terraform/projects/infra-cloudfront), but it will be migrated to [govuk-infrastructure](https://github.com/alphagov/govuk-infrastructure) in the future.

In its current state, our CDN configuration is highly complex and does many things, making it brittle and difficult to maintain, and hampering efforts to ensure parity between the two CDNs. Its current approach to testing also leaves a lot to be desired - as we are unable to verify the behaviour of the VCL through automated tests, we instead simply [run RuboCop over the repo](https://github.com/alphagov/govuk-cdn-config/blob/5bff7b9d3b7ef51b493bb00e609fc714da2dc67a/Rakefile#L8), [verify that the VCL rendered from our ERB templates matches what we expect](https://github.com/alphagov/govuk-cdn-config/blob/5bff7b9d3b7ef51b493bb00e609fc714da2dc67a/spec/www_vcl_erb_spec.rb), and [verify that our hand-written Ruby deploy scripts work](https://github.com/alphagov/govuk-cdn-config/blob/5bff7b9d3b7ef51b493bb00e609fc714da2dc67a/spec/deploy_service_spec.rb).

The lack of feature parity between the two CDNs presents us with several issues:

- Lack of clarity or confidence around what works in Cloudfront (e.g. developers have to be aware of this when building things, SMT need to be reminded of impact failover will have, we may be more hesitant in triggering the failover, etc.)
- Complexities also introduced downstream (e.g. if we failover and A/B testing stops working, data analysts now need to scrub out the failover period in their analysis)
- We're less likely to drill the failover in Production to ensure it works (as it will cause a somewhat degraded experience)
- It restricts our ability to consider a multi CDN strategy where traffic is split between two CDNs simultaneously 

A number of the things that we currently handle at the CDN level might perhaps be better handled at other places in the stack. By moving things out of the CDN layer, we minimise the amount of duplicated effort in maintaining equivalent but different configurations for each CDN.

Fastly are recommending the use of [Compute@Edge](https://www.fastly.com/products/edge-compute) for future development on their platform. Using Compute@Edge would allow us to express our CDN logic in a programming language, using an SDK provided by Fastly, instead of having to grapple with VCL. This could make it easier to maintain the functionality that can't be relocated to other parts of the stack, as well as allowing us to set up integration tests for our CDN logic. We are not (yet) proposing migrating to Compute@Edge, but if and when we decide to do so, it will be easier if there is less functionality to migrate.

Across GDS we are standardising on infrastructure as code, and the use of Terraform to describe this infrastructure. Our Fastly service configuration has so far avoided this treatment, and is still deployed using custom Ruby code. We should address this by replacing our [handwritten Ruby scripts](https://github.com/alphagov/govuk-cdn-config/tree/main/lib) in [govuk-cdn-config](https://github.com/alphagov/govuk-cdn-config) with Terraform.

## Proposal

### Where possible, relocate logic from the CDN layer to other parts of the stack

Please see the [appendix](rfc-163/relocating-logic-from-cdn.md) for specific examples of what functionality we are proposing to move, and where we are proposing to move it to. Note however that this is not an exhaustive list, and is subject to change; the main point is that we want to move as much functionality out of the CDN as possible, to make it easier to maintain.

### Standardise on Terraform for CDN configuration

The [custom Ruby scripts](https://github.com/alphagov/govuk-cdn-config/tree/main/lib) in [govuk-cdn-config](https://github.com/alphagov/govuk-cdn-config) should be replaced with Terraform project(s). Note that the data.gov.uk Fastly services are [already deployed with Terraform](https://github.com/alphagov/govuk-aws/tree/main/terraform/projects/fastly-datagovuk): this provides a good preview of the direction we want to take the GOV.UK Fastly services in.

## [Appendix: Proposal for relocating logic from the CDN layer to other parts of the stack](rfc-163/relocating-logic-from-cdn.md)
