# Appendix B: E2E Interactions

The following is an audit of the live API requests to other GOV.UK apps, which can be used to check where contract testing may be necessary. Search for an app to see which other apps use its APIs.

> Originally this RFC had criteria for testing all live API interactions, using Smoke tests or sandboxed E2E tests. This list is an edited version of the compatibility audit that was done using those criteria.

- [asset-manager](https://github.com/alphagov/asset-manager)
  - No live API requests to GOV.UK apps.

- [authenticating-proxy](https://github.com/alphagov/authenticating-proxy)
  - Live API request to Signon [[1](https://github.com/alphagov/authenticating-proxy/blob/414d6e76218df263fd3beabd7b93d93a9ae7bb54/app/lib/proxy.rb#L17)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/draft_environment.feature#L8)].

- [bouncer](https://github.com/alphagov/bouncer)
  - No live API requests to GOV.UK apps.

- [cache-clearing-service](https://github.com/alphagov/cache-clearing-service)
  - No live API requests to GOV.UK apps.

- [ckanext-datagovuk](https://github.com/alphagov/ckanext-datagovuk)
  - Special case: not a GOV.UK app ([developed externally](https://github.com/KSP-CKAN/CKAN)).

- [collections](https://github.com/alphagov/collections)
  - Live API request to Static [[1](https://github.com/alphagov/collections/blob/5cdfa8b5185ff849b691f9f70021549c923efc6d/Gemfile#L15)].
  - Live API request to Content Store [[1](https://github.com/alphagov/collections/blob/329d7c84bb90731f9542362585a3d8d09f15a630/app/models/content_item.rb#L5)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/collections.feature#L8)].
  - Live API request to Search API [[1](https://github.com/alphagov/collections/blob/7bc125e5670ecba7b85a3918c8b02d339b0368d9/app/lib/services_and_information_links_grouper.rb#L21)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/collections.feature#L41)].
  - Live API request to Mapit [[1](https://github.com/alphagov/collections/blob/d0a7286456f9b0792a0a5f5e1abc2acb65715ebf/app/services/location_lookup_service.rb#L52)].

- [collections-publisher](https://github.com/alphagov/collections-publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/collections-publisher/blob/b2acd0ff4c10057943628b00491297cd24added4/app/controllers/application_controller.rb#L7)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/publishing_tools.feature#L3)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/collections-publisher/blob/f5cfc71d282f26469afec98398fa0ccd32bbb80b/app/services/coronavirus_pages/draft_updater.rb#L30)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/collections_publisher/publishing_parent_and_child_topic_spec.rb)].
  - Live API request to Content Store [[1](https://github.com/alphagov/collections-publisher/blob/f04fdc32409165f238b32245d8189faa5ac216a3/app/validators/valid_govuk_path_validator.rb#L5)].
  - Live API request to Link Checker API [[1](https://github.com/alphagov/collections-publisher/blob/2f16dddc0f9958f7a8ba8282742e0448e66098bb/app/models/step.rb#L40)].

- [contacts-admin](https://github.com/alphagov/contacts-admin)
  - Live API request to Signon [[1](https://github.com/alphagov/contacts-admin/blob/da62aedccfcbe22b02ac5c3a16595172de5d7111/app/controllers/admin_controller.rb#L4)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/publishing_tools.feature#L12)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/contacts-admin/blob/97127269e3e1b5e41e29291282285c83b3f2e870/app/interactors/admin/destroy_contact.rb#L9)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/contacts_admin/publish_a_contact_spec.rb)].
  - Live API request to Whitehall [[1](https://github.com/alphagov/contacts-admin/blob/c39a9b63a9cbf254384af9c4cb042017fede4e74/app/views/admin/contacts/post_addresses/_form.html.erb#L10)].

- [content-data-admin](https://github.com/alphagov/content-data-admin)
  - Live API request to Content Data API [[1](https://github.com/alphagov/content-data-admin/blob/dcd23d101fad94bd07f158f6c20f79ccc1e72c76/lib/gds_api/content_data_api.rb)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/content_data_admin.feature#L13)].

- [content-data-api](https://github.com/alphagov/content-data-admin)
  - No live API requests to GOV.UK apps.

- [content-publisher](https://github.com/alphagov/content-publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/content-publisher/blob/f4b0ea2bc0056a4c345602e1636b1cf6c16dfa45/app/controllers/application_controller.rb#L10)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/publishing_tools.feature#L29)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/content-publisher/blob/3e479a6decc7be7aad9a1d82b43cd061ca7e6741/app/services/preview_draft_edition_service.rb#L21)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/content-publisher/blob/0c757447ca2aad3621f11c99fe8307a718ade186/app/services/preview_asset_service.rb#L24)].

- [content-store](https://github.com/alphagov/content-store)
  - Live API request to Router API [[1](https://github.com/alphagov/content-store/blob/b035022aa5e75b2ccce11fd855ff84e8da273cbd/app/models/route_set.rb#L121)].

- [content-tagger](https://github.com/alphagov/content-tagger)
  - Live API request to Signon [[1](https://github.com/alphagov/content-tagger/blob/97e1e3825e5cf4fd1c7291c1f37eb2b12894c0ed/app/controllers/application_controller.rb#L5)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/publishing_tools.feature#L21)].
  - Live API request to Email Alert API [[1](https://github.com/alphagov/content-tagger/blob/97e1e3825e5cf4fd1c7291c1f37eb2b12894c0ed/app/services/taxonomy/show_page.rb#L89)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/content-tagger/blob/7b40f74054783536f39060a64df3f8d82bf76b65/app/workers/publish_taxon_worker.rb#L9)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/content_tagger/create_draft_taxon_spec.rb)].

- [email-alert-api](https://github.com/alphagov/email-alert-api)
  - No live API requests to GOV.UK apps.

- [email-alert-frontend](https://github.com/alphagov/email-alert-frontend)
  - Live API request to Static [[1](https://github.com/alphagov/email-alert-frontend/blob/5dce6ef63ae97259b47dd2dc3869a3f83825589b/Gemfile#L12)].
  - Live API request to Content Store [[1](https://github.com/alphagov/email-alert-frontend/blob/00475de8b7a168dd832909465774fbea0021bb8d/app/controllers/content_item_signups_controller.rb#L66)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/collections.feature#L54)].
  - Live API request to Email Alert API [[1](https://github.com/alphagov/email-alert-frontend/blob/00475de8b7a168dd832909465774fbea0021bb8d/app/models/content_item_subscriber_list.rb#L6)]  [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/finder_frontend.feature#L64)].

- [email-alert-service](https://github.com/alphagov/email-alert-service)
  - Live API request to Email Alert API [[1](https://github.com/alphagov/email-alert-service/blob/fabcf01849b6073e67a09b4acd76eea841cfd5bf/email_alert_service/models/email_alert.rb#L15)].

- [feedback](https://github.com/alphagov/feedback)
  - Live API request to Static [[1](https://github.com/alphagov/feedback/blob/256a6d30e80828b34fd659398d938154ceabf1fa/Gemfile#L15)].
  - Live API request to Support API [[1](https://github.com/alphagov/feedback/blob/61d175b509b0be9bbcc2b052e4c28ad775898e5a/app/models/service_feedback.rb#L18)].
  - Live API request to Support [[1](https://github.com/alphagov/feedback/blob/61d175b509b0be9bbcc2b052e4c28ad775898e5a/app/models/contact_ticket.rb#L35)].

- [finder-frontend](https://github.com/alphagov/finder-frontend)
  - Live API request to Static [[1](https://github.com/alphagov/finder-frontend/blob/6837084cec40f651a5472553b7968bf14cd4a538/Gemfile#L15)].
  - Live API request to Content Store [[1](https://github.com/alphagov/finder-frontend/blob/ec425f329348a7e7c424dcabc27b351c100ac601/app/controllers/finders_controller.rb#L88)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/finder_frontend.feature#L16)].
  - Live API request to Email Alert API [[1](https://github.com/alphagov/finder-frontend/blob/2584995bcbc4fef6302205a7764b436d25063c18/app/controllers/brexit_checker_controller.rb#L45)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/brexit_check.feature#L23)].
  - Live API request to Search API [[1](https://github.com/alphagov/finder-frontend/blob/80e265c3b6be25e42a4108480d698bdd60f19642/app/lib/registries/people_registry.rb#L46)] [[2](https://github.com/alphagov/smokey/blob/1ed4d16d13564e52839a8480dfaa1543ce5af196/features/finder_frontend.feature#L85)].
  - Live API request to Whitehall [[1](https://github.com/alphagov/finder-frontend/blob/80e265c3b6be25e42a4108480d698bdd60f19642/app/lib/registries/world_locations_registry.rb#L46)].

- [frontend](https://github.com/alphagov/frontend)
  - Live API request to Static [[1](https://github.com/alphagov/frontend/blob/9fdfefcb11b9c1ef1653c7330d263ed042564d81/Gemfile#L17)].
  - Live API request to Content Store [[1](https://github.com/alphagov/frontend/blob/8dbe0f0f6ca0f5a777a0d6ca77b858fe5adc2494/app/controllers/application_controller.rb#L82)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/frontend.feature#L12)].
  - Live API request to Licensify [[1](https://github.com/alphagov/frontend/blob/8dbe0f0f6ca0f5a777a0d6ca77b858fe5adc2494/app/controllers/licence_controller.rb#L49)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/frontend.feature#L33)].

- [government-frontend](https://github.com/alphagov/government-frontend)
  - Live API request to Static [[1](https://github.com/alphagov/government-frontend/blob/268d0dd1778f1ea10d49d0ae94bcf780ba16e7b9/Gemfile#L17)].
  - Live API request to Content Store [[1](https://github.com/alphagov/government-frontend/blob/0c6aeb4102c351b0a37df32979493cd006f4f4d0/app/controllers/content_items_controller.rb#L89)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/government_frontend.feature#L8)].

- [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas)
  - No live API requests to GOV.UK apps.

- [govuk_crawler_worker](https://github.com/alphagov/govuk_crawler_worker)
  - No live API requests to GOV.UK apps.

- [hmrc-manuals-api](https://github.com/alphagov/hmrc-manuals-api)
  - Live API request to Publishing API [[1](https://github.com/alphagov/hmrc-manuals-api/blob/3248572e16452ec4e51b6434d3582bf6ef3c2975/app/notifiers/publishing_api_notifier.rb#L16)].
  - APIs are not consumed by any GOV.UK apps.

- [imminence](https://github.com/alphagov/imminence)
  - Live API request to Mapit [[1](https://github.com/alphagov/imminence/blob/0e6a9a44cc81b51fdcefe4c4a116ad4f8dfae3fb/app/controllers/areas_controller.rb#L30)] [[2](https://github.com/alphagov/smokey/blob/master/features/smartanswers.feature#L106)].

- [info-frontend](https://github.com/alphagov/info-frontend)
  - Live API request to Static [[1](https://github.com/alphagov/info-frontend/blob/ca5efc64f91638bf63cebd2de822f5a059b8f3cf/Gemfile#L10)].
  - Live API request to Content Store [[1](https://github.com/alphagov/info-frontend/blob/7d814f04cae313a43432e2f6fa23a2f0157e0d36/app/controllers/info_controller.rb#L12)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/info_frontend.feature)].

- [licence-finder](https://github.com/alphagov/licence-finder)
  - Live API request to Static [[1](https://github.com/alphagov/licence-finder/blob/7f6a19170bd87d1d3f12e23f78e9f7ac62fab762/Gemfile#L16)].
  - Live API request to Content Store [[1](https://github.com/alphagov/licence-finder/blob/e82bb28693578b9b5a53ae70ad399b7d7f4a5894/app/controllers/licence_finder_controller.rb#L130)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/licence_finder.feature#L11)].
  - Live API request to Search API [[1](https://github.com/alphagov/licence-finder/blob/432a653f508a0da47154810a06ffa29628c36e28/app/models/licence_facade.rb#L19)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/licence_finder.feature#L15)].

- [licensify](https://github.com/alphagov/licensify)
  - Special case: not a GOV.UK app ([maintained externally](https://docs.publishing.service.gov.uk/apps/licensify.html#ownership)).

- [link-checker-api](https://github.com/alphagov/link-checker-api)
  - No live API requests to GOV.UK apps.

- [local-links-manager](https://github.com/alphagov/local-links-manager)
  - Live API request to Signon [[1](https://github.com/alphagov/local-links-manager/blob/74fbde57d13d422dad62917e904e84f5e1652077/app/controllers/application_controller.rb#L3)] [[2](https://github.com/alphagov/smokey/blob/24a889a4346e3a9ff74d6ad0f389b90919944452/features/publishing_tools.feature#L45)].

- [manuals-frontend](https://github.com/alphagov/manuals-frontend)
  - Live API request to Static [[1](https://github.com/alphagov/manuals-frontend/blob/3325d4d15f6af7f0c6bb6598ff41a5d1d59c9c0c/Gemfile#L5)].
  - Live API request to Content Store [[1](https://github.com/alphagov/manuals-frontend/blob/000b4ec8d6d64f60d7b7e715a838f9675b5e85e3/app/repositories/document_repository.rb#L18)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/manuals_frontend.feature#L10)].

- [manuals-publisher](https://github.com/alphagov/manuals-publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/manuals-publisher/blob/43b3d96f49e45e1d814673efb1fc9834efdde2f3/app/controllers/application_controller.rb#L10)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/publishing_tools.feature#L53)].
  - Live API request to Collections [[1](https://github.com/alphagov/manuals-publisher/blob/43b3d96f49e45e1d814673efb1fc9834efdde2f3/app/adapters/organisations_adapter.rb#L10)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/publisher/creating_draft_content_spec.rb)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/manuals-publisher/blob/43b3d96f49e45e1d814673efb1fc9834efdde2f3/app/adapters/publishing_adapter.rb#L186)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/publisher/creating_draft_content_spec.rb)].
  - Live API request to Link Checker API [[1](https://github.com/alphagov/manuals-publisher/blob/43b3d96f49e45e1d814673efb1fc9834efdde2f3/app/services/link_check_report/create_service.rb#L60)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/manuals-publisher/blob/43b3d96f49e45e1d814673efb1fc9834efdde2f3/app/models/attachment.rb#L35)].

- [mapit](https://github.com/alphagov/mapit)
  - No live API requests to GOV.UK apps.

- [maslow](https://github.com/alphagov/maslow)
  - Live API request to Signon [[1](https://github.com/alphagov/maslow/blob/f78c86b85e42605331f0ea32fab25b5a707b857e/app/controllers/application_controller.rb#L15)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/publishing_tools.feature#L62)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/maslow/blob/f78c86b85e42605331f0ea32fab25b5a707b857e/app/models/need.rb#L309)].

- [publisher](https://github.com/alphagov/publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/publisher/blob/86d0d8730afe82ece905c7da16518074373dbeb4/app/controllers/application_controller.rb#L6)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/publishing_tools.feature#L71)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/publisher/blob/e02632d914431a491e4bdfada7d6e5db7431f3a5/app/models/edition.rb#L422)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/publisher/creating_draft_content_spec.rb)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/publisher/blob/ad5541a78cdb2a27b3c7fe4a5ec23705bbb812dd/app/traits/attachable.rb#L63)].
  - Live API request to Link Checker API [[1](https://github.com/alphagov/publisher/blob/86d0d8730afe82ece905c7da16518074373dbeb4/app/services/link_check_report_creator.rb#L48)].
  - Live API request to Frontend [[1](https://github.com/alphagov/publisher/blob/2e2184503eb26480a0036315b8360b63b8212c87/lib/working_days_calculator.rb#L28)].

- [publishing-api](https://github.com/alphagov/publishing-api)
  - Live API request to Content Store [[1](https://github.com/alphagov/publishing-api/blob/899d8dcb1f220a863ebc023407e4059a8dc39818/app/services/downstream_service.rb#L10)].

- [release](https://github.com/alphagov/release)
  - No live API requests to GOV.UK apps.

- [router](https://github.com/alphagov/router)
  - No live API requests to GOV.UK apps.

- [router-api](https://github.com/alphagov/router-api)
  - Live API request to Router [[1](https://github.com/alphagov/router-api/blob/c4dd8bf33da8c5605afea9fb17e359ad9ece29a8/lib/router_reloader.rb#L15)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/manuals_publisher/publish_live_spec.rb)].

- [search-api](https://github.com/alphagov/search-api)
  - Live API request to Publishing API [[1](https://github.com/alphagov/search-api/blob/b86f6c7f5b89be5e3607b4d41c4fff98a7562ddb/lib/indexer/attachments_lookup.rb#L62)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/3d2f74569ccc5136899364e4e0f24ca1d80ab6ff/spec/publisher/publishing_content_to_government_frontend_spec.rb#L41)].

- [search-admin](https://github.com/alphagov/search-admin)
  - Live API request to Publishing API [[1](https://github.com/alphagov/search-admin/blob/69bf410bf982be66e58e5e01a2b17f4209913839/app/services/external_content_publisher.rb#L6)].
  - Live API request to Search API [[1](https://github.com/alphagov/search-admin/blob/69bf410bf982be66e58e5e01a2b17f4209913839/app/controllers/results_controller.rb#L7)].
  - Live API request to Signon [[1](https://github.com/alphagov/search-admin/blob/69bf410bf982be66e58e5e01a2b17f4209913839/app/controllers/application_controller.rb#L7)].

- [service-manual-frontend](https://github.com/alphagov/service-manual-frontend)
  - Live API request to Static [[1](https://github.com/alphagov/service-manual-frontend/blob/0d4d276dcb6ac081ec233690728623d63d733613/Gemfile#L12)].
  - Live API request to Content Store [[1](https://github.com/alphagov/service-manual-frontend/blob/0fac11ad7f063cbff5c598ad6ef3d3d50ec3d523/app/controllers/content_items_controller.rb#L27)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/service_manual.feature#L7)].

- [service-manual-publisher](https://github.com/alphagov/service-manual-publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/service-manual-publisher/blob/97fd600604029e058375707aa51187fbec9a6aa2/app/controllers/application_controller.rb#L7)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/publishing_tools.feature#L79)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/service-manual-publisher/blob/97fd600604029e058375707aa51187fbec9a6aa2/app/controllers/uploads_controller.rb#L14)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/service-manual-publisher/blob/97fd600604029e058375707aa51187fbec9a6aa2/app/services/guide_manager.rb#L31)].

- [short-url-manager](https://github.com/alphagov/short-url-manager)
  - Live API request to Signon [[1](https://github.com/alphagov/short-url-manager/blob/d67db77a4ddfc5dd43ef5bc61dff757f69ee9686/app/controllers/application_controller.rb#L7)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/publishing_tools.feature#L87)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/short-url-manager/blob/d67db77a4ddfc5dd43ef5bc61dff757f69ee9686/app/models/redirect.rb#L29)].

- [sidekiq-monitoring](https://github.com/alphagov/sidekiq-monitoring)
  - Special case: support app for monitoring.

- [signon](https://github.com/alphagov/signon)
  - No live API requests to GOV.UK apps.

- [smart-answers](https://github.com/alphagov/smart-answers)
  - Live API request to Static [[1](https://github.com/alphagov/smart-answers/blob/9df500c639d7d9711ea69847622d0226c251d284/Gemfile#L23)].
  - Live API request to Content Store [[1](https://github.com/alphagov/smart-answers/blob/e07909df5962abb4125980fd50efc0922d6258f6/app/controllers/session_answers_controller.rb#L4)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/smartanswers.feature#L14)].
  - Live API request to Imminence [[1](https://github.com/alphagov/smart-answers/blob/9b637a5a3d1fbb56cbd4f476cd4653ed7d286710/lib/smart_answer/calculators/landlord_immigration_check_calculator.rb#L16)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/smartanswers.feature#L36)].
  - Live API request to Whitehall [[1](https://github.com/alphagov/smart-answers/blob/57b41bea27ed793e51b101467bd4616a4265e324/app/models/world_location.rb#L18)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/smartanswers.feature#L56)].
  - Live API request to Frontend [[1](https://github.com/alphagov/smart-answers/blob/396a140694fcf915593a6e48f399c4565a1c1865/lib/working_days.rb#L6)].

- [specialist-publisher](https://github.com/alphagov/specialist-publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/specialist-publisher/blob/27c6ec0511a84538ae9e6e93a6e2caea81abc89f/app/controllers/application_controller.rb#L7)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/publishing_tools.feature#L96)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/specialist-publisher/blob/27c6ec0511a84538ae9e6e93a6e2caea81abc89f/app/services/document_publisher.rb#L11)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/specialist_publisher/publishing_spec.rb#L6)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/specialist-publisher/blob/8debeb2f0147142c87f22308d57fe4f6dd0c1297/app/models/attachment.rb#L49)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/specialist_publisher/upload_attachment_spec.rb)].
  - Live API request to Email Alert API [[1](https://github.com/alphagov/specialist-publisher/blob/ef53b9e18f4baff204162c3179adcd15c176cb6a/app/workers/email_alert_api_worker.rb#L7)].

- [static](https://github.com/alphagov/static)
  - No live API requests to GOV.UK apps.

- [support](https://github.com/alphagov/support)
  - Live API request to Support API [[1](https://github.com/alphagov/support/blob/41cec714da8967acb16a41ac93bfea4fa3368852/app/controllers/anonymous_feedback/problem_reports_controller.rb#L32)].

- [support-api](https://github.com/alphagov/support-api)
  - No live API requests to GOV.UK apps.

- [transition](https://github.com/alphagov/transition)
  - Live API request to Signon [[1](https://github.com/alphagov/transition/blob/f11449c4362e65c3da4d0c18489923e1fce12ef2/app/controllers/application_controller.rb#L5)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/transition.feature#L4)].

- [travel-advice-publisher](https://github.com/alphagov/travel-advice-publisher)
  - Live API request to Signon [[1](https://github.com/alphagov/travel-advice-publisher/blob/0efd572383bebd574f7c666d950218df3d5d6dc2/app/controllers/application_controller.rb#L5)] [[2](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/publishing_tools.feature#L106)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/travel-advice-publisher/blob/540aa04f7e1fc54bcc03e9a20c68a97a3847f8a8/app/workers/publishing_api_worker.rb#L12)] [[2](https://github.com/alphagov/publishing-e2e-tests/tree/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/travel_advice_publisher)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/travel-advice-publisher/blob/f6128e3698bb5eab4bdc1794e85ba6ffef415263/app/models/travel_advice_edition.rb#L231)] [[2](https://github.com/alphagov/publishing-e2e-tests/tree/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/travel_advice_publisher)].
  - Live API request to Link Checker API [[1](https://github.com/alphagov/travel-advice-publisher/blob/0efd572383bebd574f7c666d950218df3d5d6dc2/app/notifiers/email_alert_api_notifier.rb#L9)] [[2](https://github.com/alphagov/travel-advice-publisher/blob/0d772912137b067bc0e3615c504025a66f1917ec/app/services/link_check_report_creator.rb#L41)].
  - Live API request to Email Alert API [[1](https://github.com/alphagov/travel-advice-publisher/blob/dfeac3c8986519717815a8c80b8b9b84bf5cdbaf/app/notifiers/email_alert_api_notifier.rb#L9)].

- [whitehall](https://github.com/alphagov/whitehall)
  - Live API request to Static [[1](https://github.com/alphagov/whitehall/blob/4d1de9a6818041994f555ae40164b08cd85f043e/Gemfile#L58)].
  - Live API request to Signon [[1](https://github.com/alphagov/whitehall/blob/8c9234f54749c378c27d3bb497c4986d93dbd89d/app/controllers/admin/base_controller.rb#L7)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/publishing_tools.feature#L114)].
  - Live API request to Asset Manager [[1](https://github.com/alphagov/whitehall/blob/master/lib/csv_file_from_public_host.rb#L9)] [[2](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/csv_preview.feature#L9)].
  - Live API request to Publishing API [[1](https://github.com/alphagov/whitehall/blob/8c9234f54749c378c27d3bb497c4986d93dbd89d/app/workers/publishing_api_worker.rb#L54)] [[2](https://github.com/alphagov/publishing-e2e-tests/blob/43ac18bba872c8f73e5a543190cfc787a86c38bb/spec/whitehall/updating_document_spec.rb#L8)].
  - Live API request to Content Store [[1](https://github.com/alphagov/whitehall/blob/8c9234f54749c378c27d3bb497c4986d93dbd89d/app/controllers/organisations_controller.rb#L5)].
  - Live API request to Search API [[1](https://github.com/alphagov/whitehall/blob/8c9234f54749c378c27d3bb497c4986d93dbd89d/app/controllers/world_location_news_controller.rb#L44)].
  - Live API request to Email Alert API [[1](https://github.com/alphagov/whitehall/blob/8c9234f54749c378c27d3bb497c4986d93dbd89d/app/models/world_location_email_signup.rb#L9)].
  - Live API request to Link Checker API [[1](https://github.com/alphagov/whitehall/blob/8c9234f54749c378c27d3bb497c4986d93dbd89d/app/controllers/admin/editions_controller.rb#L114)].
  - Live API request to Maslow [[1](https://github.com/alphagov/whitehall/blob/305f4faf488b97ddd7f4d234a82576fd070346fb/app/views/admin/editions/_need.html.erb#L8)].
