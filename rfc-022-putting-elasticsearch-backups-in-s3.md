## **Problem**

Currently, we don't have good (any?) backups for our elasticsearch indexes. &nbsp;This is particularly critical for the index which powers the main site search, since it takes at least 2 hours to rebuild the indexes for the "/government" content from scratch, and requires lots of separate apps to be prodded to rebuild the indexes for the mainstream index.

We also don't have a good way to sync the search indexes to other environments, and to developer machines.

**Proposal**

Since elasticsearch 1.0, elasticsearch has supported&nbsp;["Snapshot and Restore"](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html), which allows a snapshot of a search index to be copied to either a shared filesystem, or to amazon S3. &nbsp;I propose that we use S3, for its ease of setup, and because it will allow us to share the resulting backups easily.

In detail:

&nbsp;- each index should have a snapshot set up to copy it from production to S3.

&nbsp;- the snapshot should be updated frequently (eg, every 5 minutes)

&nbsp;- all the indexes which currently exist contain only publically available content, and should be made readable to everyone (ie, no access control needed to access the snapshots). &nbsp;This is much more convenient than having to give all developers access to a special set of S3 keys. &nbsp;Being open about this should enable other uses to be made of the data (for example, I know academics who would love to have a local copy of the GOV.UK search index so that they can perform experiments on it).

&nbsp;- if draft ("preview") content is put into the search system, it should be put into a separate index, which will not be made publically readable.

&nbsp;- the sync process from production to staging and preview environments will be replaced with a restore process. &nbsp;This can be made "atomic" (I'm not sure if the restore process is atomic by default, but if not we can make it restore to a new index, and use aliases to switch it in place once the restore complete, much as we currently do).

&nbsp;- we should also ensure that the scripts for restoring to staging and preview work for restoring to production, for disaster recovery.

&nbsp;- sync to developer machines should also be replaced with using the restore process

This work should be completed before we next attempt to upgrade the elasticsearch cluster, both to allow easy reverting of such an upgrade, and to allow an upgrade to be done by building a new cluster and switchng over easily, if desired.

&nbsp;

&nbsp;

