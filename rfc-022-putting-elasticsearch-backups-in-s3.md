---
status: accepted
implementation: done
status_last_reviewed: 2024-03-06
---

# Putting Elasticsearch backups into S3

## Problem

Currently, we don't have good (any?) backups for our elasticsearch indexes. &nbsp;This is particularly critical for the index which powers the main site search, since it takes at least 2 hours to rebuild the indexes for the "/government" content from scratch, and requires lots of separate apps to be prodded to rebuild the indexes for the mainstream index.

Our current mechanism for syncing the search indexes to other environments, and to developer machines, is:

- slow (can take 90 minutes to perform the sync, because it rebuilds the indexes from JSON, and we now perform lots of complicated analysis in elasticsearch)
- frequently fails (lots of dependencies and moving parts)
- hard to maintain
- requires ssh access to preview machines to get developer builds
- developers can't get an up-to-date copy of the search index - latency of at least a day (more when nightly jobs have failed)

## Proposal

Since elasticsearch 1.0, elasticsearch has supported&nbsp;["Snapshot and Restore"](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html), which allows a snapshot of a search index to be copied to either a shared filesystem, or to amazon S3. &nbsp;I propose that we use S3, for its ease of setup, and because it will allow us to share the resulting backups easily.

&nbsp;

In detail:

- snapshots are configured per-index.&nbsp;each index should have a snapshot set up to copy it from production to S3.
- the snapshot should be updated frequently (eg, every 5 minutes)
- the snapshots should be&nbsp;made readable to everyone (ie, no access control needed to access the snapshots).&nbsp;This is much more convenient than having to give all developers access to a special set of S3 keys. All the indexes which currently exist contain only publically available content, so there is no confidentiality issue with this right now. If draft ("preview") content is put into the search system, it should be put into a separate elasticsearch index, which will **not** be made publically readable - a separate S3 bucket would be used for this, and this might require accreditation approval since it would not be public data.
- the sync process from production to staging and preview environments will be replaced with a restore process. &nbsp;This can be made "atomic" (I'm not sure if the restore process is atomic by default, but if not we can make it restore to a new index, and use aliases to switch it in place once the restore complete, much as we currently do).
- we should also ensure that the scripts for restoring to staging and preview work for restoring to production, for disaster recovery.
- sync to developer machines should also be replaced with using the restore process

As well as fixing existing problems with syncing, this proposal has the following benefits:

- We would have working backups of the search index, and since we'd be using them for data sync, we'd notice quickly if the backups stopped being viable.  
- Being open about this should enable other uses to be made of the data (for example, I know academics who would love to have a local copy of the GOV.UK search index so that they can perform experiments on it).
- Future upgrades of elasticsearch should become much easier and safer, since we could easily revert an upgrade (and go back to an earlier index snapshot), and could also perform an&nbsp;upgrade by building a new cluster and switching over easily, if desired.

&nbsp;

&nbsp;

