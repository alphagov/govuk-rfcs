# Migrate from VCL-based CDN config to edge compute on Fastly & AWS

## Summary

We currently configure our CDN (Fastly) using a domain-specific language called [VCL](https://developer.fastly.com/learning/vcl/using/).

By moving to [edge computing](https://en.wikipedia.org/wiki/Edge_computing) instead, we could potentially simplify our configuration, while making it easier to port it to other CDNs (to support CDN failover).

## Problems

- Currently our Fastly services and our CloudFront distributions are configured in different ways, within different codebases:
  - Our Fastly services are configured using [VCL (varnish cache language)](https://developer.fastly.com/learning/vcl/using/), in [`govuk-cdn-config`](https://github.com/alphagov/govuk-cdn-config).
  - Our CloudFront failover distribution is configured and deployed using Terraform, in [the `infra-mirror-bucket` project in `govuk-aws`](https://github.com/alphagov/govuk-aws/tree/main/terraform/projects/infra-mirror-bucket).
- Currently only our Fastly configuration is feature-complete; if Fastly goes down then we failover to a CloudFront distribution that is only configured to serve a static mirror of GOV.UK.
  - Platform Reliability have begun work on a new CloudFront distribution that's able to serve content from origin by calling into a load balancer in front of our `cache` class nodes, but this new setup [doesn't have feature parity](https://docs.google.com/document/d/17_dfWvKNmqyLX1h_PPY6_Cd6IggrrSsP-Peh2De6JQk/edit) with our existing VCL-based Fastly service, and we have no plans to implement full feature parity with Fastly (as that's the purpose of this RFC).
  - This lack of feature parity presents us with several issues:
    - Lack of clarity or confidence around what works in Cloudfront (e.g. developers have to be aware of this when building things, SMT need to be reminded of impact failover will have, we may be more hesitant in triggering the failover, etc.)
    - Complexities also introduced downstream (e.g. if we failover and A/B testing stops working, data analysts now need to scrub out the failover period in their analysis)
    - We're less likely to drill the failover in Production to ensure it works (as it will cause a somewhat degraded experience)
    - It restricts our ability to consider a multi CDN strategy where traffic is split between two CDNs simultaneously 

## Proposal

Move from VCL-based CDN config to edge compute on both Fastly ([Compute@Edge](https://www.fastly.com/products/edge-compute)) and AWS ([Lambda@Edge](https://aws.amazon.com/lambda/edge/)).

Benefits:

- Allows us to deploy the same CDN config to multiple CDNs
  - This makes it easier for us to build a failover solution that has feature parity with the primary CDN
- Using a programming language for CDN config (as opposed to a DSL) allows us to test it locally, as discussed later in this RFC

## Background

### VCL (Fastly)

This is the "traditional" way to configure Fastly services (see [high-level overview](https://developer.fastly.com/learning/vcl/using/)).

[Our VCL](https://github.com/alphagov/govuk-cdn-config/blob/main/vcl_templates/www.vcl.erb) currently overrides the `RECV`, `FETCH`, `DELIVER` and `ERROR` subroutines, and handles a lot of things including (non-exhaustive):

- IP allowlisting
- Requiring HTTP basic auth on integration
- A/B testing, including Replatforming's traffic split experiment logic
- [JA3](https://github.com/salesforce/ja3) fingerprinting and denylisting
- Enforcing SSL
- Setting feature flag headers (e.g. `Govuk-Use-Recommended-Related-Links`, which enables recommended links in Whitehall)
- Serving from static mirrors on HTTP 5xx
- Requiring authentication for cache purge requests
- Redirect for `/.well-known/security`
- Serving an HTTP 404 for `autodiscover.xml`
- Sorting query params and stripping UTM params to improve cache hit rate
- Setting `GOVUK-Request-Id`
- Brotli compression
- Preventing responses from being cached if they manipulate the user session (i.e. if `GOVUK-Account-Session` or `GOVUK-Account-End-Session` are set)
- Stripping cookies in some cases
- Rendering some custom error pages

We also make use of some features in the Fastly UI, which are not currently available within VCL (or indeed Compute@Edge code - see [Known limitations](#known-limitations)):

- Enabling [shielding](https://docs.fastly.com/en/guides/shielding) for paths beginning with `/alerts`
- Setting up logging to S3 and Splunk

### Compute@Edge (Fastly)

[Compute@Edge](https://www.fastly.com/products/edge-compute) (C@E) is Fastly's serverless edge compute product.

- Built around WebAssembly, supports [several languages](https://developer.fastly.com/learning/compute/#choose-a-language-to-use)
- C@E services are built locally into WebAssembly blobs, and can be deployed using the Fastly CLI
- C@E services are totally independent from VCL-based ones, and you cannot mix VCL with edge compute (other than with [service chaining](https://developer.fastly.com/learning/concepts/service-chaining/), where one service has another as its backend)
- Includes APIs to make dealing with requests or interacting with the backend easier

The below sequence diagram shows the path a request makes through a Compute@Edge service. Note that a single customisation point is exposed to us, and it's our responsibility to make one or more requests to the backend(s) of our choice, if appropriate.

![Sequence diagram showing a request being handled on Fastly Compute@Edge](rfc-157/Compute%40Edge%20sequence%20diagram.png)

The below sequence diagram illustrates how backend failover works on Compute@Edge. Again, note that it's our own code that performs the failover.

![Sequence diagram showing backend failover on Fastly Compute@Edge](rfc-157/Compute%40Edge%20backend%20failover.png)

#### Known limitations

> Compute@Edge services currently offer a fetch API that performs a backend fetch through the Fastly edge cache, and stores cacheable responses. There is no way to adjust cache rules for objects received from a backend before they are inserted into the cache within a Compute@Edge service. As a result, if you need to process received objects before caching them, or to set custom cache TTLs, a solution is to place a VCL service in a chain with a Compute@Edge one
>
> -- <cite>https://developer.fastly.com/learning/concepts/service-chaining/#computeedge-to-vcl-chaining</cite>

This means that it's currently not possible to implement all of the code from our `vcl_fetch` subroutine within a Compute@Edge service, including e.g. [this code](https://github.com/alphagov/govuk-cdn-config/blob/b0f104094c34c9b72c311a7aae2f04603364a1f1/vcl_templates/www.vcl.erb#L527-533) which marks a response as uncacheable if the `GOVUK-Account-Session` or `GOVUK-Account-End-Session` are set.

Fastly have plans to address this limitation in the future, but in the meantime a workaround is to ["chain" a VCL service behind our Compute@Edge one](https://developer.fastly.com/learning/concepts/service-chaining/#computeedge-to-vcl-chaining).

> Currently, Compute@Edge does not support shielding, making service chaining a useful mechanism for adding shielding to C@E services
>
> -- <cite>https://developer.fastly.com/learning/concepts/service-chaining/#chaining-with-shielding-in-computeedge</cite>

We're currently using shielding on `gov.uk/alerts`, so we would need to make use of service chaining to allow this to continue working when we migrate the rest of our logic to Compute@Edge.

### Lambda@Edge (AWS)

[Lambda@Edge](https://aws.amazon.com/lambda/edge/) is a feature of CloudFront that allows us to use Lambda functions to customise the behaviour of a CloudFront distribution.

- Only supports JavaScript (through Node) or Python
- Can be deployed using Terraform
- Does not include any APIs (other than those provided by Node itself), but the format of messages that are passed to/from the handler is specified

The below sequence diagram shows the path a request makes through a CloudFront distribution that makes use of Lambda@Edge.

![Sequence diagram showing a request being handled on AWS Lambda@Edge](rfc-157/Lambda%40Edge%20sequence%20diagram.png)

4 customisation points are exposed to us:

- Viewer request handler, which allows us to customise the request received from the viewer before cache key computation and cache lookup occur. This roughly corresponds to the `RECV` VCL subroutine.
- Origin request handler, which allows us to modify the request that is forwarded to origin in the event of a cache miss. This roughly corresponds to the `MISS` VCL subroutine.
- Origin response handler, which allows us to modify the response received from origin before it is cached. This roughly corresponds to the `FETCH` VCL subroutine.
- Viewer response handler, which allows us to modify the response that is sent to the user (whether that response was cached or not). This roughly corresponds to the `DELIVER` VCL subroutine.

Origin request/response handlers allow us to do things that Compute@Edge does not yet support (but that are available in VCL), such as modifying a backend request after the cache key has been computed, or modifying a backend response before it gets cached.

Lambda@Edge origin request handlers can perform [dynamic origin selection](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html#lambda-examples-content-based-routing-examples), but unlike Fastly/C@E, origin failover on CloudFront is handled by CloudFront itself (not our Lambda@Edge code), through the use of [Origin Groups](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/high_availability_origin_failover.html#concept_origin_groups.lambda):

![Origin failover with Lambda@Edge](rfc-157/Lambda%40Edge%20with%20origin%20groups.png)

## Choice of language

TypeScript (or JavaScript if there's popular outcry against TS).

Compute@Edge supports any [WASI](https://github.com/WebAssembly/WASI)-supporting language, and provides official SDKs for Rust, JavaScript, Go and AssemblyScript. The JavaScript SDK also includes [TypeScript definitions](https://github.com/fastly/js-compute-runtime/tree/main/types), and the default JavaScript project generated by the CLI includes Webpack (allowing us to use JavaScript modules).

Lambda@Edge currently only supports two platforms: JavaScript (through Node.js), and Python. WASI-supporting languages like Rust _can_ be made to work on Lambda, but [it's pretty gnarly](https://markentier.tech/posts/2021/01/rust-wasm-on-aws-lambda-edge/) and maybe not the best idea. Lambda@Edge also has [(third-party) TypeScript definitions](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/aws-lambda) available. Unlike Compute@Edge, there is no CLI for Lambda@Edge and no template projects; if we want to use JS modules we must bring our own JS bundler.

As the only common language shared between the two platforms, JavaScript (or TypeScript) seems like the obvious choice.

The primary benefit TypeScript provides over JavaScript is type safety, including enforcement of `readonly` properties. This will be particularly useful on the Lambda@Edge side because parts of the payload we receive from CloudFront are intended to be read-only. TypeScript enforces these invariants (potentially preventing us from introducing bugs), whereas JavaScript doesn't know how to.

If folks have a strong aversion to TypeScript, JavaScript would also be a good option.

## Architecture

I propose that we build a three-layer architecture, with:

- A platform-agnostic wrapper API to abstract away differences between the platform-specific types (e.g. `Request` and `Response`)
- Platform-agnostic request and response handlers (corresponding to Lambda@Edge's viewer request and viewer response handlers concepts respectively), where the majority of the code lives, e.g. (pseudocode)
  ```typescript
  // Takes the request from the client
  // Returns either a request to be sent to the backend,
  // or a response to be sent to the client
  function handle_request(request: Request): Request | Response

  // Takes the response returned from either the request handler or the backend
  // Returns the response to be sent to the client
  function handle_response(response: Response): Response
  ```
- Platform-specific entrypoints for Compute@Edge and Lambda@Edge, which call into the platform-agnostic code, e.g. (pseudocode)
  ```typescript
  // Compute@Edge entrypoint:
  function perform_backend_fetch(request: Request): Response; // Provided by Fastly SDK

  function fastly_entrypoint(request: Request): Response {
    const request_or_response = handle_request(request)
    const response = (request_or_response instanceof Request) ?
      perform_backend_fetch(request_or_response) :
      request_or_response
    return handle_response(response)
  }

  // Lambda@Edge viewer request handler entrypoint:
  function viewer_request_handler(request: Request): Request | Response {
    return handle_request(request)
  }

  // Lambda@Edge viewer response handler entrypoint:
  function viewer_response_handler(response: Response): Response {
    return handle_response(response)
  }
  ```

On the Fastly side, we will also need:

- A VCL service _before_ our Compute@Edge one so that we can continue to use shielding on the `/alerts` route (and potentially roll out shielding for all of GOV.UK), and
- Another VCL service _after_ our Compute@Edge one so that we can manipulate backend responses before they hit the cache and/or control which backend responses are cacheable.

In other words, we will need a VCL -> Compute@Edge -> VCL "sandwich". Such an approach is explicitly mentioned in the [Fastly docs](https://developer.fastly.com/learning/concepts/service-chaining/#chaining-more-than-two-services) as the only use case where a chain of more than 2 services is recommended.

On the Lambda@Edge side, manipulation of the backend response before it hits the cache could be achieved by building an origin response handler. This would create code duplication between Lambda@Edge and the second VCL service in the "sandwich" (because we're implementing the same behaviour in both VCL and TypeScript). When Compute@Edge gains support for controlling caching around backend responses, we can refactor this to remove the duplication.

Backend failover will be performed from within the Fastly-specific entrypoint on the Fastly side, and through a CloudFront origin group configured using Terraform on the CloudFront side.

## Testing

- The platform-agnostic layer should be unit tested in isolation using a JavaScript unit testing tool such as Jasmine, potentially mocking the `Request` and `Response` classes.
- With regards to integration testing:
  - Although Compute@Edge doesn't include any testing capabilities out of the box, it is possible to set up local integration testing using the development server provided by the Fastly CLI:
    - Spin up an HTTP server that records each request it receives, and returns a dummy response, using Node's [built-in HTTP server library](https://nodejs.org/api/http.html#httpcreateserveroptions-requestlistener)
    - Start the Compute@Edge development server, with the aforementioned dummy server as its backend
    - Send requests to the Compute@Edge development server, and verify the behaviour by inspecting the requests that were forwarded to the dummy backend
    - This testing approach has already been successfully [spiked](https://github.com/alphagov/govuk-cdn-config/tree/5fb3610236fa655ff3f5c9bf70d26166e8d15f2a/compute%40edge) in `govuk-cdn-config`
  - Lambda@Edge is more difficult to integration test because no development server is provided. We could unit test the request and response handlers in isolation, but in order to conduct a real integration test we would have to deploy the handlers to integration, and then perhaps test them using Smokey or something similar.

## Deployment

Currently:

- Our VCL config lives in `govuk-cdn-config`, and is deployed via a custom Ruby script which calls into the Fastly API.
- Our existing AWS Lambda functions live in `govuk-aws`, and are deployed using Terraform.

I propose that:

- Both the Compute@Edge and Lambda@Edge code should live in `govuk-cdn-config`.
- We should use the [Fastly Terraform provider](https://registry.terraform.io/providers/fastly/fastly/latest/docs) (or possibly the Fastly CLI, if it supports all the features we need) to:
  - Build the new Compute@Edge service into a WASI bundle and deploy it to Fastly
  - Configure the two VCL services in the "sandwich"
    - These will both be architected as entirely new services, i.e. [`www.vcl.erb`](https://github.com/alphagov/govuk-cdn-config/blob/main/vcl_templates/www.vcl.erb) will remain untouched during the migration process (other than perhaps to add A/B testing logic for the new services), and then removed when the migration is complete.
- A GitHub Actions workflow should be added to `govuk-cdn-config` that, on push to `main`, builds (using e.g. Webpack or esbuild) and packages (e.g. as a series of ZIP archives) the Lambda@Edge code, and commits the built packages to `govuk-aws`.
  - Committing built Lambda packages to `govuk-aws` is already an [established precedent](https://github.com/alphagov/govuk-aws/blob/main/terraform/lambda/DownloadLogsAnalytics/download_logs_analytics.zip), and allows us to ensure that the Terraform project is always in a deployable state
- A new Terraform project should be created in `govuk-aws` which:
  - Creates a new CloudFront distribution, creates the appropriate Lambda functions, and attaches them to the distribution (building upon [this spike](https://github.com/alphagov/govuk-aws/tree/c47b0a265a9f5c6de0b117fe3f48d6c4a56889fb/terraform/lambda/CloudfrontHandlers) in `govuk-aws`, though n.b. I am proposing that the Lambda@Edge code itself should live in `govuk-cdn-config`)

When we are ready to test the new CDN config with live traffic, we could potentially set up A/B testing by adding the new Compute@Edge service and the new CloudFront distribution as (additional) backends of the existing VCL-based service.

## Ownership & roadmap

Platform Reliability would own most of this work.

This project can be divided into a number of stages:

1. Development
    - We will develop & deploy the new Fastly services and the new CloudFront distribution separately from our existing CDN service.
    - Both the new Compute@Edge service and the Lambda@Edge handlers should be built together, so that we don't end up painting ourselves into a corner with an architecture that's only suitable for one service.
    - Both services must have access controls during development (I propose an IP allowlist restricting access to the office & VPN).
    - The new CloudFront distribution must be added to origin's IP allowlist, so that it is able to make requests to origin. The new Compute@Edge service (or rather, the VCL service behind it in the "sandwich") will [already be covered](https://docs.publishing.service.gov.uk/manual/cdn.html#fastly39s-ip-ranges-and-our-access-controls-on-origin-servers) by our existing allowlist.
2. A/B testing with live traffic by adding the new Compute@Edge service and CloudFront distribution as backends to the existing VCL-based service, and passing a percentage of traffic directly to each
3. Promotion of the new Fastly config
    - Update our DNS records for GOV.UK to point to the new Compute@Edge service (or rather, the VCL service at the front of the "sandwich").
4. Retirement of the (old) VCL service

## Risks

- We will need to maintain 2 separate CDN configurations during the migration process, however long that may be.
- To date we've only conducted very brief spikes into Compute@Edge and Lambda@Edge; we may encounter other limitations of the two platforms that we don't know about yet, or more differences between the two platforms that are difficult to abstract away.
