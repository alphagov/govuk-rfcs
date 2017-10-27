## Problem

Router-api is a Rails application whose sole purpose is to act as the data store for the router. It manages the database, exposes CRUD operations on routes and backends, and notifies router to reload when routes are updated. Router reads directly from the underlying MongoDB datastore rather than via router-api.&nbsp;There are separate instances of router-api for draft and live in each environment.

Router-api predates the current publishing platform. In the meantime, the content-store has been created as the canonical repository for all content on GOV.UK, and all content - including placeholders for unmigrated formats - now goes through that application. Content-store is currently (almost) the only place that calls router-api.

It has therefore become clear that there is now significant duplication in data and functionality between these two applications. In addition, the separation between databases means that it is possible for them to get out of sync; and the necessity for the content-store to call router-api on every update adds unnecessary asynchronicity and overhead to the publishing process.

## Proposal

Content-store should be the canonical store of routes. Router should read directly from content-store, and router-api should be retired.&nbsp;

This reduces the number of applications and databases we have to maintain, and avoids the duplication of data and the risk of it getting out of sync.

Because router reads from the datastore rather than the api, migrating to use content-store should mainly require storing the information in the appropriate form in the content-store MongoDB - in other words, removing the&nbsp;`routes` and&nbsp;`redirects` fields from ContentItem and moving the data into a separate Route model, as well as creating a Backend model. Router can then be pointed at the content-store database.

## Implementation

### Preconditions

The work to migrate router-data to short-url-manager needs to be finished. Some of the files in that repository have not been possible to migrate, because they contain routes with that conflict with existing routes in publishing-api that have different publishing apps. Some time needs to be dedicated to this job.

Whitehall's organisation\_slug\_changer task is the only other place in our stack that calls router-api directly. This should be rewritten so that it send redirects to the publishing-api.

All publishing applications should send explicit routes to the publishing platform for documents that contain sub-pages. Travel-advice-publisher is already doing this, but publisher is not.

### Changes required to content-store

Content-store should start storing routes (including redirects) as separate collections in its own datastore. This could be achieved by copying over the Route and Backend models from router-api. (Although in theory it should be possible to modify router to read the routes and redirects from the existing ContentItem model structure, attempts to do so made route reloading impractically slow.) A migration will be needed to create all the existing routes and backends.

Routes and backends should then be created directly on updates of content items, replacing the existing calls to router-api. The functionality to signal router to reload its routes should also be moved over from router-api.

To get the most benefit from this work, we should also remove the&nbsp;`routes`&nbsp;and&nbsp;`redirects`&nbsp;fields from the ContentItem model itself. These are not used by any of the frontends and are not useful information in any future public API, since they only concern our internal route registration functionality. To preserve the ability for a sub-page request to return the ContentItem for the base page, we should add a&nbsp;`base_path`&nbsp;field to the Route model which contains that canonical base path for every item.&nbsp;

(We may need to do some more thinking about how PublishIntents fit into this. They have the ability to store multiple paths, in the same way as ContentItems do currently, and share the FindByPath mixin to query them. However there are currently no publish intents with multiple paths, and it's not clear if anything could even create them.)

### Infrastructure changes

Content-store is in the api VDC, whereas router-api is in the router VDC. The firewall rules would need to be changed to allow the router to read directly from the api-mongo database.

The last step is to modify the puppet hieradata to set the ROUTER\_MONGO\_URL and ROUTER\_MONGO\_DB environment variables to point at the content store db.&nbsp;

Router-api in both draft and live, as well as the api-mongo cluster, can then be retired.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

