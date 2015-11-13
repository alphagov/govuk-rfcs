## Problem

In the JSON schemas we use to send data between our systems, we've traditionally tried to treat the `details` part of the payload as entirely opaque (eg no special knowledge should be required of anything between the publishing tool sending and the frontend rendering the payload).

The reality is that in the [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas) repository, almost all formats have required fields in the details hash. Examples:

- [case studies](https://github.com/alphagov/govuk-content-schemas/blob/b02afaac06ddd965e114b3ff577faf1952c628e0/formats/case_study/publisher/details.json)
- [finders](https://github.com/alphagov/govuk-content-schemas/blob/b02afaac06ddd965e114b3ff577faf1952c628e0/formats/finder/publisher/details.json)
- [specialist documents](https://github.com/alphagov/govuk-content-schemas/blob/b02afaac06ddd965e114b3ff577faf1952c628e0/formats/specialist_document/publisher/details.json)

All these required fields are for the rendering apps to have enough data to fulfil the business logic required of the format.

In order to provide bespoke validation of the schemas within the publishing API, we need to inspect the JSON payloads and validate them using JSON schema. We may also want to provide additional parsing (eg a future dependency resolver will want to know which fields are&nbsp;`govspeak`&nbsp;vs plain text in order to rewrite links and dependencies, or when attachments get out of virus scanning).

## Proposal

Therefore we propose to no longer treat the `details`&nbsp;part of the payload as entirely opaque, but instead allow for inspection and enhancement when required of the format.

This requires no work as we're already doing this in code in some places - but we would change our expectations about certain fields (eg datetime fields, govspeak fields, attachments).

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

