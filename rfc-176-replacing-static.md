---
status: accepted
implementation: pending
status_last_reviewed: 2024-09-03
---

# Replacing Static

## Summary

We propose splitting up the functions of the [slimmer] gem and the [static] application. Their layout functionality, which is now chiefly configuring one layout component, will be devolved to the frontend apps, the error pages and static assets will be moved into [frontend], and their support for banners will be moved into  a new gem: `govuk_web_banners`.

## Problem

The `static`/`slimmer`/`govuk_publishing components` triumviurate is a clever way of doing the jobs that it does, but it sits outside the normal idiom of how rails apps render pages, which makes it hard to understand. We have a public layout component in the [govuk_publishing_components] gem that is used to render pages in a standard way in frontend apps, but instead of accessing it directly (remember all frontend apps include the gem), they have to make a call to `slimmer` to request the variant of that layout they want, at which point `slimmer` inserts middleware that makes a network call to `static` for that layout variant. `Static` then reads that layout from its internal copy of the `govuk_publishing_components gem`, modifies it slightly to include global and emergency banners, then returns that value to the `slimmer` middleware, which slots the rendered page from the app into that returned layout.

Making a remote call through middleware to get a layout which the app already has is not an idiomatic rails way of rendering a page, and it presents a complexity barrier to changes to the frontend apps.

The reason for this complex system is that it gives `static` the ability to centralise static assets and handle adding various banners into apps. Those abilities haven't been trivial to replace. Previous RFCs have touched on replacing `static` with a gem ([RFC-84]), or the gordian knot solution of merging all affected apps ([RFC-174]). Although ultimately these RFCs were not implmented, the good news is that they were all pretty good solutions to part of the problem, they just needed some advancements in how our apps were built and deployed (which we now have). We’ve also established that some of the things static does can be done at a slightly slower pace and still be acceptable (for instance, that a 15 minute lag between the emergency banner being deployed and being visible site-wide is acceptable ([RFC-144])).


## Solutions

### The Emergency Banner (move to `govuk_web_banners`)

The current mechanism for deploying the emergency banner is via a shared redis instance. A UI in [whitehall] allows the banner to be set. The details of the banner are written into a redis key, and `static` reads that key every time it responds to a layout request, including the details of the banner in the response if present. There is no local caching of this request in `static`, but `slimmer`’s calls to `static` are cached for 60 seconds, so the redis cluster is being called at most 1 time per minute per application instance (not per application, unless the applications are sharing a cache). This means that there is a theoretical lag of up to a minute between the banner being published and it being displayed, but since the CDN caches all pages for 5 minutes anyway, this lag doesn’t have a big effect on deployment of the banner, and at any rate it’s been established that 15 minutes is acceptable delay between the button being pressed and the banner being available ([RFC-144])

Our proposal is that instead of `static` making this call to redis, all frontend apps be given read access to the same redis cluster (some of them may already have access to it), and they make the call directly through the new `govuk_web_banners` gem. This call can itself be cached for a minute, so in theory the number of calls to the redis cluster would remain the same, but we could then lose all the calls to `static` (which are likely to be a bit heavier-weight than the redis calls)

Longer-term, we could replace the redis call with a similarly-cached call to a [content-store] item for the various banners, which would allow us to make the various banners first-class content items with scheduling support (see also "The Global Banner"). It’s worth noting that we could also replace redis with content-store calls directly in `static`, but either way the change would be done in only one place, so that more desirable solution to handling banner content is neutral regarding whether the display is done in `static` or a gem. To implement banners in `content-store` we could either create a new schema for banners or perhaps implement them as reusable content blocks, if that project becomes realised.

### The Global Banner (move to `govuk_web_banners`)

The current mechanism for the global banner is via code directly in `static`. Adding a banner is a developer task. This allows one slight advantage over the emergency banner, which is that the code can change the banner content at a particular time (eg [removing a voter id banner] when the polls close in an election)

Our proposal is that global banners should ultimately be deployed using the same mechanism as the emergency banner, but with additional information baked into the values put into the redis store. Since redis naturally supports key expiration, the act of removing banners at a certain time would be pretty easy. Banners appearing at a certain time would be more awkward, but not insurmountable. These changes would make it deployable by content specialists as well as developers, and should be able to be implemented with minimal changes to `whitehall`.

In the short-term, just moving the existing global banner code into the gem with the recruitment banners and emergency banner would also simplify ensuring that recruitment and global banners are not shown when an emergency banner is in effect.

Longer-term, maintaining the same mechanism as emergency banners, we could look to make global banners first-class publishing items as well, which would give us standard scheduled publication options.

### Recruitment Banners (move to `govuk_web_banners`)

This isn’t a problem with `static`, but fits the banner theme and provides a neat start to the banner gem. Recruitment banners present a problem in that they often need to be inserted into the body of a page inside the area that `static` normally considers the app’s section (the wrapper). This means they need to be maintained in multiple apps.

Our proposal is that we include the current duplicated recruitment banner config, code, and partial views in the gem. Then we can include the gem in each application and put a single call to it in the relevant app layouts. This means we can keep the configuration in one place, where it’s more easily checked for problems, and a single release of the banner gem will be automatically pulled into each relevant app at the next dependabot merge.

### Static Assets (move to `frontend` and `special-route-publisher`, and to nginx configuration)

