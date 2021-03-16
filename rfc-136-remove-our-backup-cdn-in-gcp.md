# Remove the backup CDN in Google Cloud Platform (GCP)

## Summary

We have two backup content delivery networks (CDNs), in case Fastly have an outage.
The first is AWS CloudFront, the second is Google Cloud CDN.

A simultaneous outage of both Fastly and AWS CloudFront is very unlikely. So
the Google Cloud CDN backup provides very little extra reliability.

The infrastructure cost of the Google Cloud CDN backup is negligible, but the
cost of maintaining it is significant (it's broken right now, and it would take
several weeks of engineering time to fix it).

The maintenance cost outweighs the expected reliability benefit, so we should
remove the Google Cloud CDN backup.

## Problem

GOV.UK's current business continuity plan aims to ensure that members of the
public can continue to use www.gov.uk, even in the event of a major outage in
one or more of our infrastructure providers.

Firstly, while our primary CDN (Fastly) is up, any failed requests to our origin servers
will be retried against three static mirrors - two in AWS, one in GCP.

* origin
* AWS S3
* AWS S3 (replica in a different region)
* Google Cloud Storage

If none of the above are successful, an error is served to the user.

Secondly, if our primary CDN (Fastly) is down, we have two backup CDNs which we
can manually fail over to (by updating a DNS record). AWS CloudFront and Google
Cloud CDN.

The mirroring approach works well. This RFC does not propose any change to the
mirrors, including the Google Cloud Storage mirror.

The AWS CloudFront CDN is reasonably easy to maintain and test, however the
Google Cloud CDN backup is significantly more difficult.

### Our Google Cloud CDN setup currently broken, and fixing it would be a lot of work

The certificate in use on the CDN expired in May 2020.

The Google Cloud Storage bucket the CDN is pointing to is currently private.
This means even if you ignore certificate warnings you'll see an access
denied error.

These issues could be fixed as part of the failover process, but we don't
have any documentation explaining how to do that.

Fixing the issues up front would require several weeks of engineering time. The
replatforming team have already spent a couple of weeks investigating. At the
moment the opportunity cost of prioritising fixing these issues over other
infrastructure work is unacceptable.

### It is difficult to issue a certificate for Google Cloud CDN

GCP provide managed certificates for their CDN, but these can only be issued
and renewed if the CDN is serving live traffic (i.e. www.gov.uk's [DNS A
records point to the CDN's IP](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#update-dns)).

This doesn't work for us because we need our DNS A records to be pointing at
Fastly for www.gov.uk to work properly.

We could issue certificates from a third party certificate provider (for
example GlobalSign or LetsEncrypt).

Previously we've used Gandi for this, however they've changed their policies
for domains like www.gov.uk. The only way Gandi can validate ownership is via
an email to `admin@www.gov.uk` (which we don't have set up).

It would be possible to automate certificate issuance using something like
[certbot](https://certbot.eff.org/), using either the ACME DNS or ACME HTTP
challenges. Doing this in a secure and reliable way would be a significant
piece of work.

We could delay issuing certificates to the point where we fail over (at which
point GCP could issue the certificate). That process would need to be
documented (and ideally practiced in a non-production environment).

### Our Google Cloud CDN setup is hard to test

Because we can't easily issue a certificate to use in Google Cloud CDN, and
because the underlying static mirrors are currently private, it's not possible
to test that the CDN actually works.

It would be possible to test the Google CDN, but only if we resolved the
other problems in this RFC.

The current situation with both our backup CDNs shows that processes which
are not tested are likely to break.

### A simultaneous outage for Fastly and AWS CloudFront is unlikely

Let's assume that there's a 0.01% chance that Fastly will be having a major
incident at any given point, and the same for AWS CloudFront. (Real world
reliability is much higher than this).

Let's also assume that major incidents with Fastly are independent from major
incidents with AWS CloudFront.

The chances of both CDNs having a major incident at the same time would be
`0.0001 × 0.0001 = 0.00000001` (so 0.000001%). That's maybe once in 10,000
years.

In practice there may be some situations where failures at Fastly and
CloudFront are not independent (for example global internet issues, natural
disasters, global thermonuclear war). Even in these situations, having the
Google Cloud CDN backup would not buy us much additional reliability, because
it's likely it would also be affected by any issue wide enough to affect
Fastly and AWS CloudFront.

## Proposal

GOV.UK should remove the backup Google Cloud CDN.

GOV.UK's business continuity plan should be updated to make it clear that there
is no formal plan in place to continue to serve traffic from www.gov.uk in the
event of a simultaneous outage of both Fastly and AWS CloudFront.

## Alternative option - fix the Google Cloud CDN

If GOV.UK decides not to remove the Google Cloud CDN backup, work needs to be
prioritised to fix it.

Doing this properly will take several weeks, and will include some
architectural decision making (for example, how do we issue a certificate for
this CDN?).

Currently no teams have capacity to do this work, but GOV.UK could decide to
prioritise this over other features. We do not recommend this as the
reliability value of a secondary backup CDN is low.
