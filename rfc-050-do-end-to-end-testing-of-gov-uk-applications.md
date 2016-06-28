&nbsp;

&nbsp;

---
status: "DRAFT"
notes: "Being written up"
---

## Background

We have almost finished migrating Specialist Publisher onto the Publishing Platform.

In doing so, we've written lots of tests that ensure the application meets its requirements.

The majority of our tests follow this pattern:

1. Stub external services to return a canned response
2. Perform some action in the publishing application
3. Assert that the correct requests were made to external services

## Problems

**Unable to test user-journeys**

Because we're returning canned responses, we're unable to test user-journeys within the publishing app. We **can't** write tests like this:

1. Visit the new document page
2. Create a new document
3. Assert that the document is visible in the interface

We can't write these tests is because no state is preserved after we have created the document. The next time a request is made to get that document, it will return the original response that the stub set up and won't reflect that change that would have happened in the Publishing API if we were interacting with the application for real.

The same is true for all user-journeys in the application. There are no tests that span more than a single page of the publishing app..

**Unable to test side-effects**

Similarly, we are unable to test that side-effects actually happen. We have no way to test that an email has actually been sent. Side-effects include:

1. Checking that draft content is visible
2. Checking that published content is visible
3. Checking that an email has been sent
4. Checking that documents appear in the search index

The closest we can get is to assert that we have sent requests to the appropriate services, but this doesn't actually check that these things have happened.

**Interface brittleness**

When interfaces change on those external services, all of our tests will continue to pass, but the application will be broken.

We may be able to do lots of manual testing to plug the holes that we have with end-to-end testing, but that doesn't account for changes to interfaces that might happen in the future.

## Proposal

I propose that we consider how to do end-to-end testing of applications on GOV.UK.

I think that we should have a high-level test-suite that can orchestrate more than one application and make assertions at external boundaries of the system, such as user-interfaces or email inboxes.

Ideally, it would treat the system as a black-box and only care about the user-facing behaviour of the system, giving us the freedom to change the internals of the system independently of this end-to-end testing process.

When developing applications, writing these high-level tests should be an inherent part of that process, rather than an after-thought.

## Solution

I don't want to prescribe what the technical solution should be.

If this RFC is accepted, I think we should have a separate forum to figure out what to do.

&nbsp;

&nbsp;