Some static assets (such as the favicon and apple touch icons, among others) are served by `static`. Most are simple assets compiled during the image build phase and copied into the S3 bucket. These can be moved into `frontend`. Others need to be accessed externally, and have special routes that static publishes to the publishing api directly. The publishing metadata for these items can be moved into [special-route-publisher] (this clears up tech debt related to frontend apps having the ability to write to publishing-api, which is undesirable). There are also some redirect routes in `static` that handle old sizes of apple touch icons. These routes and their controller can be moved to `frontend`. Finally there are static files such as humans.txt (which can be moved to an idiomatic controller in `frontend`), and the Google/Bing verification files (which can be handled directly by nginx, configured in [govuk-helm-charts nginx config](https://github.com/alphagov/govuk-helm-charts/blob/45e9d22a25aa332e9a9449e2f671aebf1d667969/charts/app-config/templates/router-nginx-config.tpl#L184-L206)

### Error Pages (move to `frontend`)

Currently error pages are rendered by `static` during a deploy rake task, and uploaded to an S3 bucket.. We propose moving the error page templates into the `frontend` app - this seems  seems like the natural host, since [RFC-175] proposes merging a number of the other frontend apps into that.

### Layouts (call directly within apps)
All of the layouts in `static` are banner-aware configuration wrappers around a call to the public layout component included in the `govuk_publishing_components` gem. In practise this means that applications are having to make network calls to ask another application to return them a layout that they already have access to, and could easily configure themselves if necessary.

We propose that we move the layout calls to inside the frontend apps, determine if the additional configuration is something that can be provided in a default load-time step and explicitly overridden by the applications. This should give us more flexibility in terms of personalisation.

### Additional Considerations

Adding a gem to every frontend app may mean that frontend development may become more awkward in situations where local versions of multiple gems are needed. These are likely to be few, but we should be prepared to monitor the developer experience in these situations. Hopefully, though, the clear division of purpose between the banner gem and the components gem should mean that most work can be done with at most one local gem.

If we move components into the gem (one definite example is the global banner, which is currently an app component in static), we will try to ensure that the component guide from the gem treats them the same way it does in-app components, and we do not have to replicate the component guide code inside the gem.

## Proposed Roadmap

There are three initial streams, reflecting the fact that the gem could potentially be worked on independently. The work in each stream is arranged so that even if we don’t take the ultimate step, we’ll still be doing useful work. After these streams are complete, a final stream of work can retire `static`.

### Stream 1: Banner Gem
- Create prototype banner gem.
- Moving the recruitment banners into that gem, trial including them in one of the four apps which currently contain recruitment banner code.
- If trial looks promising, move the other three apps to use the gem.
- Move the emergency banner code into the gem, and include the gem in `static`
- Move current global banner code code into the gem, and use that code in `static`
- Convert the global banner code to use the same Redis system that the emergency banner uses.

### Stream 2: Static Content and error pages
- Trial moving static's error page content into the `frontend` app and to render/upload them in the same way `static` does now.
- Trial moving static's assets and redirects into into the `frontend` app to compile them into the shared asset bucket, and add task to special route publisher where necessary
- Add a second app to the trial, to ensure that the shared assets / error pages can still be served.

### Stream 3: Layouts in Apps
- Trial modifying an app ([email-alert-frontend], because it has one of the most complicated current uses of static layouts) to use the layouts directly (this would be partially reliant on Stream 1 for production-readiness, because it would need banner gem support for banners, but the trial can start independently)
- Modify the rest of the apps.

### Final Stream: Retire static

- Trial a single app with both the layout in-app, and the banner gem.
- If trial is successful, move remaining apps to the new system.
- Ensure that frontend is now handling all the static content and error pages
- Retire `static`/`slimmer`

## When would the `govuk_web_banner` gem be retired, and when would it change?

It's worth adding a little bit about what the predicted lifespan of the gem would be, so that we have a clear idea of when it would make sense to retire, merge, or add to it.

The banner gem is useful as long as there are multiple front-end apps that need to render the various banners. At the moment this is _all_ frontend apps for the emergency and global banners, and a subset for the recruitment banners. If that subset (or all) of the frontend apps were merged, we should consider whether to move the gem into that combined app.

It's also worth noting that the components used by this gem are _only_ used by this gem at the moment. If we think that is likely to be the case forever, we could move them into this gem and out of `govuk_publishing_components`, but only if (as noted above) we can include gem components in the existing component guide without repeating it.

[content-store]: https://github.com/alphagov/content-store
[email-alert-frontend]: https://github.com/alphagov/email-alert-frontend
[frontend]: https://github.com/alphagov/frontend
[government-frontend]: https://github.com/alphagov/government-frontend
[govuk_publishing_components]: https://github.com/alphagov/govuk_publishing_components
[slimmer]: https://github.com/alphagov/slimmer
[special-route-publisher]: https://github.com/alphagov/special-route-publisher
[static]: https://github.com/alphagov/static
[whitehall]: https://github.com/alphagov/whitehall
[removing a voter id banner]: https://github.com/alphagov/static/pull/3369
[RFC-84]: https://github.com/alphagov/govuk-rfcs/pull/84
[RFC-144]: https://github.com/alphagov/govuk-rfcs/pull/144
[RFC-174]: https://github.com/alphagov/govuk-rfcs/pull/174
[RFC-175]: https://github.com/alphagov/govuk-rfcs/pull/175
