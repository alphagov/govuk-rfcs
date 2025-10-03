---
status: proposed
implementation: proposed
status_last_reviewed:
---

# Replacement of Email-based Fact Checking process in Publisher

## Summary

Replace Publisher’s current email-based fact check workflow with a secure, auditable system that supports multiple reviewers and reduces manual effort. 

## Problem

The supporting email service is being deprecated, and its unreliability has already created ongoing toil for the Mainstream team (e.g. issues in email processing).
The current workflow also introduces multiple user pain points, most of which could be resolved by creating a dedicated tool.

As a team, we have a broad understanding of the fact check process, [User Research](https://docs.google.com/presentation/d/1Krl4a7owEX-6C2afnLRVJY51vMUe_BtP-GLREqI0R2k/edit?slide=id.g34114577801_0_0#slide=id.g34114577801_0_0) has been conducted, giving us clear indication of main user pain points. We have created a [prototype](https://govuk-mainstream-publishing-e8a90a952334.herokuapp.com/fact-check-prototype/index) and visualized main concerns on [Mural board](https://app.mural.co/t/govukdelivery7534/m/govukdelivery7534/1757931122471/7df9fba94e61240ef8901505f35d59e6f77b9542), as well as shared [Scoping document](https://docs.google.com/document/d/12Tiq7_rnRMDqwXWAjD6COklpEzvXtaIJeYjtUKGnbS0/edit?tab=t.0#heading=h.m3oovrysj2ps) with other teams.


## Proposal

This RFC summarises technical implementation options for a replacement workflow. From all available approaches, we are now focusing on three options that best address user, security, and performance needs. Other options considered but not pursued are listed at the end of this document.
Objectives of the new process:

- Allow SMEs to review and respond to fact checks without using email.
- Reduce toil and improve usability for content designers and reviewers.
- Handle multiple parallel or sequential responses.
- Provide a clear audit trail of who approved and who requested changes.
- Support multiple reviewers with structured feedback.
- Meet security requirements via Signon or magic-link authentication.
- Enable visibility of content for potential future integration with Zendesk.

### Options

We are considering three options, all of which meet the objectives above:

1. Tool integrated directly into the Mainstream Publisher app.
2. Standalone Fact Check Application.
3. Rails Engine within Publisher.

#### Option 1: Tool integrated into the Mainstream Publisher app

This option would involve building the fact check functionality directly into the existing Mainstream Publisher application. The main advantage is that it would be fully integrated with Publisher’s business logic, eliminating the need for a separate application or any additional API integrations. However, this approach would add complexity to the Publisher codebase and increase the long-term maintenance burden. It would also raise security risks by broadening external access to Publisher.

#### Option 2: Standalone Fact Check Application

A standalone application would provide a clear separation of concerns, making the fact check process distinct from Publisher and potentially more scalable for future needs. It could also, in theory, be reused by other GOV.UK publishing apps, although this is of limited value at present since we do not expect other apps to adopt the same process. The downsides of this approach are the high development and integration effort required, the added complexity of keeping data in sync between systems, and the need for additional infrastructure and ongoing maintenance.

#### Option 3: Rails Engine within Publisher

The third option is to build the functionality as a Rails Engine within Publisher. This would allow us to reuse Publisher’s existing code and logic, reducing the implementation effort, while also providing a design that can minimise internal complexity if done carefully. A further benefit of this approach is its flexibility: the engine could later be extracted into a standalone service if reuse across other applications became necessary. The disadvantages are the need for careful management of boundaries between the engine and the rest of the application, as well as the initial setup effort and some ongoing maintenance overhead.

### Recommendation
Pending further team discussions. We are inclined towards Option 3 (Rails Engine). This approach balances effort and feasibility: it is faster to deliver than a standalone application, while leaving the door open to evolve into a separate service later if reuse demands increase.

#### Options considered but not pursued

Tokenized Interface (no login) / Secure Link + Response Form

This option would have been straightforward to implement, but it introduces several issues. Security risks are significant, as tokens could be leaked or shared. Attribution would be weak, relying on anonymous submissions or manual name entry. The approach also provides poor support for multiple reviewers, making it unsuitable for the needs identified.

Integration with External Tools / Email Proxies (e.g. Microsoft tools)

Another option was to leverage tools already familiar to SMEs, such as Slack, Teams, or Zendesk, and feed responses back into Publisher. While this could reduce adoption friction, it would still rely on external infrastructure and would not provide the necessary auditability. In practice, it risks creating additional operational toil and producing an inconsistent user experience across departments.

