# One database per RDS instance

## Summary

We currently use a one-instance-many-databases approach to hosting MySQL, Postgres, Mongo and Redis. These mega-databases make it difficult to perform major version upgrades – they need to be coordinated across all applications at the same time, increase the blast-radius of problems in a single database, and make it harder to appropriately size and monitor resources for an application.

This RFC proposes that we split the single RDS instances for MySQL and Postgres, moving to a single RDS instance per database. It also proposes we apply the same principle to our self-hosted Mongo and Redis installations.

This principle _could_ be applied to RabbitMQ, S3, etc., but it's out of scope for this RFC.

## Naming

The word "database" is often interchangeably used to describe a collection of tables, and an instance of (e.g.) Postgres server running somewhere. For the purposes of this RFC, "database" refers to the collection of tables, schema, etc.. We'll use "instance" to refer to the runtime that hosts the database.

## Problem

Having a single instance hosting multiple databases has a number of drawbacks:

1. Major upgrades must be applied to all databases in one go, as it's the instance we're upgrading, not the database. Major upgrades are considered risky because they contain potentially breaking, and backward-incompatible changes. This means major upgrades are scarier, so we're less likely to do them until we're forced. They also require coordination across disparate teams so everyone's confident their apps will survive the upgrade.

2. Problems in one database are likely to impact other unrelated services. For example an app with unexpectedly high load on its database could max-out the instance, causing performance degradation in other databases and their apps.

3. Related to [2], it's significantly harder to size instance resources. Disk is fairly straightforward, but it's harder to understand CPU/RAM/IOPS patterns. We're also likely to over-size resources to reduce the likelihood large-scale problems in [2].

4. There is no clear owner of the instances. Each app is owned by a single team, and each database should be accessed by exactly one app. However, many apps with different owners reside on the single instance. Sizing and managing databases is an app-level responsibility, so it doesn't fit with the remit of Platform Reliability/Replatforming/Platform Health (i.e. for a single, central resource).

This is coming up now because our versions of MySQL and Postgres are approaching End of Life (notice for [MySQL](https://forums.aws.amazon.com/ann.jspa?annID=8790) and [Postgres](https://forums.aws.amazon.com/ann.jspa?annID=8499)), forcing us to plan major upgrades for both over the next few months.

## Proposal

We propose that:

1. All new long-lived databases are created in their own individual RDS instances.
2. Existing MySQL and Postgres databases are migrated out of the central instance to individual managed-service instances as part of the upcoming major upgrade cycle.
3. Existing Redis and Mongo databases are migrated out of their central instances in-line with team priorities, and prior to any major upgrade.


### Consequences

- Creating more RDS instances means that application-owning teams will need to monitor and consider database upgrades as part of their day-to-day work. We can ease this burden through monitoring & reporting, which may be considered by a future Platform Reliability team.

- Zero-downtime migrations take extra planning and effort. Services such as AWS DB Migration Service ease some of this complexity.

- This change affects our production, integration, staging and CI environments. Our setup for CI requires a slightly different user setup so we can create and destroy databases within the instance (where we create databases per test run).

## Questions

1. Should we exclude CI from this proposal, and use a separate RFC to cover changes there?

2. Do we need another RFC for to discuss the use of managed services (e.g. RDS) in preference to self-hosted?