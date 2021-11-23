# One database per RDS instance

## Summary

We currently use a one-instance-many-databases approach to hosting MySQL, Postgres, Mongo and Redis. These mega-databases make it difficult to perform major version upgrades – they need to be coordinated across all applications at the same time, increase the blast-radius of problems in a single database, and make it harder to appropriately size and monitor resources for an application.

This RFC proposes that we split the single RDS instances for MySQL and Postgres, moving to a single RDS instance per database. It also proposes we apply the same principle to our self-hosted Mongo and Redis installations, and more generally to all supporting services for an application which aren't shared with other applications.

## Naming

The word "database" is often interchangeably used to describe a collection of tables, and an instance of (e.g.) Postgres server running somewhere. For the purposes of this RFC, "database" refers to the collection of tables, schema, etc.. We'll use "instance" to refer to the runtime that hosts one or more databases.

## Problem

Having a single instance hosting multiple databases has a number of drawbacks:

1. Major upgrades must be applied to all databases in one go, as it's the instance we're upgrading, not the database. Major upgrades are considered risky because they contain potentially breaking, and backward-incompatible changes. This means major upgrades are scarier, so we're less likely to do them until we're forced. They also require coordination across disparate teams so everyone's confident their apps will survive the upgrade.

2. Problems in one database are likely to impact other unrelated services. For example an app with a poorly performing database has caused performance degradation in other databases and their apps[^1].

3. Related to [2], it's significantly harder to size instance resources. Disk is fairly straightforward, but it's harder to understand CPU/RAM/IOPS patterns. We're also likely to over-size resources to reduce the likelihood large-scale problems in [2].

4. There is no clear owner of the instances. Each app is owned by a single team, and each database should be accessed by exactly one app. However, many apps with different owners reside on the single instance. Sizing and managing databases is an app-level responsibility, so it doesn't fit with the remit of Platform Reliability/Replatforming/Platform Health (i.e. for a single, central resource).

This is coming up now because our versions of MySQL and Postgres are approaching End of Life (notice for [MySQL](https://forums.aws.amazon.com/ann.jspa?annID=8790) and [Postgres](https://forums.aws.amazon.com/ann.jspa?annID=8499)), forcing us to plan major upgrades for both over the next few months.

## Proposal

We propose a new principle to be applied across GOV.UK:

> Supporting services for an application should not be shared with any other applications at the infrastructure/provisioning level.

For example, a RabbitMQ queue used solely to manage Sidekiq jobs for an application should never be accessed by another app. An exception to the rule would be when services are designed for application communication, such as a RabbitMQ queue that broadcasts publishing events to be consumed by other apps. Both types of queues should live in distinct RabbitMQ instances/servers.

Applying this initially to our databases, we propose that:

1. All new long-lived databases are created in their own individual RDS instances.
2. Existing MySQL and Postgres databases are migrated out of the central instance to individual managed-service instances as part of the upcoming major upgrade cycle.
3. Existing Redis and Mongo databases are migrated out of their central instances in-line with team priorities, and prior to any major upgrade.
4. Any future supporting services for applications should be distinct to the application and, where applicable, run on a managed service

### Consequences

- It will be easier to identify the causes of performance problems in an application.

- The chance of a problem with one service cascading to other services will be reduced, because there is no contention for resources which aren't shared.

- Creating more RDS instances means that application-owning teams will need to monitor and consider database upgrades as part of their day-to-day work. We can ease this burden through monitoring & reporting, which may be considered by a future Platform Reliability team.

- There will be less consistency in database versions across the programme. Individual teams are responsible for their upgrade appetite and prioritisation.

- There is a potential increase in costs caused by having dedicated instances, particularly when they are initially split (because it's harded to accurately estimate resource requirements). This may be offset by being able to optimise individual databases to their needs.

- Migrating to new instances with minimal (or no) downtime takes planning and effort. AWS' forced upgrades of Postgres and MySQL in early 2022 will force this effort regardless.

- This change affects our production, integration, staging and CI environments. Our setup for CI requires a slightly different user setup so we can create and destroy databases within the instance (where we create databases per test run). There's likely a strong argument for using local disposable databases in non-production-like environments like integration or CI, to skip the long RDS provisioning times - the move to kubernetes should in principle make this pretty straightforward, but we'll cover that in a separate RFC when it's feasible.

- CI will need to support a wider range of database versions than it currently supports to cope with teams using different versions. Ideally, teams will be able to create and manage databases to meet their needs independently, but as a first step we'll need to introduce a pool of "supported" database types and versions. We have experience of doing this with Mongo and tagged agents.

[^1]: [Incident report for Imminence slowness](https://docs.google.com/document/d/10aOHyjO8JjzbIhj5HpowAuDlXvnbkAnDgYpTuCpBv-0/edit#heading=h.gzidrot4nw3r)
