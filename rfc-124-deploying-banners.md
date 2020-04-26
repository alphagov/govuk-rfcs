# Use Edge Side Include (ESI) to deploy banners on GOV.UK

## Summary

Using Edge Side Include (ESI) to deploy banners on GOV.UK will help us move away from `static`/`slimmer` while being able to roll out changes quickly.

## Background
A few types of site-wide banners can be activated to convey important information on GOV.UK.

### Emergency banner
The information for the emergency banner is [stored in Redis](https://github.com/alphagov/static/blob/998d94e1e1c70dabbe86384f565966acc8ef5110/lib/emergency_banner/deploy.rb#L4). [`Static`](https://github.com/alphagov/static/blob/master/app/views/notifications/_emergency_banner.html.erb) is responsible for displaying the information. We use Jenkins to run [rake tasks in `static`](https://github.com/alphagov/static/blob/master/lib/tasks/emergency_banner.rake) to set or delete the appropriate hash in Redis.

### Non-emergency banner
The information for the non-emergency banner is [hardcoded in a view in `static`](https://github.com/alphagov/static/blob/master/app/views/notifications/_global_bar.html.erb#L2-L11). To update this information and show or hide the banner a new pull request must be created with the changes, merged to master, then deployed across all environments. A list with the pages where the banner should not be displayed is [hardcoded in the JavaScript that initialises the banner](https://github.com/alphagov/static/blob/master/app/assets/javascripts/global-bar-init.js#L27-L39). This banner has [a mechanism based on cookies to show the banner only a certain number of times](https://github.com/alphagov/static/blob/d900b5be5b6176ce66008f6bc368908cd0cda5e3/app/assets/javascripts/modules/global-bar.js#L62-L70).

### Cookies banner
The information for the [cookie banner is in the shared components library](https://components.publishing.service.gov.uk/component-guide/cookie_banner). To update the information consistently across the public-facing applications in GOV.UK, a new pull request in the components library must be created with the changes, merged to master then publish a new release of the components library. All the public-facing applications need to be updated to use the latest version of the components library. This update must be deployed across all environments for each application.

![The current mechanism for deploying banners on GOV.UK](https://docs.google.com/drawings/d/e/2PACX-1vS-vz5bPpGAOhATHYH6hqY5BSR_T-JPSJkuGeneuZKe6Ae8Z4vShcPw-5Im9_OESK1zapFUZX4gNoX4/pub?w=1504&amp;h=909)

The current mechanism for deploying banners on GOV.UK – [view source](https://docs.google.com/drawings/d/1XgSskX5Ufb6BU_PiaIvAHsj7bTARMMgmWlkfOf3f_uA/edit)

## Problem

The recent events – such as making the cookie banner Privacy and Electronic Communications Regulations (PECR) compliant or showing important information related to Brexit and more recently COVID-19 – have made us more aware about the importance of being able to deploy banners quickly and with confidence without overloading our infrastructure. As described in the previous section, the process for deploying banners on GOV.UK is not consistent and has a certain degree of complexity depending on the banner type.

Moving away from `static`/`slimmer` towards a fully component-based architecture makes the process or rolling out a change across all applications more difficult.

## Proposal

Use Edge Side Include (ESI) to deploy banners on GOV.UK.

Edge Side Include (ESI) is a [web standard](https://www.w3.org/TR/esi-lang) originally proposed by Akamai and Oracle, among other companies. It allows an Edge Server (like [Fastly’s caches](https://www.fastly.com/blog/using-esi-part-1-simple-edge-side-include)) to "mix and match" content from multiple URLs.

In practice, the emergency banner on GOV.UK, for example, will require the following changes:

1. make the emergency banner available as a fragment (e.g. on `/emergency-banner`); this should be hosted on a frontend server, potentially served by a new application called `banners`, similarly with the other public-facing application
1. add an ESI include tag (pointing to the fragment) in the application layout
```
  <esi:include src="/emergency-banner" />
```
1. add an ESI remove tag and ESI comment to provide a fallback on environments where ESI is not available
```
  <esi:remove>
    <%= render "/components/emergency_banner" %>
  </esi:remove>
  <!--esi
  <esi:include src="/emergency-banner" />
  -->
```
1. enable ESI in Fastly via Varnish Configuration Language (VCL)
1. optional: add extra logic in VCL. Fastly gives us the ability to create custom responses at the edge – called "synthetics" in Varnish terminology – which can be used to include personalised, dynamic information that will be served from the edge instead of origin

### Pros
- performance gains (a higher cache-hit ratio, quicker page loads, less traffic spikes)
- the include fragment will have its own URL and thus independent VCL logic and caching TTLs
- due to the above, fragments can be purged independently of the main HTML content – this allows banners to roll-out instantly without having to drop the cache of all public-facing applications in GOV.UK
- ESI remove can be used to store fallback HTML content (which could be the rendered banner component) and therefore make local development easier and more consistent with production

### Cons
- origin must serve top-level page HTML as an uncompressed response (or support content-encoding negotiation) in order for Varnish to be able to do streaming ESI replacement
- it is also not possible for Varnish to compress the response after ESI processing. Fortunately Fastly has a workaround for this which forces H2O (Fastly’s HTTP terminator and HTTP/2-3 server) to do the streaming compression (which supports both `gzip` and `brotli`). This can easily be enabled via a HTTP response header which is subsequently stripped by H2O. However, as Fastly bills from bytes out of Varnish this would result in you getting billed for the uncompressed bytes instead of the compressed version. We are on a flat fee plan and thus this should not be an issue
- if ESI is not implemented correctly can make us vulnerable to different attacks (SSRF and XSS)

What a consistent mechanism to update banners would look like:
- content changes and enabling/disabling banners should be done in `banners`. This can be initially done through code changes, YAML configuration or rake tasks (similar to the current process for the emergency banner) then potentially improved to be powered by an admin interface.
- design and functional changes should be done in `govuk_publishing_components`, as for the rest of the UI components. A new version of the gem must be released then `banners` updated and deployed across all environments.

![The proposed mechanism for deploying banners on GOV.UK](https://docs.google.com/drawings/d/e/2PACX-1vRRMbxkghxpS_SHB706QfcM2M9vwQZZ--bzMxr17Fj1k_GJ7Z_rCoLqba9tJQqEXH2VTPyrxNh_W4rR/pub?w=1503&amp;h=908)

The proposed mechanism for deploying banners on GOV.UK – [view source](https://docs.google.com/drawings/d/1S9VaY6jjpFo3QWQ4CJ4fhSwpWn12BNqunXhT27JdDAY/edit)


### References
- [Edge Side Includes (ESI) standard](https://www.w3.org/TR/esi-lang)
- [Fastly documentation on ESI configuration](https://docs.fastly.com/en/guides/using-edge-side-includes)
- [GOV.UK’s emergency banner](https://docs.publishing.service.gov.uk/manual/emergency-publishing.html)
- [GOV.UK’s non-emergency banner](https://docs.publishing.service.gov.uk/manual/global-banner.html)
- [RFC 84: Replace `static` by a gem](https://github.com/alphagov/govuk-rfcs/blob/bc8ffe85cdf5cdf5005502cba50d5b64237f1b71/rfc-084-frontend-in-a-gem.md)
- [RFC 95: Long term future of applications](https://github.com/alphagov/govuk-rfcs/blob/master/rfc-095-long-term-future-apps.md)
- [RFC 118: Storing global content in `content-store`](https://github.com/alphagov/govuk-rfcs/pull/118/files?short_path=e726d76#diff-e726d76080573a2313d111b44a90f38d)
