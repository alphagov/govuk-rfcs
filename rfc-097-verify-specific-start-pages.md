# Providing alternative GOV.UK service start pages for the GOV.UK Verify single IDP journey

## Summary

This document describes an approach for providing alternative service start pages 
that will be displayed to users on a GOV.UK Verify single IDP journey.

## Terms

* IDP - Identity Provider (also known as a Certified Company)
* RP - Relying Party (also known as a transaction or service, e.g. view your driving license or check your state pension)

## Problem

We have recently introduced a new type of journey to Verify. This journey type allows Identity Providers (IDPs) to target their existing customers in order to drive customers into using their identity service with GOV.UK services. Unlike traditional Verify journeys, the user will actually start on a page at, or an e-mail from, a specific IDP where they will choose which service to use. During this journey Verify restricts their ability to choose an alternative IDP. This is know as the Single IDP journey and is described in Verify [RFC-041](https://github.com/alphagov/verify-architecture/blob/master/rfcs/rfc-041-single-idp-journey.md).

When following a single IDP journey, the user needs to be redirected via the RP (service) in order to pick up a valid SAML request. Initial thoughts were to direct the RP headless start page, which generates the SAML request and results in an immediate redirect back to the Verify hub.
This approach, however, is not desirable as there is often important information given to the
user on the service's normal start page. Similarly, showing the normal start page is not
desirable as it may give service sign-in options that would direct the user away from Verify and the
user's chosen IDP (for example, if the user chooses to login with Government Gateway).

The approach described in this document is to implement alternate service start pages, that
will display all important information to the user but only give them the option of using
Verify and, hence, their chosen IDP. 

### Considerations

#### Discoverability

Any customised content is designed to be reachable solely via hyperlinks from IDPs, which will redirect via the Verify hub.
Therefore the new content MUST not be indexed and reachable by performing, for example, a Google search or GOV.UK search. 


#### Content Schemas

There are two GOV.UK content schemas used for service start pages. Most services use the `transaction` schema but some use the 
`guide` schema. Any solution MUST work for, at least, both these content schemas.


## Proposal

### Short term/interim solution - Alternate Content

In the short term, and in the interests of getting up and running quickly, we can simply take a copy of the existing content in
GOV.UK's content publisher service, alter it, and publish it with a different URL slug (as specified in the `base_url` property 
of the content item. A suggestion would be to append `-verify` to the the end of the existing slug.

For example:
```
// Original Content Item
{
    "analytics_identifier": null,
    "base_path": "/my-rp-transaction-page",
    "content_id": "abcd1234-5678-90ab-cdef-0123456789ab",
    ...
}
```

```
// Alternate Content Item
{
    "analytics_identifier": null,
    "base_path": "/my-rp-transaction-page-verify",
    "content_id": "abcd1234-5678-90ab-cdef-abcdef123456",
    ...
}
```

[**needs confirmation**] This solution works well for `transaction` content schema, and looks like it should work with `guide` although more care will 
need to be taken the latter to ensure all slugs are updated and any explicit hyperlinks updated also.

#### Searching
 
[**for discussion**] The GOV.UK team state there is an existing method for ensuring that these alternate content pages are not searchable
within the GOV.UK website, a change will need to be implemented on GOV.UK to ensure the these pages are not indexable by 
search engine web crawlers. Even though the new alternate content will not be linked from anywhere, so would not be discoverable by crawlers, 
GOV.UK does publish a `sitemap.xml`. We need to ensure these alternate content pages are not published in `sitemap.xml` and/or include the
 `ROBOTS` meta tag with a `NOINDEX` value.
 
### Long term solution - Content Variations

A long term solution would be for GOV.UK to support 'variants' of content in the content schemas. This should allow a variant of
the page to be requested in the URL, for example, `http://www.gov.uk/<base_url>/<variant-name>`

For example, `http://www.gov.uk/my-rp-transaction-page/verify`.

An example of how the content schema for `transaction` could be updated is shown here:

```
{
  // Existing
  ...
  "details": {
    "introductory_paragraph": "<p>The services introduction</p>\n",
    "start_button_text": "Start now",
    "will_continue_on": "the RP start page",
    "transaction_start_link": "https://www.my-service.gov.uk/start",
    "more_information": "<p>Additional Info</p>\n",
    "external_related_links": [],
    "department_analytics_profile": ""
  }
  ...
}
```

```
{
  // Including a variant
  ...
  "details": {
    "introductory_paragraph": "<p>The services introduction</p>\n",
    "start_button_text": "Start now",
    "will_continue_on": "the interstitial sign-in page",
    "transaction_start_link": "https://www.gov.uk/my-rp-transaction-page-verify/service-sign-in",
    "more_information": "<p>Additional Info</p>\n",
    "external_related_links": [],
    "department_analytics_profile": ""
  },
  "variants": {
    "verify": {
      "details": {
        "introductory_paragraph": "<p>The services alternative introduction</p>\n",
        "start_button_text": "Start now",
        "will_continue_on": "the RP's verify start page",
        "transaction_start_link": "https://www.my-service.gov.uk/start",
        "more_information": "<p>Additional Info</p>\n",
        "external_related_links": [],
        "department_analytics_profile": ""
      }    
    }
  }
  ...
}
```
[**for discussion**] This would require multiple changes to GOV.UK including schemas, publisher, content service and front end.

#### Searching

This solution SHOULD not add the variants to any search indexes or to `sitemap.xml`. This will mean that the variants are not searchable unless
someone were to add an explicit link to a variant into a searchable page.
