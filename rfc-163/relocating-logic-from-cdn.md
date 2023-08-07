# Appendix: Proposal for relocating logic from the CDN layer to other parts of the stack

Things that could be moved to WAF:

- IP allowlisting on staging and production EKS[^ip-allowlist]
- Requiring HTTP Basic auth on integration[^http-basic-1][^http-basic-2] (unless the user's IP is in the allowlist[^http-basic-allowlist])
- IP denylisting[^ip-denylist]
  - This functionality is currently unused (the dictionary that the denylist is read from is empty), but it exists in case we ever need to quickly block IP addresses (for example, during an incident).
- Silently ignore certain requests[^drop-requests-1][^drop-requests-2]
  - This was the outcome of an [incident report](https://docs.google.com/document/d/12DzQsDeu7zUcICy9zVporjprX4qZFIrpOOWtYYRx-nk/edit) - details cannot be provided here, as this is a public repo
- Serving an HTTP 404 response with a hardcoded template[^autodiscover-template] if the request URL matches `/autodiscover/autodiscover.xml`[^autodiscover-matcher]
  - Context: https://github.com/alphagov/govuk-cdn-config/pull/86
  - Blocking this from our WAF would remove the hardcoded page template, but no users are likely to visit this URL anyway

[^ip-allowlist]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L182-L187
[^http-basic-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L202-L207
[^http-basic-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L614-L620
[^http-basic-allowlist]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L154-L165
[^ip-denylist]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L189-L192
[^drop-requests-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L223
[^drop-requests-2]: https://github.com/alphagov/govuk-cdn-config-secrets/blob/536de2171d17297c08a0a328df53a6b65002e2c4/fastly/fastly.yaml#L30-L39
[^autodiscover-template]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L579-L603
[^autodiscover-matcher]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L226-L228

Things that could be implemented via Router:

- Redirecting `/security.txt` and `/.well-known/security.txt` to `https://vdp.cabinetoffice.gov.uk/.well-known/security.txt`[^redirect-security-txt-1][^redirect-security-txt-2]
  - We could set up an HTTP 301 redirect using Router instead; CDNs and browsers should cache HTTP 301 responses

[^redirect-security-txt-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L231-L233
[^redirect-security-txt-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L606-L612

Things that could be implemented in our applications:

- Setting feature flags, such as showing recommended related links for Whitehall content[^whitehall-recommended-links]
  - On the old platform it was necessary to implement these flags in the CDN layer to prevent the need to deploy a new release every time we wanted to enable/disable a feature. A header is set on the backend request to indicate to the application whether the feature is enabled or disabled.
  - In the replatformed world, this becomes a lot easier: we can implement feature flags through environment variables (as opposed to headers), and then enabling or disabling the feature becomes a matter of [updating the environment variables in `govuk-helm-charts`](https://govuk-kubernetes-cluster-user-docs.publishing.service.gov.uk/manage-app/set-env-var/#update-an-ordinary-non-secret-environment-variable) and waiting a couple of minutes for Argo to pick up the changes.
  - We will also need to [update the docs](https://docs.publishing.service.gov.uk/manual/related-links.html#suspending-all-suggested-related-links)

[^whitehall-recommended-links]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L251

Things that need to remain in our CDN (but become easier to implement/maintain if we later migrate to Compute@Edge):

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
- JA3 denylisting[^ja3-1][^ja3-2]
  - Ideally this would be handled by our WAF, but AWS WAF does not currently support it ([though it _is_ supported on CloudFront](https://aws.amazon.com/about-aws/whats-new/2022/11/amazon-cloudfront-supports-ja3-fingerprint-headers/), so it's possible that WAF will get it at some point in the future)

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

Things that need to stay in VCL for now, but will become unnecessary if we later move to Compute@Edge:

- Explicitly marking HTTP 307 responses from origin as cacheable[^http-307-caching]
  - Fastly VCL is built on an old version of Varnish which didn't do this by default; if we migrate to Compute@Edge then we shouldn't need this anymore
- Enabling Brotli compression[^brotli-1][^brotli-2]
  - From [the description](https://github.com/alphagov/govuk-cdn-config/commit/b60833af17de971c6780207d0f08b9e13993d0cd) of the commit that introduced this change, this appears to be a workaround for a limitation in VCL - if that's not the case, we can port this over to Compute@Edge

[^http-307-caching]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L459-L461
[^brotli-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L329-L333
[^brotli-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L388-L402

Things that we could probably remove:

- Enforcing the use of TLS[^force-tls-1][^force-tls-2]
  - Origin already performs an HTTP 301 redirect to the TLS version of the site. Browsers and CDNs should cache this response.

[^force-tls-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L218-L220
[^force-tls-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L561-L568

Known issues with our current config that could be addressed more easily if we move to Compute@Edge:

- Currently if origin returns an HTTP 500, and we failover to the S3 mirror, but the requested path is not present in the mirror, the user receives an HTTP 403 and a very ugly XML-based error page
  - This is expected behaviour: S3 returns a 403 if the file is missing and the access key that was used to make the request does not have the `s3:ListBucket` permission
  - The fix is to intercept HTTP 403 responses _only from the S3 backend_, and replace them with a hardcoded error page - much easier to implement in Compute@Edge than in VCL

Undecided/needs input from other developers:

- GOV.UK accounts: Mapping from headers to cookies and back[^accounts-1][^accounts-2][^accounts-3]
  - This is described in more detail in [RFC-134](https://github.com/alphagov/govuk-rfcs/blob/main/rfc-134-govuk-wide-session-cookie-and-login.md), and the discussion on [the associated PR](https://github.com/alphagov/govuk-rfcs/pull/134)
  - Code exists in our VCL to map between a cookie named `__Host-govuk_account_session` in user requests/responses, and the `GOVUK-Account-Session` and `GOVUK-Account-End-Session` headers in backend requests/responses, and to control the cache behaviour of these requests/responses
  - We might instead be able to pass the cookie through to origin, but that would go against established precedent of stripping all cookies. Undecided whether or not this is a good idea.
- A/B testing[^ab-1][^ab-2]

[^accounts-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L504-L522
[^accounts-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L350-L361
[^accounts-3]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L488-L492
[^ab-1]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/www.vcl.erb#L524-L555
[^ab-2]: https://github.com/alphagov/govuk-cdn-config/blob/55e587b238338caea1c7187c1f5d70cac8e5b104/vcl_templates/_multivariate_tests.vcl.erb
