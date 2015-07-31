# Problem

Our applications at the moment are more tightly coupled to the infrastructure that is necessary or good. This is going to make transitioning to a containerised setup harder.

# Proposal

This is therefore a proposal for how we should configure our Rails apps to use ideas from [The Twelve-Factor App](http://12factor.net/) to reduce this coupling. This details how Rails apps should behave because most of our apps are Rails, but these proposals can easily be applied to apps using other technologies.

## Configuration

Any config details that are specific to the deployment environment should be&nbsp;passed to the app using environment variables. This includes any credentials,&nbsp;locations of database servers etc. More details - [http://12factor.net/config](http://12factor.net/config)

Many of the default generated Rails config files include code to read these&nbsp;values from the environment in production (eg [secrets.yml](https://github.com/rails/rails/blob/4-2-stable/railties/lib/rails/generators/rails/app/templates/config/secrets.yml)).&nbsp;We should use these environment variable names where they exist.

These environment variables will be set by whatever mechanism is responsible for&nbsp;starting the app. At present, this is handled by the `govuk_setenv` script that&nbsp;reads environment variables from files managed by puppet. In future this&nbsp;mechanism may change, but the important point is that the applications&nbsp;themselves won't need to be updated to reflect this change, they'll continue to&nbsp;read the same environment variables.

## Logging

Applications should not deal with opening logfiles etc. Instead they should log  
to STDOUT, and STDERR. The OS should deal with capturing these streams and  
storing them as appropriate. Details - [http://12factor.net/logs](http://12factor.net/logs)

General logging SHOULD be sent to STDERR.

Request logs SHOULD be sent to STDOUT as JSON lines suitable for logstash.

Apps MAY send additional log lines to STDOUT providing they are JSON formatted.

Apps MUST NOT send any non-JSON logging to STDOUT.

TODO: Document how to configure Rails to follow the above.

### Known issues

&nbsp;

- omniauth logs things to STDOUT by default. gds-sso will need to be updated to&nbsp;configure it to log elsewhere.  
Alternatively it may be easier and safer to redirect STDOUT to STDERR, so that only known things will log to the real STDOUT&nbsp;

&nbsp;

&nbsp;

&nbsp;

