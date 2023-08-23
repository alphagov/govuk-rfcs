# Appendix: Proposal for relocating logic from the CDN layer to other parts of the stack

Things that could be moved to WAF:

- Silently ignore certain requests[^drop-requests-1][^drop-requests-2]
  - This was the outcome of an [incident report](https://docs.google.com/document/d/12DzQsDeu7zUcICy9zVporjprX4qZFIrpOOWtYYRx-nk/edit) - details cannot be provided here, as this is a public repo
- Serving an HTTP 404 response with a hardcoded template[^autodiscover-template] if the request URL matches `/autodiscover/autodiscover.xml`[^autodiscover-matcher]
  - Context: https://github.com/alphagov/govuk-cdn-config/pull/86
- Redirecting `/security.txt` and `/.well-known/security.txt` to `https://vdp.cabinetoffice.gov.uk/.well-known/security.txt`[^redirect-security-txt-1][^redirect-security-txt-2]
  - This one might be a stretch - while we _could_ implement this via WAF, it's not the kind of behaviour that you'd typically associate with a firewall
- Requiring HTTP Basic auth on integration[^http-basic-1][^http-basic-2] (unless the user's IP is in the allowlist[^http-basic-allowlist])
  - If we handle this in the WAF then we will need to be careful around caching. We might be able to do something like setting `Vary: Authorization` in the response from the WAF, and additionally set `Vary: Fastly-Client-IP` if and only if the `Authorization` header is missing
  - Will need to spike this approach to see if it's actually easier than handling at edge

[^drop-requests-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L223
[^drop-requests-2]: https://github.com/alphagov/govuk-cdn-config-secrets/blob/536de2171d17297c08a0a328df53a6b65002e2c4/fastly/fastly.yaml#L30-L39
[^autodiscover-template]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L579-L603
[^autodiscover-matcher]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L226-L228
[^redirect-security-txt-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L231-L233
[^redirect-security-txt-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L606-L612
[^http-basic-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L202-L207
[^http-basic-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L614-L620
[^http-basic-allowlist]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L154-L165

Things that we could probably remove:

- Feature flag for showing recommended related links for Whitehall content[^whitehall-recommended-links]
  - This was added as a safety mechanism for the introduction of related links, in case something really inappropriate was found. There are ways to manually override the links now, and we've never used the feature flag, so we can probably remove it now.
  - If we remove this functionality then we will also need to [update the docs](https://docs.publishing.service.gov.uk/manual/related-links.html#suspending-all-suggested-related-links).
  - Regarding feature flags as a general concept:
    - On the old platform it was necessary to implement these flags in the CDN layer to prevent the need to deploy a new release every time we wanted to enable/disable a feature. A header is set on the backend request to indicate to the application whether the feature is enabled or disabled.
    - In the replatformed world, this becomes a lot easier: we can implement feature flags through environment variables (as opposed to headers), and then enabling or disabling the feature becomes a matter of [updating the environment variables in `govuk-helm-charts`](https://govuk-kubernetes-cluster-user-docs.publishing.service.gov.uk/manage-app/set-env-var/#update-an-ordinary-non-secret-environment-variable) and waiting a couple of minutes for Argo to pick up the changes.
- Pre-replatforming EKS things
  - While our EKS cluster was still being tested we maintained two separate services for each environment (a "live" service pointed at our old EC2 infrastructure, and an access-controlled EKS service pointed at the new cluster)
  - The EKS service definitions are now symlinks for the main VCL definitions, but the WWW service template still contains EKS-related conditionals[^eks-1][^eks-2] and references to the traffic split experiment[^eks-traffic-split]
  - Now that replatforming is complete, we should clean up this leftover logic
- Enforcing the use of TLS[^force-tls-1][^force-tls-2]
  - Origin already performs an HTTP 301 redirect to the TLS version of the site. Browsers and CDNs should cache this response.

[^force-tls-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L218-L220
[^force-tls-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L561-L568
[^whitehall-recommended-links]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L251
[^eks-1]: https://github.com/alphagov/govuk-cdn-config/blob/main/vcl_templates/www.vcl.erb#L154
[^eks-2]: https://github.com/alphagov/govuk-cdn-config/blob/main/vcl_templates/www.vcl.erb#L182
[^eks-traffic-split]: https://github.com/alphagov/govuk-cdn-config/blob/main/vcl_templates/www.vcl.erb#L243

Things that need to remain in our CDN (but become easier to implement/maintain if we later migrate to Compute@Edge):

- IP denylisting[^ip-denylist] (this must happen at the CDN layer, where caching takes place)
  - This functionality is currently unused (the dictionary that the denylist is read from is empty), but it exists in case we ever need to quickly block IP addresses (for example, during an incident).
- JA3 denylisting[^ja3-1][^ja3-2]
  - The JA3 fingerprint is computed from the TLS handshake, meaning it has to be computed at the node to which the client's TLS connection is made (i.e. the CDN)
  - We _could_ compute the JA3 fingerprint at the CDN layer and pass it via a header to the WAF in which the actual blocking takes place, but this would have implications on caching and so probably isn't feasible
- Require authentication for Fastly `PURGE` requests[^purge-auth]
  - This doesn't need parity on Cloudfront
- Sorting query string params[^sort-query] and removing Google Analytics campaign params[^remove-utm] to improve cache hit rate
- Stripping query string params only for the homepage and `/alerts`[^remove-query]
  - This appears to be a DDoS prevention measure(?) - should we expand this protection to other routes?
- Automatic failover to static S3/GCS mirror if origin is unhealthy or returns an HTTP 5xx (only in staging and production - in integration we want to be able to see errors as they happen)[^mirror-failover]
- Stripping the `Accept-Encoding` header if the content is already compressed[^strip-accept-encoding]
  - Context: https://github.com/alphagov/govuk-cdn-config/pull/379
  - [Fastly already normalises the `Accept-Encoding` header](https://developer.fastly.com/reference/http/http-headers/Accept-Encoding/#normalization), but it doesn't automatically remove it if the requested content is already compressed
- Controlling cache behaviour based on the `Cache-Control` header returned by origin[^cache-control]
  - Manually set `Fastly-Cachetype` to `PRIVATE` if `Cache-Control: Private`[^cache-control-private]
  - Explicit `pass` if `Cache-Control: max-age=0`[^cache-control-max-age]
  - Explicitly `pass` if `Cache-Control: no-(store|cache)`[^cache-control-no-store]
  - It is unclear which (if any) of these remain necessary if we decide to move to Compute@Edge (it's also unclear why Fastly doesn't respect them automatically 🤷‍♂️)
- Setting a request id header to allow requests to be traced through the stack[^request-id]
  - It's important to set this at the earliest opportunity, which is when we first receive the request (at edge)
- Mapping from headers to cookies and back
  - It is considered a [best practice](https://developer.fastly.com/reference/http/http-headers/Cookie/#best-practices) to strip cookies before forwarding the request to origin. For this reason our VCL contains logic to map from headers to cookies and back, to implement the following features:
    - GOV.UK accounts[^accounts-1][^accounts-2][^accounts-3]
      - This is described in more detail in [RFC-134](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-134-govuk-wide-session-cookie-and-login.md), and the discussion on [the associated PR](https://github.com/alphagov/govuk-rfcs/pull/134)
      - Code exists in our VCL to map between a cookie named `__Host-govuk_account_session` in user requests/responses, and the `GOVUK-Account-Session` and `GOVUK-Account-End-Session` headers in backend requests/responses, and to control the cache behaviour of these requests/responses
    - A/B testing[^ab-1][^ab-2]
      - Code exists in our VCL to select a variant for each active test, pass the chosen variant to origin, and store the chosen variant in a cookie so that the same variant will be chosen on the next request
  - This functionality needs to remain in the CDN layer, but becomes much easier to implement in Compute@Edge (details of this might follow in a future RFC).

[^ip-denylist]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L189-L192
[^purge-auth]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L171
[^sort-query]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L236
[^remove-utm]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L239
[^remove-query]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L256-L264
[^mirror-failover]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L266-L326
[^strip-accept-encoding]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L211-L215
[^cache-control]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L444-L455
[^cache-control-private]: https://github.com/alphagov/govuk-cdn-config/commit/03cb1fc5794658b89ed9f80ab5ca3c0b98a7afe7
[^cache-control-max-age]: https://github.com/alphagov/govuk-cdn-config/commit/54bf796f7c7543a893dbf14a8ca4fa1eae3253a1
[^cache-control-no-store]: https://github.com/alphagov/govuk-cdn-config/commit/fa56132e49d41595ba1681467adb828694cf0086
[^request-id]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L254
[^ja3-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L178-L180
[^ja3-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L195-L199
[^accounts-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L504-L522
[^accounts-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L350-L361
[^accounts-3]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L488-L492
[^ab-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L524-L555
[^ab-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/_multivariate_tests.vcl.erb

Things that need to stay in VCL for now, but will become unnecessary if we later move to Compute@Edge:

- Explicitly marking HTTP 307 responses from origin as cacheable[^http-307-caching]
  - Fastly VCL is built on an old version of Varnish which didn't do this by default; if we migrate to Compute@Edge then we shouldn't need this anymore
- Enabling Brotli compression[^brotli-1][^brotli-2]
  - From [the description](https://github.com/alphagov/govuk-cdn-config/commit/b60833af17de971c6780207d0f08b9e13993d0cd) of the commit that introduced this change, this appears to be a workaround for a limitation in VCL - if that's not the case, we can port this over to Compute@Edge

[^http-307-caching]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L459-L461
[^brotli-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L329-L333
[^brotli-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L388-L402

Known issues with our current config that could be addressed more easily if we move to Compute@Edge:

- Currently if origin returns an HTTP 500, and we failover to the S3 mirror, but the requested path is not present in the mirror, the user receives an HTTP 403 and a very ugly XML-based error page
  - This is expected behaviour: S3 returns a 403 if the file is missing and the access key that was used to make the request does not have the `s3:ListBucket` permission
  - The fix is to intercept HTTP 403 responses _only from the S3 backend_, and replace them with a hardcoded error page - much easier to implement in Compute@Edge than in VCL
