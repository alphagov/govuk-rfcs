---
status: accepted
implementation: done
status_last_reviewed: 2024-03-04
---

# Updating routes in Router

## Summary

This RFC proposes changing the way that routes are updated in Router, moving away from Router API manually updating Router instances and instead allowing Router instances to keep themselves up-to-date via polling MongoDB for changes.

## Problem

Whenever a route needs to be added or updated, Content Store calls into Router API to perform the update. Router API knows the address of every Router instance from a static file that it reads at start-up; it then uses this information to call the `/reload` endpoint on every Router instance to let them know that routes have been updated, so that those instances reload the routes they hold in memory.

As GOV.UK moves to containerise more applications and host them in AWS Elastic Container Service (ECS), Router API will no longer be able to talk to individual instances of Router without additional changes; these changes can either be to rethink how Router instances are updated, or to implement a hacky solution which attempts to keep Router API's ability to talk to Router instances through making a DNS request to AWS App Mesh, get the IP addresses of Router instances and then _attempt_ to talk to them.

The current implementation of updating routes has led to scaling issues. When scaling Router, Router API takes [5 minutes][] to get an accurate router node list. If Router API fails to update a Router node (i.e. one that is being brought up/down), the API also [fails to reach subsequent nodes in the list][].

We should therefore rethink how these routes are updated within Router instances and to come up with another way of managing the update process.

[5 minutes]: https://github.com/alphagov/govuk-puppet/blob/84689ae2c36bbc7740da6a8d70c7f4e04d0e2357/modules/govuk/manifests/apps/router_api.pp#L110
[fails to reach subsequent nodes in the list]: https://github.com/alphagov/router-api/blob/2aa74d402624837c87fef136084ae66633e57d46/lib/router_reloader.rb#L46

## Proposal

Router will keep its in-memory cache of routes up-to-date via a two stage process:

  1. Router will perform a simple query against MongoDB returning the state of the database with the current set of routes; ideally this will be a query which contains a checksum or timestamp of last update which can be used by Router instances to check whether their local copy of routes is up-to-date.
  2. If the check against MongoDB concludes that Router needs to update its in-memory cache of routes, then Router will self-action a reload of all routes, using the same mechanism as it currently does when it receives a call to its `/reload` endpoint.

The polling of changes by Router against MongoDB will take place every few seconds in order to ensure that routes are updated quickly as and when they change, which keeps in line with the current approach of updating routes when comparing how fast route updates propagate through to Router instances. Individual Router instances will drift slightly out of sync with each other, but because we're polling every few seconds and updating as soon as we see changes there won't be any noticeable changes.

The query used to poll MongoDB for changes should be quick to compute, taking advantage of any existing indexes on the database or aggregates already stored by MongoDB; for example, the [db.stats() method](https://docs.mongodb.com/manual/reference/method/db.stats/) could be a useful starting point. The details of the query aren't included the scope of this RFC however and it should be assumed that a suitably performant query can be made which allows for the polling of changes to routes.

This proposal is relatively simple to implement compared to some of the others we have considered and will allow us to move at pace in decoupling Router API and Router. It also puts us in a good place to iterate the solution further by using [the change streams feature](#using-mongodb-change-streams-to-notify-router-instances-of-route-changes) in future, whether that's offered by MongoDB, DocumentDB or any other database technology that we decide to use for storing routes.

### Possible alternatives

There were a number of approaches considered to tackle the problem presented in this RFC and [these approaches have been documented in detail](https://docs.google.com/document/d/1gGRWTmhfcfU1jfBDWYMiDa-6G64tRNdPFI3BLcbCxWc/edit#). Still, it is worth a brief summary of the main approaches discussed for completeness.

#### Removing Router API entirely

The first option available to us was to remove Router API entirely, which has been [discussed previously](https://github.com/alphagov/govuk-rfcs/pull/72) and for which there also exists a [tech debt card](https://trello.com/c/MOuw5ke0). Removal of Router API from the stack would be a good refactoring for GOV.UK to remove complexity, as Content Store already calls Router API, so why not remove this call and just have Content Store update routes directly.

The downside is that this approach doesn't solve the underlying problem of this RFC. When apps are running in ECS / AppMesh, it is going to be difficult to contact individual instances of Router without doing something hacky. Removing Router API just moves the problem to Content Store not being able to talk to Router instances, it doesn't make it go away.

#### Using MongoDB change streams to notify Router instances of route changes

MongoDB has the ability to notify consumers of a dataset when data changes via [change streams](https://docs.mongodb.com/manual/changeStreams/), which could be used to completely decouple Router API and Router as outlined in this RFC.

Currently this option isn't available to us, as the MongoDB database containing routes is running version `2.6.12`, with the change sets feature being introduced from MongoDB version `3.6.0`. There is upcoming work on the roadmap to upgrade this MongoDB version outside of the scope of this RFC and there is also a wider question about whether we might want to adopt a different database technology entirely for storing routes, such as DocumentDB or PostgreSQL. For these reasons we dismissed this approach.

#### Using a message broker to notify Route of route changes

GOV.UK already uses RabbitMQ, an open-source message broker which would allow us to completely decouple Router API and Router. Router API would push route updates to an exchange in RabbitMQ and Router instances would have updates automatically pushed to them from the queues subscribed to the exchange.

There are benefits to using RabbitMQ such as message durability and the low overhead in introducing it to tackle this new problem, given that we already have the infrastructure in place. At the same time, Router API and Router instances both already talk to MongoDB, so adding in a message broker such as RabbitMQ adds yet another layer of complexity for something which could be handled as already outlined by MongoDB's change streams feature. For this reason we dismissed this approach.
