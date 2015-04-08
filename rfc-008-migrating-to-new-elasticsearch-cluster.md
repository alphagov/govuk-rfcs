# Problem

We are migrating GOV.UK search from an elasticsearch cluster running elasticsearch 0.90.12 to one running elasticsearch 1.4.4. &nbsp;This can't be done as a rolling upgrade, so instead we have brought up a new cluster and plan to migrate the data over.

We're also moving rummager to run in a new cluster at the same time (on search-[123].api.production).

# Current status

elasticsearch-[123].backend cluster is running elasticsearch 0.90.12, and is the live search index

backend-[123].backend cluster is running rummager, talking to elasticsearch-[123].backend cluster, and handling requests from apps. &nbsp;Rummager is deployed on these machines under the app name "search".

api-elasticsearch-[123].api cluster is running elasticsearch 1.4.4, with all indexes created but with no data in the indexes

search-[123].api cluster is running rummager, talking to api-elasticsearch-[123].api cluster, but handling no requests from apps. &nbsp;Rummager is deployed on these machines under the app name "rummager".

# Plan

- Stop the rummager indexing sidekiq workers on the new cluster  
 - This is to make sure that any changes which get to this cluster aren't applied before we're ready.

- Copy all indexes from the old cluster to the new cluster  
 - This should be possible using something like the env-dump-restore script, but we need to ensure the schemas are copied across.  
 - I'd expect this to take about 15 minutes to run.

- Change which machines searches and index requests go to. From this point, users won't see updates in the search index until we finish the migration. This could be done in two ways:  
 - Change where the "search" name points to, to switch requests and indexing over to the new cluster.  
 - This would require a deploy of puppet, followed by convergence (we'd probably force a puppet run on the machines we care about).  
 - We'd then need to restart all affected apps.  
 - Alternatively, we could have a set of PRs to change all the applications which talk to "search" to try and contact "rummager".  
 - Would require multiple app deploys.

- Check that all searches are being served from the new cluster, and updates are being queued on the new cluster

- Wait for the sidekiq workers on the old cluster to finish draining the queue  
 - This is likely to have already happened - it should be very quick

- Disable the rummager app on the old cluster.  
 - There should be no errors (if there are errors, restart it, and work out why).

- Copy all indexes from the old cluster to the new cluster again  
 - this ensures that the most recent updates also get carried across

- Start the sidekiq workers on the new cluster, to catch up with the changes that happened during the migration.

