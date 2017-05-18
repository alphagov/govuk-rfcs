## Problem

Recently the publishing-api has begun to validate incoming payloads against the
[govuk-content-schemas][].

How it works now:

- The schemas are manually "deployed" using a [task in Jenkins][jenkins-task]
  that [copies][deploy-script] over the schemas to the publishing-api
- Pull requests on publishing apps are tested against the master branch of
  govuk-content-schemas ([example][example-1])
- Pull requests on govuk-content-schemas are tested against the master branch
  of the downstream applications ([example][example-2])

[govuk-content-schemas]: https://github.com/alphagov/govuk-content-schemas
[jenkins-task]: https://deploy.integration.publishing.service.gov.uk/job/Deploy_GOVUK_Content_Schemas/
[deploy-script]: https://github.com/alphagov/govuk-content-schemas/blob/master/deploy.sh
[example-1]: https://github.com/alphagov/calendars/blob/51a9583b4de80aeca53c9f3762f6412c24a3c951/jenkins.sh#L45
[example-2]: https://ci.dev.publishing.service.gov.uk/job/govuk_business_support_finder_schema_tests/configure

This opens up two issues that could cause the publishing-api to reject valid
content, causing errors or delays for editors.

### 1. Undeployed changes in schemas

Example:

- You add a field to govuk-content-schemas, but don't deploy
- You add the field to the content item payload in the publisher application.
  The PR will be green because the new payload is valid to the content schema
  on master
- PR gets merged and deployed
- Now the app will fail on production because publishing-api doesn't know about
  your new attribute yet

### 2. Making schema changes with undeployed apps

Example:

- You want to remove an attribute from govuk-content-schemas. You remove it
  from the payload in the publisher application. 
- The PR is merged, but the application is not yet deployed to production.
- Raise a PR on content-schemas to remove the payload. Downstream apps pass
  because the publisher app master isn't sending the attribute anymore.
- When you deploy govuk-content-schemas the publisher app will be sending
  invalid content.

## Proposal

This RFC proposes:

- Application tests are to be run against the **deployed** version of
  govuk-content-schemas
- Pull requests on govuk-content-schemas are to be tested against the
  **deployed** version of the downstream applications

The scenarios above now can't happen:

### 1. Undeployed changes in schemas

Example:

- You add a field to govuk-content-schemas, but don't deploy
- You add the field to the content item payload in the publisher application.
  The PR will **not pass** because the new payload is invalid against the
  released-to-production branch of content-schemas

### 2. Making schema changes with undeployed apps

Example:

- You want to remove an attribute from govuk-content-schemas. You remove it
  from the payload in the publisher application. 
- The PR is merged, but the application is not yet deployed to production.
- Raise a PR on content-schemas to remove the payload. Downstream apps **do not
  pass** because the publisher app still has the attribute in
  released-to-production

Because we don't deploy automatically to production, there's a situation that
will cause a PR to get merged that will fail on production:

1. Add an attribute to govuk-content-schemas. Merge the PR & deploy to
   production.
2. Raise PR to send this attribute from the publisher application. Your tests
   pass (because it's testing against released-to-production schemas)
3. Merge the PR on the publisher application (but do not deploy)
4. Now raise a PR to remove attribute from content schemas. Because the change
   hasn't been deployed the tests pass **will pass**. Merge it.
5. If you deploy the PR on the publisher application now, the publisher app
   will start sending invalid data to the publishing-api and fail

To illustrate how schema changes take place, [we've made some diagrams
describing the process][diagrams].

[diagrams]: https://gov-uk.atlassian.net/wiki/display/GOVUK/Illustration+of+schema+development+workflow
