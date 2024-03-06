---
status: accepted
implementation: superseded
status_last_reviewed: 2024-03-06
---

# Migrating to a new Elasticsearch cluster

## Problem

We are migrating GOV.UK search from an elasticsearch cluster running elasticsearch 0.90.12 to one running elasticsearch 1.4.4. &nbsp;This can't be done as a rolling upgrade, so instead we have brought up a new cluster and plan to migrate the data over.

We're also moving rummager to run in a new cluster at the same time (on search-[123].api.production).

## Current status

elasticsearch-[123].backend cluster is running elasticsearch 0.90.12, and is the live search index

backend-[123].backend cluster is running rummager, talking to elasticsearch-[123].backend cluster, and handling requests from apps. &nbsp;Rummager is deployed on these machines under the app name "search".

api-elasticsearch-[123].api cluster is running elasticsearch 1.4.4, with all indexes created but with no data in the indexes

search-[123].api cluster is running rummager, talking to api-elasticsearch-[123].api cluster, but handling no requests from apps. &nbsp;Rummager is deployed on these machines under the app name "rummager".

## Steps

| Aim | How | Preparation |
| --- | --- | --- |
| Ensure that the latest version of rummager is deployed to the new cluster | 

There's a separate deploy job: "Rummager Test"

Deploy: release\_971

 | None |
| Prevent indexing on the new cluster, to make sure that any changes which get to this cluster aren't applied before we're ready | 
- Disable puppet on the new cluster (search-[123].api.production) to sidekiq workers aren't started again.  
`fab $ENV class:search puppet.disable:'Rummager migration - see https://gov-uk.atlassian.net/wiki/x/XAGKAQ'`
- Stop sidekiq workers on the new cluster.  
`fab $ENV class:search sdo:'service rummager-procfile-worker stop'`
- Ack the alerts in nagios (should be 3 of them, saying the workers aren't running)
 | None |
| Copy all indexes from the old cluster to the new cluster | 

Use the "[https://deploy.preview.alphagov.co.uk/job/Migrate\_elasticsearch\_indexes\_to\_new\_cluster](https://deploy.preview.alphagov.co.uk/job/Migrate_elasticsearch_indexes_to_new_cluster)" job.

This should take around 10 minutes to run.

&nbsp;

 | None. |
| Change which machines searches and index requests go to, to point to the new rummager instances. From this point, users won't see updates in the search index until we finish the migration. | 

Change where the "search" name points to, to switch requests and indexing over to the new cluster.

1. 
  - Merge PR to change target of search.
  - Deploy puppet: build\_15653
  - Force convergence on machines we care about:  
  
`fab $ENV class:backend puppet:'-v'`  
`fab $ENV class:whitehall_backend puppet:'-v'`  
`fab $ENV class:whitehall_frontend puppet:'-v'`  
fab $ENV class:calculators\_frontend puppet:'-v'  
`fab $ENV class:frontend puppet:'-v'`  
`fab $ENV class:frontend_lb puppet:'-v'`  
  
  - We then need to restart all apps which index or search:
    - whitehall (indexes + searches)
    - 

panopticon (indexes)

    - 

specialist-publisher (indexes)

    - search-admin (indexes)
    - 

frontend (searches)

    - 

finder-frontend (searches)

    - 

design-principles (searches)

    - government-service-design-manual (searches)
    - govuk\_content\_api (searches)
    - collections-api (searches)
    - collections (searches)

fab $ENV class:whitehall\_backend app.reload:whitehall

fab $ENV class:whitehall\_backend app.reload:whitehall-admin-procfile-worker

fab $ENV class:backend app.reload:panopticon

fab $ENV class:backend app.reload:specialist-publisher

fab $ENV class:backend app.reload:search-admin

fab $ENV class:whitehall\_frontend app.reload:whitehall

fab $ENV class:frontend app.reload:frontend
fab $ENV class:calculators\_frontend app.reload:finder-frontend

fab $ENV class:backend app.reload:contentapi

fab $ENV class:frontend app.reload:collections

fab $ENV class:backend app.reload:collections-api

fab $ENV class:frontend app.reload:designprinciples

fab $ENV class:frontend\_lb sdo:'service nginx reload'

 | 

Prepare puppet PR

List machines we should force / wait for convergence on

List apps we need to restart

 |
| Check that all searches are being served from the new cluster, and updates are being queued on the new cluster | 

Check that the old rummager application isn't receiving any traffic, and the new one is. Easiest way is probably just to tail the application logs, given that kibana is missing the data at present.

Also, check that the indexing queue is growing (using sidekiq-monitoring).

For sidekiq monitoring:

ssh backend-1.backend.$ENV -CNL 9000:127.0.0.1:80

Then visit http://localhost:9000/

 | None |
| Wait for the sidekiq workers on the old cluster to finish draining the queue | This is likely to have already happened - it should be very quick. Just needs a check using sidekiq-monitoring. | None |
| Disable the rummager app on the old cluster | 
- disable puppet on backend-[123].backend machines  
fab $ENV class:backend puppet.disable:'stopping rummager for migration'
- stop "search" app on backend machines  
fab $ENV class:backend sdo:'service search stop'

&nbsp;

 | Prepare fabric commands |
| Copy all indexes from the old cluster to the new cluster again, to make sure that updates that happened after the initial copy are present in the new cluster. | Same jenkins job as run earlier. | None |
| Check that all applications are running correctly.

There should be no errors (if there are errors, restart rummager, and work out why).

 | 

Wait for a while (30 minutes?) and check for errors.

 | 

None

 |
| Start the indexing on the new cluster, to catch up with the changes that happened during the migration | 

Start the sidekiq workers on the new cluster

`fab $ENV class:search sdo:'service rummager-procfile-worker start'`

Updates from the time we switched applications to point at the new rummager cluster should be in the sidekiq queue at this point, and this will apply them to the index in the new cluster.

 | None |

&nbsp;

&nbsp;

&nbsp;

&nbsp;

