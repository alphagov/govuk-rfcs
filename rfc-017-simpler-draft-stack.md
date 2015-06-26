## **Problem**

The current draft stack design is laid out as an exact copy of the `frontend`, `API`, and `management` VDCs in the GOV.UK vCloud Organisation. Because we've replicated all our data store clusters (Mongo and ElasticSearch), as well as our monitoring stack, we have over 30 machines in this VDC.

Additionally, because we've hit the limit of VDCs in our current vCloud Org, we've had to build this VDC in a new org.

Creating a new org has some extra implications to our setup, namely:

- It creates deployment complexity - we need extra Jenkins instances to maintain a privileged connection to the new Org, and chain Jenkins jobs across Orgs together to deploy
- It creates operational complexity
  - we have to create extra SSH configuration and deploy this to all clients to allow us to easily get on the machines
  - we now have at least 2 monitoring stacks to watch (in different orgs)
  - we now have at least 2 Kibana instances, so logs are no longer all in one place
- Data synchronisation is a problem because we have to create VPNs between Orgs

**Proposal**

To reduce the complexity, we propose to, within the main GOV.UK Production vCloud Org:

- Add 2 machines to the cache VDC: `draft-cache-{1,2}`
- Add 2 machines to the frontend VDC:` draft-frontend-{1,2}`
- Add 2 machines to the API VDC:` draft-content-store-{1,2}`

The applications that depend on data stores (`router, content-store, router-api`) will use the existing clusters, but use different database names (eg `draft_content_store_production`).

This has a few advantages over the previous design:

- It requires significantly less machines (6 vs 30+)
- It simplifies deployments - we're deploying into a single Org so no need for extra Jenkins machines
- It simplifies operations - we can use the existing Errbit, Icinga, and Kibana setups; and for 2nd line staff no change is required to SSH configuration

it also has one main negative - the security model previously offered (total separation of content and data/requests) is no longer as simple to come by. We plan to address this using vShield Edge firewalling.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

