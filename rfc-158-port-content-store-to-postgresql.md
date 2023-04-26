# Port Content-Store to PostgreSQL on RDS

## Summary

GOV.UK Publishing should port content-store from its current legacy self-hosted MongoDB, to PostgreSQL running on AWS' RDS.

## Problem

Content-store is a critical component of GOV.UK. All front-end apps rely on it for serving requests, it serves the GOV.UK content API directly, and is the authoritative source of all content published on GOV.UK. However, it stores this content in a self-hosted legacy database (MongoDB v2.6) which is poorly understood, difficult to support, and has been marked [end-of-life since 2016](https://www.mongodb.com/blog/post/mongodb-2-6-end-of-life). 

There are many consequences of this long-standing tech debt: 

- we do not receive security updates for MongoDB
- support for this version is hard to find in tooling and client libraries 
- when incidents occur with it we do not have the expertise in-house to fully understand and resolve issues
- when GOV.UK replatformed onto Kubernetes in March 2023, the MongoDB cluster was not migrated over. It still runs on EC2 instances configured via GOV.UK Puppet, and is a blocker for deprecating that large legacy codebase
- we cannot run the same version locally as in production (it is not available for the standard developer laptops), meaning compatibility and testing is largely based on hope rather than rigour
- GOV.UK developers (and the wider industry pool of developers from which we hire) tend to be significantly less familiar with Mongo than PostgreSQL, which most of the rest of GOV.UK runs on
- The Mongoid ORM adapter which we use to connect to Mongo from our Ruby on Rails applications does not support many of the features of the more standard ActiveRecord, which is used throughout GOV.UK - meaning the content-store application is harder to work on and creates more toil for developers

[Architectural Decision Record 0038](https://docs.publishing.service.gov.uk/repos/govuk-aws/architecture/decisions/0038-mongo_replacement_by_documentdb.html) recommended in 2019 that in general MongoDB should be replaced with Amazon's proprietary DocumentDB. However this has not proved to be a workable decision in practise for several reasons, including an inability to run DocumentDB locally, its "Mongo compatibility mode" not being fully compatible, and increasing dependence on single-vendor proprietary software against general government policy of choosing open-source by default.


## Proposal


A previous [options paper](https://docs.google.com/document/d/1evZ6B3a2XMU8YgDruuS8idseqC38vcogo_bnIDshfrY/edit#) written by Ryan Brooks (previous Lead Technical Architect for GOV.UK Publishing) recommended migrating to RDS PostgreSQL as the most practical option for content-store.

GOV.UK Publishing Platform team will implement this recommendation - we will port content-store to run on PostgreSQL, using Amazon's RDS managed service in integration, staging and production. This will bring content-store in line with most of GOV.UK, and externalise responsibility for the mechanics of running and updating a highly-available datastore under load, to Amazon. It will also allow us to use the exact same version of PostgreSQL for local development as in production. 

We have already performed tech 'spikes' to prove the concept of a) porting the application, and b) migrating the full dataset over to PostgreSQL (overall [Trello 'epic' card](https://trello.com/c/C1BQDFTG/502-plan-for-migrating-content-store-off-mongodb) ). Whilst there are several possible ways to manage the migration, this RFC is focussed on the target end-state, not how to get there. We can, however, state that we are confident we can achieve this migration with :

- zero or near-zero downtime
- no significant changes to the HTTP content-store APIs
- comparable performance for most queries as a result of the move

## Consequences

While the majority of applications correctly use the API to interact with content-store data, there are some downstream processes which depend on the nightly database backups, and therefore will need to be changed. These include:

- The overnight [environment sync](https://docs.publishing.service.gov.uk/manual/govuk-env-sync.html) job, which dumps live data to S3 and imports it into integration & staging environments
- Data Services' GCP [Storage Transfer job](https://github.com/alphagov/govuk-s3-mirror/blob/main/terraform/transfer.tf) to upload the S3 backup to Google Cloud Platform for subsequent analysis and processing
- The [GOV.UK MongoDB Content tool](https://docs.publishing.service.gov.uk/repos/govuk-mongodb-content.html) which allows the user to explore a local copy of the database
