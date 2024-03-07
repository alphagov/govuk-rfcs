---
status: accepted
implementation: done
status_last_reviewed: 2024-03-06
---

# 12 Factor Rails apps

## Problem

Our applications at the moment are more tightly coupled to the infrastructure than is necessary or good. This is going to make transitioning to a containerised setup harder.

## Proposal

This is therefore a proposal for how we should configure our Rails apps to use ideas from [The Twelve-Factor App](http://12factor.net/) to reduce this coupling. This details how Rails apps should behave because most of our apps are Rails, but these proposals can easily be applied to apps using other technologies.

### Configuration

Any config details that are specific to the deployment environment should be passed to the app using environment variables. This includes any credentials, locations of database servers etc. More details - [http://12factor.net/config](http://12factor.net/config)

Many of the default generated Rails config files include code to read these values from the environment in production (eg [secrets.yml](https://github.com/rails/rails/blob/4-2-stable/railties/lib/rails/generators/rails/app/templates/config/secrets.yml)). We should use these environment variable names where they exist.

These environment variables will be set by whatever mechanism is responsible for starting the app. At present, this is handled by the `govuk_setenv` script that reads environment variables from files managed by puppet. In future this mechanism may change, but the important point is that the applications themselves won't need to be updated to reflect this change, they'll continue to read the same environment variables.

### Logging

Applications should not deal with opening logfiles etc. Instead they should log to `STDOUT`, and `STDERR`. The OS should deal with capturing these streams and storing them as appropriate. Details - [http://12factor.net/logs](http://12factor.net/logs)

- Anything sent to `STDOUT` MUST be JSON lines suitable for use in logstash
- Apps MAY send additional log lines to `STDOUT` providing they are JSON formatted.

I've created an example app, and configured it to log as described - [https://github.com/alext/twelve-factor-rails/pull/1](https://github.com/alext/twelve-factor-rails/pull/1)

### Asset serving

Twelve-factor recommends that:

> "The twelve-factor app is completely self-contained and does not rely on runtime injection of a webserver into the execution environment to create a web-facing service." - [reference](http://12factor.net/port-binding)

This is at odds with the way we currently serve static assets (nginx is configured to serve everything from the public directory). Some thought needs to be given as to whether this is an acceptable deviation for the efficiency benefits.

The alternative would be to have these assets served by the application process using some rack middleware.  This has some efficiency implications because it will use the app workers to serve static files, but due to the cacheability of these files, this can be mitigated by setting appropriate `Cache-Control` headers.

This RFC proposes that:

- apps MUST serve their own assets. They MUST NOT assume the presence of a web server that will serve anything from the public directory.
- apps MAY use a Sendfile mechanism to offload the serving of files **if and only if** the request includes an `X-Sendfile-Type` header (Rails already provides this feature via the `Rack::Sendfile` middleware which is included by default)
- apps SHOULD set appropriate `Cache-Control` headers for the assets they serve.

### Dependencies

A twelve-factor app should "Explicitly declare and isolate dependencies" ([http://12factor.net/dependencies](http://12factor.net/dependencies)). Rails apps mostly have this covered through the use of Bundler and Gemfiles.

One area that's not so well covered is any non-gem dependencies provided by the OS. This includes things like external programs (imagemagick, tika etc...), and any libraries required by gems with native extensions (eg libxml), and the compilers necessary to build them. This also includes the ruby interpreter itself (currently specified by the .ruby-version file, but provided by the OS). There's no obvious way to resolve this with our current infrastructure, we therefore recommend that a decision on how to resolve this is deferred until we migrate to a containerised setup.

### Separate the build and release stages

Our current deploy process doesn't map onto the process described by twelve-factor ([http://12factor.net/build-release-run](http://12factor.net/build-release-run)).

We're currently using a Capistrano deploy style which does most of the building on the app servers at deploy time. Given ruby is a non-compiled language, there isn't much building to do - it mostly comes down to building assets, and bundling.

We should investigate how to build a single artefact that can be simply deployed and run on servers taking all the necessary config from the environment.  This is probably another point that should be deferred until we are transitioning to a containerised setup.

## 12-factor principles

For reference these are all the twelve-factor principles:

[I. Codebase](http://12factor.net/codebase) - One codebase tracked in revision control, many deploys

We already do this.

[II. Dependencies](http://12factor.net/dependencies) - Explicitly declare and isolate dependencies

See above...

[III. Config](http://12factor.net/config) - Store config in the environment

See above...

[IV. Backing Services](http://12factor.net/backing-services) - Treat backing services as attached resources

We already do this (when combined with the Config approach above).

[V. Build, release, run](http://12factor.net/build-release-run) - Strictly separate build and run stages

See above...

[VI. Processes](http://12factor.net/processes) - Execute the app as one or more stateless processes

We already do this

[VII. Port binding](http://12factor.net/port-binding) - Export services via port binding

We already do this

[VIII. Concurrency](http://12factor.net/concurrency) - Scale out via the process model

We already do this

[IX. Disposability](http://12factor.net/disposability) - Maximize robustness with fast startup and graceful shutdown

Unicorn gives us this feature.

[X. Dev/prod parity](http://12factor.net/dev-prod-parity) - Keep development, staging, and production as similar as possible

We already do this

[XI. Logs](http://12factor.net/logs) - Treat logs as event streams

See above...

[XII. Admin processes](http://12factor.net/admin-processes) - Run admin/management tasks as one-off processes

Rake tasks give us this.
