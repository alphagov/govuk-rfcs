# Rationalise our CDN config, and move away from VCL on Fastly

## Summary

- Where possible, relocate logic from the CDN layer to other parts of the stack
- Migrate our Fastly VCL to Compute@Edge
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

Fastly are recommending the use of [Compute@Edge](https://www.fastly.com/products/edge-compute) for future development on their platform. Using Compute@Edge would allow us to express our CDN logic in a programming language, using an SDK provided by Fastly, instead of having to grapple with VCL. This could make it easier to maintain the functionality that can't be relocated to other parts of the stack, as well as allowing us to set up integration tests for our CDN logic.

Across GDS we are standardising on infrastructure as code, and the use of Terraform to describe this infrastructure. Our Fastly service configuration has so far avoided this treatment, and is still deployed using custom Ruby code. We should address this by replacing our [handwritten Ruby scripts](https://github.com/alphagov/govuk-cdn-config/tree/main/lib) in [govuk-cdn-config](https://github.com/alphagov/govuk-cdn-config) with Terraform.

## Proposal

### Where possible, relocate logic from the CDN layer to other parts of the stack

Please see the [appendix](rfc-163/relocating-logic-from-cdn.md) for specific examples of what functionality we are proposing to move, and where we are proposing to move it to. Note however that this is not an exhaustive list, and is subject to change; the main point is that we want to move as much functionality out of the CDN as possible, to make it easier to maintain.

### Migrate our Fastly VCL to Compute@Edge

Compute@Edge is Fastly's edge compute product, and their recommended approach for developing services moving forwards.

From our perspective, its primary benefit is that it is much simpler to work with than VCL. The [migration guide](https://developer.fastly.com/learning/compute/migrate/) in the developer docs provide some motivating examples.

It [officially supports Rust, JavaScript and Go](https://developer.fastly.com/learning/compute/#choose-a-language-to-use), though community-supported SDKs are available for some other languages. At time of writing, only the Rust SDK is currently feature-complete (though we may not need any of the features that are missing from the JS/Go SDKs).

It also includes a [local testing server](https://developer.fastly.com/learning/compute/testing/#running-a-local-testing-server), which we could use to add continuous integration to our CDN config.

An introduction to the full feature set of Compute@Edge is out of scope of this RFC, but the below sequence diagram shows the path a request makes through a Compute@Edge service. Note that:

- A single customisation point is exposed to us: the `fetch` event, for which we can provide a handler in the language of our choice
- It's our responsibility to construct a response for the end user, by making one or more requests to the backend(s) of our choice, or by responding with a hard-coded template, whichever is appropriate.

![Sequence diagram showing a request being handled on Fastly Compute@Edge](rfc-163/Compute%40Edge%20sequence%20diagram.png)

The below sequence diagram illustrates how backend failover works on Compute@Edge. Again, note that it's our own code that performs the failover.

![Sequence diagram showing backend failover on Fastly Compute@Edge](rfc-163/Compute%40Edge%20backend%20failover.png)

#### Known limitations

Compute@Edge has a couple of known limitations that _may_ affect this work, depending on how much we care about these features:

> Compute@Edge services currently offer a fetch API that performs a backend fetch through the Fastly edge cache, and stores cacheable responses. There is no way to adjust cache rules for objects received from a backend before they are inserted into the cache within a Compute@Edge service. As a result, if you need to process received objects before caching them, or to set custom cache TTLs, a solution is to place a VCL service in a chain with a Compute@Edge one
>
> -- <cite>https://developer.fastly.com/learning/concepts/service-chaining/#computeedge-to-vcl-chaining</cite>

This means that it's currently not possible to implement all of the code from our `vcl_fetch` subroutine within a Compute@Edge service, including e.g. [this code](https://github.com/alphagov/govuk-cdn-config/blob/b0f104094c34c9b72c311a7aae2f04603364a1f1/vcl_templates/www.vcl.erb#L527-533) which marks a response as uncacheable if the `GOVUK-Account-Session` or `GOVUK-Account-End-Session` headers are set.

This code was introduced in https://github.com/alphagov/govuk-cdn-config/pull/357, and is defence-in-depth to catch the case where appropriate caching headers were not set by origin (e.g. `Vary: GOVUK-Account-Session` or `Cache-Control: no-store`).

Fastly have plans to address this limitation in the future, but in the meantime a workaround is to ["chain" a VCL service behind our Compute@Edge one](https://developer.fastly.com/learning/concepts/service-chaining/#computeedge-to-vcl-chaining). If we wish to retain this defence-in-depth functionality, this is how we'll need to implement it.

---

> Currently, Compute@Edge does not support shielding, making service chaining a useful mechanism for adding shielding to C@E services
>
> -- <cite>https://developer.fastly.com/learning/concepts/service-chaining/#chaining-with-shielding-in-computeedge</cite>

We're currently using shielding on `gov.uk/alerts`, so we would need to make use of service chaining to allow this to continue working when we migrate the rest of our logic to Compute@Edge.

### Standardise on Terraform for CDN configuration

The [custom Ruby scripts](https://github.com/alphagov/govuk-cdn-config/tree/main/lib) in [govuk-cdn-config](https://github.com/alphagov/govuk-cdn-config) should be replaced with Terraform project(s).

Compute@Edge projects require a build step in which they are compiled to a WebAssembly binary, before they can be deployed. We should commit this compiled binary to the repository that contains the Terraform code, most likely in an automated way via GitHub Actions, to ensure that our Terraform code is always in a deployable state (regardless of the state of the Compute@Edge code).
