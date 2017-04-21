## Problem

We have different terms to describe what a thing is on GOV.UK.&nbsp;

&nbsp;split up format into "document type" and "schema name".

Template Consolidation's&nbsp;&nbsp;makes a distinction between "format" and "template".

This RFC is an attempt to unify the language.

## Proposal

A **document type** is what users call a thing. It's often a "real" concept, like a press release, a speech, a policy. "Is a {name}"

A **schema** defines what the data looks like.&nbsp;"Uses a {name} schema"

A **template** is what the page looks like visually. "Rendered with a&nbsp;{name} template"

The terms "format" and "content type" are discouraged.

## Examples

[https://www.gov.uk/guidance/data-verifying-services](https://www.gov.uk/guidance/data-verifying-services)

- Is a "detailed guide"  
- Uses the "detailed\_guide" schema  
- Is rendered with the "short text" template

[https://www.gov.uk/aaib-reports/aaib-investigation-to-rans-s6-coyote-ii-g-bsmu](https://www.gov.uk/aaib-reports/aaib-investigation-to-rans-s6-coyote-ii-g-bsmu)

- Is a "aaib report"  
- Uses the "aaib\_report" schema  
- Is rendered with the "short text" template

[https://www.gov.uk/aaib-reports](https://www.gov.uk/aaib-reports)

- Is a "specialist document finder"  
- Uses the "finder" schema  
- Is rendered with the "finder" template

[https://www.gov.uk/bank-holidays](https://www.gov.uk/bank-holidays)

- Is a "calendar"

- Uses the "generic" schema  
- Is rendered with the "calendar" template

[https://www.gov.uk/](https://www.gov.uk/bank-holidays)

- Is a "special page"

- Uses the "generic" schema  
- Is rendered with the "homepage" template

