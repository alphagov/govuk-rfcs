## Problem

Recently the publishing-api&nbsp;has begun to validate incoming payloads against the [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas).

How it works now:

- The schemas are manually "deployed" using a [task in Jenkins](https://deploy.integration.publishing.service.gov.uk/job/Deploy_GOVUK_Content_Schemas/) that [copies](https://github.com/alphagov/govuk-content-schemas/blob/master/deploy.sh) over the schemas to the publishing-api
- Pull requests on&nbsp;publishing apps are tested against the master branch of govuk-content-schemas ([example](https://github.com/alphagov/calendars/blob/51a9583b4de80aeca53c9f3762f6412c24a3c951/jenkins.sh#L45))
- Pull requests on&nbsp;govuk-content-schemas are tested against the master branch of the downstream applications ([example](https://ci.dev.publishing.service.gov.uk/job/govuk_business_support_finder_schema_tests/configure))

This opens up two issues that could cause the publishing-api to reject valid content, causing errors or delays for editors.

**1) Undeployed changes in schemas**

Example:

- You add a field to govuk-content-schemas, but don't deploy
- You add the field to the content item payload in the publisher application. The PR will be green because the new payload is valid to the content schema on master
- PR gets merged and deployed
- Now the app will fail on production because publishing-api&nbsp;doesn't know about your new attribute yet

**2) Making schema changes with undeployed apps**

Example:

- You want to remove an attribute from govuk-content-schemas. You remove it from the payload in the publisher application.&nbsp;
- The PR is merged, but the application is not yet deployed to production.
- Raise a PR on content-schemas to remove the payload. Downstream apps pass because the publisher app master isn't sending the attribute anymore.
- When you deploy govuk-content-schemas the publisher app will be sending invalid content.

## Proposal

This RFC proposes:&nbsp;

- Application tests are to be run against the **deployed** &nbsp;version of govuk-content-schemas
- Pull requests on govuk-content-schemas are to be tested against the **deployed** version of the downstream applications
- The govuk-content-schemas repo is to be **automatically deployed** from master for all environments

The diagram below attempts to illustrate workflow for changes to the schemas:

