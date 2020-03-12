# RFC 95: Long term future of applications

## Summary

This RFC describes the direction of travel for the applications that make up GOV.UK.

## Problem

We currently have 58 separate applications running on GOV.UK. The [Platform architecture principles][princ] explain where we're going from an architectural standpoint. This RFC is an attempt to explain the long term vision of each of GOV.UK's apps.

The purpose of doing this is to make clear:

- where to put new functionality
- which applications need particular attention

## Proposal

| Name | Description | Rough action plan |
| -- | -- | -- |
| calculators | Serves the Child benefit tax calculator on GOV.UK | Merge into smart-answers |
| calendars | Serves /bank-holidays and /when-do-the-clocks-change on GOV.UK | Merge into custom frontend |
| ckanext-datagovuk | Extension for use with datagovuk_publish | Unknown |
| collections-publisher | Publishes step by steps, /browse pages, and legacy /topic pages on GOV.UK | While topics and browse pages will be removed, this can still be the app for curating collections. We might move Whitehall's document collections into this app |
<<<<<<< Updated upstream
=======
| content-audit-tool | Deprecated application to audit content | Retire, as it's not used. (Update 12 March 2020: Content Audit Tool was retired in January 2020) |
>>>>>>> Stashed changes
| content-publisher | WIP - Future publisher of content on GOV.UK | Expand to publish most content |
| datagovuk_find | Beta version of Find Data | Unknown |
| datagovuk_publish | Beta version of publish data | [Under discussion](https://github.com/alphagov/govuk-rfcs/pull/95#issuecomment-425097037) |
| email-alert-service | Message queue consumer that triggers email alerts for GOV.UK | Merge into email-alert-api, as it's only task is to take things from the message queue and forward it there |
| licence-finder | Serves licence pages on GOV.UK | Retire or [merge into other app](https://github.com/alphagov/govuk-rfcs/pull/95#discussion_r220937672) |
| licensify | GOV.UK Licensing (formerly ELMS, Licence Application Tool, & Licensify) | Retire |
| manuals-frontend | Serves manuals on GOV.UK | Merge into government-frontend |
| manuals-publisher | Publishes manuals on GOV.UK | Retire in favour of content-publisher |
| mapit | GOV.UK fork of Mapit, a web service to map postcodes to administrative boundaries | Possible retire [in favour of a hosted version](https://github.com/alphagov/govuk-rfcs/pull/95#discussion_r220922280) |
| organisations-publisher | (Work in progress) Application for managing organisations, people and roles within GOV.UK | Will take on the organisation and "machinery of government" functionality of whitehall |
| publisher | Publishes mainstream content on GOV.UK | Retire in favour of content-publisher |
| router-api | API for updating the routes used by the router on GOV.UK | Merge into either content store or publishing-api |
| service-manual-frontend | Serves the Service Manual and Service Toolkit on GOV.UK | Parts of the frontend could be merged into government-frontend, and other apps |
| service-manual-publisher | Publishes the Service Manual on GOV.UK | Custom application that could long term be replaced by content-publisher  |
| specialist-publisher | Publishes specialist documents on GOV.UK | Retire in favour of content-publisher |
| static | GOV.UK static files and resources | Retire in favour of [the components gem][cg] |
| travel-advice-publisher | Publishes foreign travel advice on GOV.UK | Retire in favour of content-publisher |
| whitehall | Publishes government content on GOV.UK | Retire in favour of content-publisher, organisations-publisher, and collections-publisher, custom-frontend (history pages) |

### Apps that need a Rename

| Name | Description | Rough action plan |
| -- | -- | -- |
| bouncer | Handles traffic for sites that have transitioned to GOV.UK | Rename to "transition-redirector" |
| collections | Serves the new navigation pages, browse, topic and services and information pages on GOV.UK | Rename to "collections-frontend" |
| content-performance-manager | Data warehouse that stores content and content metrics to help content owners measure and improve content on GOV.UK | Rename to "content-data" |
| feedback | Serves contact pages on GOV.UK | Rename to "feedback-frontend" |
| finder-frontend | Serves search pages for GOV.UK | Rename to "search-frontend". |
| frontend | Serves the homepage, transactions and some index pages on GOV.UK | Rename to "custom-frontend" |
| government-frontend | Serves government pages on GOV.UK | Rename to "content-frontend" |
| imminence | Find My Nearest API and management tools on GOV.UK | Rename to? |
| maslow | Create and manage needs on GOV.UK | Rename to "user-needs-publisher" |
| rummager | Search API for GOV.UK | Rename to "search-api" |
| smart-answers | Serves smart answers on GOV.UK | Rename to "smart-answers-frontend" |
| support | Forms to raise Zendesk tickets to be used by Government personnel on GOV.UK | Rename to "support-admin" |
| transition | Managing redirects for sites moving to GOV.UK. | Rename to "transition-admin" |

[cg]: https://github.com/alphagov/govuk_publishing_components

### No changes expected

| Name | Description | Rough plan |
| -- | -- | -- |
| asset-manager | Manages uploaded assets (images, PDFs etc.) for applications on GOV.UK | No change expected |
| authenticating-proxy | Allows authorised users to access the GOV.UK draft stack | No change expected |
| cache-clearing-service | Clears various caches when new content is published. | No change expected |
| contacts-admin | Publishes HMRC contact information on GOV.UK | No change expected |
| content-data-admin | A front end for the data warehouse | No change expected |
| content-store | API for content on GOV.UK | No change expected |
| content-tagger | Tool to tag content and manage the taxonomy on GOV.UK | No change expected |
| email-alert-api | Sends email alerts to the public for GOV.UK | No change expected |
| email-alert-frontend | Serves email alert signup pages on GOV.UK | No change expected |
| hmrc-manuals-api | API for HMRC to publish manuals to GOV.UK | No change expected |
| link-checker-api | Checks links on GOV.UK | No change expected |
| local-links-manager | Manages local links from local authorities on GOV.UK | No change expected |
| publishing-api | API to publish content on GOV.UK | No change expected |
| release | Helps deploying to GOV.UK | No change expected |
| router | Router in front on GOV.UK to proxy to backend servers on the single domain | No change expected |
| search-admin | Admin for GOV.UK search | No change expected |
| short-url-manager | Tool to request, approve and create short URL redirects on GOV.UK | No change expected |
| signon | Single sign-on service for GOV.UK | No change expected |
| support-api | API for processing GOV.UK named requests and anonymous feedback | No change expected |
| info-frontend | Serves /info pages to display user needs and performance data about a page on GOV.UK | No change expected |

[princ]: https://docs.google.com/document/d/1Oft4akc6dZfhhOjosNPbFpcLUOUjz7YG7QPcVZi8hww/edit#heading=h.goscl46jcc91
