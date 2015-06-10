## **Problem**

Editions in Whitehall have the ability to be marked as "access limited". This means that until they are published, only users in the organisation the edition belongs to, or (for world news articles) associated with the world locations of the organisation, can view the edition in draft. This functionality needs to be replicated in the draft stack so that access-limited content is only viewable by the relevant users before publication.

### Agreed solution

After discussion it has been decided to split authorisation and authentication. The content-store will be responsible for authorisation, i.e. determining if a user can see a given content item. A new minimal app will live in front of the router and be responsible for authentication, i.e. identifying a user with a signon session. This will involve the following changes:

**A new "Authenticating proxy" application**

- authenticates users via signonotron oauth
- proxies requests from authenticated users adding an&nbsp;&nbsp;`X-GOVUK-AUTHENTICATED-USER` header containing the user id
- denies all unauthenticated requests

**Updates to content-store**

- Uses the the &nbsp;`X-GOVUK-AUTHENTICATED-USER`&nbsp;header to check the list of permitted users in content item data
- Returns 403 if user is not permitted to see the item
- Ensures that responses for access limited items are marked with no\_cache headers. This is in accordance with our principle that frontend applications honour cache headers from content-store.

**Updates to gds-api-adapters**

&nbsp;

- propagates&nbsp;the user ID in the&nbsp;`X-GOVUK-AUTHENTICATED-USER`&nbsp;header to content-store API requests.

**Updates to government-frontend**

- serves a nice 403 page for unauthorised user requests

Flow diagram

&nbsp;

Flow diagram generated using [http://bramp.github.io/js-sequence-diagrams/](http://bramp.github.io/js-sequence-diagrams/)&nbsp;graph source at&nbsp;[https://gist.github.com/heathd/44dd5e0aaede647121f2](https://gist.github.com/heathd/44dd5e0aaede647121f2)

### Data representation

The content item should contain the list of user ids who are allowed to access this item. The publishing application is responsible for providing this list; for example in the case of Whitehall, where access limits are defined by organisation, the app would expand the organisation into a list of its member users. Since draft items are relatively ephemeral, there should no need to provide functionality to republish them if organisation membership changes.

The `access_limited`&nbsp;object will be constructed as follows:

Defining this as an object with a single "users" key provides flexibility in case we do need to add alternative authorisation methods in the future.

&nbsp;

### **Original Proposals we considered**

Add an optional&nbsp;`access_limited`&nbsp;boolean to formats/metadata.json so it is added to the base of all edition schemas. (Don't need to provide the actual org or location since they are already provided in links?)

**Option 1: in content store**

Add gds-sso gem to content-store and create User model (shouldn't need any extra fields).  
When contentitem has access\_limited, check organisation matches.  
Pass through OAuth token and JSON blob when making API request to content-store - how?  
How to redirect to signon if not authenticated?&nbsp;

**Option 2: new authenticator service _(chosen as final option)_**

Sits between router and the frontend apps, uses gds-sso gem.  
Would need to store data from signon which means having a database. Is there no way to use gds-sso without storing data locally?  
Makes request to content-store to determine if item is access limited. Maybe a new content-store endpoint to just return org slug, to avoid passing the whole content item around twice?  
How to route via authenticator, since router will point to government-frontend?

**Option 3: do it in government-frontend**

Use gds-sso here, so would need to add a database&nbsp;(again, is there really no way of doing it without?)  
Simplifies routing and redirection, and would only need to request content once  
Possible duplication if other frontends also need this functionality.

**For the sake of completeness, option 4: in router**

Horrible as a) blurs responsibility of router and b) it's go so we would need to re-implement all the sso stuff.&nbsp;  
But, it has a database, it's central, and would avoid problems with routing and redirection.&nbsp;  
Wouldn't solve issue of requesting data twice though, and would need to have a way of rendering 'not for you' page.&nbsp;

&nbsp;

&nbsp;

&nbsp;

