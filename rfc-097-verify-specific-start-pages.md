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

Any customised content is designed to be solely reachable, indirectly via the hub, using hyperlinks IDPs publish to their users.

Therefore the new content MUST not be indexed and reachable by performing, for example, a Google search or GOV.UK search. 

#### Content Schema

The GOV.UK content schema used for service start pages is the `transaction` schema, the changes proposed will require changes to this schema which will, potentially, require changes to be made to existing data that conforms to this schema.

## Proposal
  
The solution would be for GOV.UK to support 'variants' of content in the transaction content schema. This should allow a variant of the page to be requested in the URL, as shown, `http://www.gov.uk/<base_url>/<variant-name>`. For example, `http://www.gov.uk/my-rp-transaction-page/verify`.

This would require multiple changes to GOV.UK including schemas, publisher and government frontend.

Publisher already supports the concept of a 'parted' content item, so the publisher app should be modified to add the 'parted' functionality to the transaction editor. Corresponding changes would also need to be made to the `transaction` content schema to ensure that the publishing API accepts multiple parts. Government frontend would also have to be modified to render the pages correctly.

#### Searching

Even though the new alternate parts will not be linked from anywhere, it should not be discoverable by crawlers, GOV.UK does publish a `sitemap.xml`. We need to ensure the variant pages include the `ROBOTS` meta tag with a `NOINDEX` value.

This will be achieved by allowing a variant/part to be flagged with a "Exclude from Index" option. If present on a variant, when Government frontend renders the page it should include the NOINDEX value in the ROBOTS meta tag.

