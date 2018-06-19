# Retire GOV.UK CDN Logs Monitor

## Summary

This RFC proposes the retiring of the application
[GOV.UK CDN Logs Monitor][cdn-logs-repo] for the following reasons:

- We do not make use of the data it generates;
- It is a complicated tool that few GOV.UK developers understand the purpose of;
- Similarly, due to lack of knowledge we don't know if the data is accurate
  when problems occur;
- Since there is a very infrequent need to use the application there isn't
  much justification to invest in developers learning it;
- It uses a significant amount of disk space that requires maintenance.

The purpose of this RFC is to make the case that we should retire it based off
the knowledge we have. We are hoping that by circulating this suggestion
across the wider GOV.UK technical community we can identify any issues that
we haven't yet identified.

## Background

We understand that the original motivation for creating GOV.UK CDN Logs Monitor
was in response to an incident and it was intended as a means to monitor
when URLs on GOV.UK change from responding with a success (2xx) status code to a
different one.

A summary of the responsibilities of the application is as follows:

- Monitor the log files that Fastly sends directly to the box via syslog.
- Increments statsd counters for the amount of responses the Fastly is serving
  with a particular status code.
  E.g. stats.govuk.app.govuk-cdn-logs-monitor.logs-cdn-1.status.200
- Increments statsd counters for which backend (e.g. origin or mirror) are
  serving a request.
- It outputs data to stdout - which subsequently goes to logit - of any
  requests that are not served by origin or the CDN itself.
- On a nightly basis various log files are assembled which:
  - Count how many times a path was accessed via a particular method and
    backend in an hour.
  - Store a list of all paths that were accessed successfully that day.

There is more in-depth documentation in the [repo][repo-docs].

## Comparative data

There does not appear to be any tools that are monitoring the graphite data
that statsd populates. This was checked by searching govuk_puppet for any
references to the govuk-cdn-logs-monitor namespaces.

We do monitor similar graphite databases for CDN health by utilising
`monitoring-1_management.cdn_fastly-govuk.requests-status_*` which are fed by
collectd usage of Fastly API.

We don't appear to have an equivalent statistic to the one provided which
tracks requests per backend - presumably though we could collate this if needed
by comparing other graphite sources.

If we were to turn off this application we would not have the CDN requests
sent to logit. However we would suggest that the ones we have now are a source
of confusion as it is not clear why only some reach logit.

The most likely sources we have for similar data relating to when paths changed
from a successful status code to an unsuccessful one are Google Analytics,
Logit, and access to the raw CDN logs. We are not aware of anyone making use of
the files produced by this application with this data.

The [Future steps](#future-steps) section of this document explores using
[AWS Athena][] as a means to query for the data sources that are lost.

## Data usage

This application currently uses 413GB on `logs-cdn-1` and stores > 100GB of
Graphite databases on `graphite-1`. A significant portion of the graphite storage
is due to unnoticed misconfiguration.

## Proposal

If we are to gain consensus through this RFC that it is beneficial to retire
this application we will intend to remove it from GOV.UK architecture, archive
application data associated with it and finally remove the server class and
machines it runs on.

These are the steps we propose to achieve this:

- Stop running the application through a configuration change in govuk_puppet,
  then allow time to see if we are alerted to any services or monitoring systems
  that break due to the lack of data
- Create an S3 bucket which can be used to store the 413GB of data we have
  accumulated on logs-cdn-1
- Prune the data from Graphite
- Switch Fastly to send the CDN logs to an S3 bucket rather than logs-cdn-1
- Turn off the sending of logs from Fastly to logs-cdn-1
- Remove the application and associated services from govuk_puppet
- Remove the machines from govuk_puppet and vCloud
- Archive the [GOV.UK CDN Logs Monitor][cdn-logs-repo] repository

## Future steps

By hooking the eventual S3 bucket into [AWS Athena][] we can set up a query
interface to search the logs which should provide answers to a number of the
queries that we we hoped GOV.UK CDN Logs Monitor would answer.

[cdn-logs-repo]: https://github.com/alphagov/govuk-cdn-logs-monitor
[repo-docs]: https://github.com/alphagov/govuk-cdn-logs-monitor/blob/master/docs/design.md
[AWS Athena]: https://aws.amazon.com/athena/
