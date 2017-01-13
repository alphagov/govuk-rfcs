## Problem

Our frontend applications have many templates that render similar pages which makes consistent updates difficult.

As part of Discovery the Template Consolidation team has grouped formats into 5 categories

|   
 | 

Rendered by

 |
| 

[Short Text](https://gov-uk.atlassian.net/wiki/display/FE/*Short-text+format)

 | 

government-frontend

whitehall

frontend

multipage-frontend

specialist-frontend

 |
| 

[Long Text](https://gov-uk.atlassian.net/wiki/display/FE/*Long-text+format)

 | 

manuals-frontend

design-principles

whitehall

government-frontend

 |
| 

[Start Page](https://gov-uk.atlassian.net/wiki/display/FE/*Start+pages)

 | 

trade-tariff-frontend

email-campaign-frontend

frontend

calculators

smart-answers

license-finder

 |
| 

[Homepage](https://gov-uk.atlassian.net/wiki/display/FE/*Home+pages)

 | 

whitehall

 |
| 

[Bespoke](https://gov-uk.atlassian.net/wiki/display/FE/*Bespoke)

 | 

collections

calendars

 |

(More information can be found on our wiki [https://gov-uk.atlassian.net/wiki/display/FE/Mission%3A+Discovery+Phase](https://gov-uk.atlassian.net/wiki/display/FE/Mission%3A+Discovery+Phase))

## Proposal

We intend to merge the frontend applications concerned with rendering published content into a single application. To do this we will iterate the current templates so they are grouped by how they are rendered rather than their relationships with the formats.

Diagram shows the different applications that render published content that will be merged into ‘published-content-frontend’ (Name pending) forked from ‘government-frontend’ as the base.

## Alpha

As part of the Template Consolidation Alpha we are looking to explore what this could look like focusing only on the ‘Short Text’ template ([Why start with short text?](https://gov-uk.atlassian.net/wiki/pages/viewpage.action?pageId=127041562)). If we do not find any major problems we will update the community and work through the rest of the templates in Beta.

During Alpha we will only work on ‘government-frontend’, ‘specialist-frontend’ and ‘multipage-frontend’. We intend to fork ‘government-frontend’ as a base and merge in ‘specialist-frontend’ and ‘multipage-frontend’.

We are still considering our approach so would love some feedback from the wider community.

