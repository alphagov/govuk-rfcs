## Problem

We have different terms to describe what a thing is on GOV.UK.&nbsp;

&nbsp;split up format into "document type" and "schema name".

Template Consolidation's&nbsp;&nbsp;makes a distinction between "format" and "template".

This RFC is an attempt to unify the language.

## Proposal

A **document type** is what users call a thing. It's often a "real" concept, like a press release, a speech, a policy. "Is a"

A **schema** defines what the data looks like.&nbsp;"Uses a {name} schema"  
A **template** is what it looks like visually. "Rendered with a&nbsp;{name} template"

The terms "format" and "content type" are discouraged.

## Examples

[https://www.gov.uk/government/publications/acetic-acid-properties-uses-and-incident-management](https://www.gov.uk/government/publications/acetic-acid-properties-uses-and-incident-management)

- Is a "detailed\_guide"  
- Uses the "publication" schema  
- Is rendered with the "short text" template

[https://www.gov.uk/aaib-reports/aaib-investigation-to-rans-s6-coyote-ii-g-bsmu](https://www.gov.uk/aaib-reports/aaib-investigation-to-rans-s6-coyote-ii-g-bsmu)

- Is a "aaib\_report"  
- Uses the "aaib\_report" schema  
- Is rendered with the "short text" template

[https://www.gov.uk/aaib-reports](https://www.gov.uk/aaib-reports)

- Is a "specialist document finder"  
- Uses the "finder" schema  
- Is rendered with the "finder" template

[https://www.gov.uk/bank-holidays](https://www.gov.uk/bank-holidays)

[- Is a "special page"](https://www.gov.uk/bank-holidays)

- Uses the "generic" schema  
- Is rendered with the "bank holidays" template

