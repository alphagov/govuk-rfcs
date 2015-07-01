## **Problem**

The old draft stack used firewall rules to ensure that instances of frontend applications intended to serve published content were prevented from inadvertently reading from the instance of the content-store application used to serve draft (unpublished) content.

This is an operational risk for GOV.UK, since unpublished content may be [embargoed](https://en.wikipedia.org/wiki/News_embargo) for publication or otherwise contain sensitive information that should not become public until published.

Now that applications serving draft content are hosted in the same vCloud organisation as their counterpart instances&nbsp;used for published content&nbsp;(see ), we must identify any vectors through which the published frontends could read from the draft content store.

**Proposal**

We have identified vectors through which a published frontend application might inadvertently read from the draft instance of the content-store application:

1. The instance of the content-store used for published content could inadvertently read from the draft instance of the content-store database if its database settings were misconfigured.
2. Draft instances of frontend applications could inadvertently read from the draft instance of the content-store application if their configuration was incorrect.

### Mitigation for vector (1)

Vector (1) has been mitigated by [avoiding the use of a default](https://github.gds/gds/puppet/commit/3fa80cdceb7138dc2f1a7e4aba90976274a3ce65#diff-317c81f58cd20afec981e1e6c339703f) for the name of the content-store database when configuring the content-store application, meaning that each machine class (i.e. [content\_store](https://github.gds/gds/puppet/blob/effc4c0cab1/hieradata/class/content_store.yaml#L3) or [draft\_content\_store](https://github.gds/gds/puppet/blob/effc4c0cab1/hieradata/class/draft_content_store.yaml#L3)) must explicitly set the database name.

### Mitigation for vector (2)

The draft instance of the content-store application is fronted by Nginx the existing api\_lb machines, much the same way that the published instance of content-store is fronted by Nginx. The decision to share the api\_lb for requests for both draft and published content was made to avoid the additional expense for creating two new draft\_api\_lb machines for serving draft content.

We initially explored access limiting by IP address within the Nginx virtual host for requests going to `draft-content-store.production.alphagov.co.uk` on the api\_lb machines so as to block requests coming from published instances of frontend applications, however this was not possible because the client IP address in the HTTP request is presented as originating from the API vDC network's gateway IP address. This makes it impossible, in this configuration, to differentiate between requests from published and draft instances of frontend applications.

The only other possibility for implementing access control by IP address would be in the vShield Edge Gateway's firewall rules. Applying a firewall rule for the [existing API vSE load balancer](https://github.gds/gds/govuk-provisioning/blob/c33df9b/vcloud-edge_gateway/rules/lb.yaml.mustache#L169-L175) would not work as both published and draft applications would require access to it

&nbsp;

&nbsp;

