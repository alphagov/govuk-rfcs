## **Problem**

The old draft stack used firewall rules to ensure that instances of frontend applications intended to serve published content were prevented from inadvertently reading from the instance of the content-store application used to serve draft (unpublished) content.

This is an operational risk for GOV.UK, since unpublished content may be [embargoed](https://en.wikipedia.org/wiki/News_embargo) for publication or otherwise contain sensitive information that should not become public until published.

Now that applications serving draft content are hosted in the same vCloud organisation as their counterpart instances&nbsp;used for published content&nbsp;(see ), we must identify any vectors through which the published frontends could read from the draft content store.

&nbsp;

**Proposal**

We have identified vectors through which a published frontend application might inadvertently read from the draft instance of the content-store application:

1. The instance of the content-store used for published content could inadvertently read from the draft instance of the content-store database if its database settings were misconfigured.
2. Draft instances of frontend applications could inadvertently read from the draft instance of the content-store application if their configuration was incorrect.

Vector (1) has been mitigated by avoiding the use of a default for the name of the content-store database when configuring the content-store application, meaning that each machine class (i.e. content\_store or draft\_content\_store) must explicitly set the database name.

&nbsp;

&nbsp;

&nbsp;

&nbsp;

