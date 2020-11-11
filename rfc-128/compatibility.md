# Appendix A: Compatibility

The following is a rough audit of compatibility for most GOV.UK apps with respect to the safety criteria identified in the RFC. The code references used in this audit are all anchored to specific commits, so that they are robust in the face of future changes. **Warning: this means the links could be out-of-date.**

- ❌ [asset-manager](https://github.com/alphagov/asset-manager)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint (draft and live) [[1](https://github.com/alphagov/asset-manager/blob/65cf7e7965ca5f9b5c4980c73ac9fcb7b862483a/app/models/healthcheck.rb)]:
    - Check for connectivity to MongoDB.
    - Check for connectivity to Redis.
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/asset-manager/blob/5e6d282e8fb2775e9cb199bc485af4eb75376477/lib/services.rb#L6)].
  - ⚠ Missing contract tests for e.g. creation [[1](https://github.com/alphagov/content-publisher/blob/0c757447ca2aad3621f11c99fe8307a718ade186/app/services/preview_asset_service.rb#L29)] [[2](https://github.com/alphagov/specialist-publisher/blob/8debeb2f0147142c87f22308d57fe4f6dd0c1297/app/models/attachment.rb#L49)].
  - Code coverage is 97% [[1](https://github.com/alphagov/asset-manager/pull/802)].

- ❌ [authenticating-proxy](https://github.com/alphagov/authenticating-proxy)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/authenticating-proxy/blob/1f9078827a27879ca305d77e75d0b327074801c0/config/routes.rb#L2)]:
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/authenticating-proxy/blob/1f9078827a27879ca305d77e75d0b327074801c0/config/mongoid.yml)].
  - Code coverage is 97% [[1](https://github.com/alphagov/authenticating-proxy/pull/218)].

- ❌ [bouncer](https://github.com/alphagov/bouncer)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/bouncer/blob/d4c0daa8445028025a6d962a7f100ac1aa687d6a/lib/bouncer/outcome/healthcheck.rb)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/bouncer/blob/d4c0daa8445028025a6d962a7f100ac1aa687d6a/lib/active_record/rack/connection_management.rb)].
  - Code coverage is 98% [[1](https://github.com/alphagov/bouncer/pull/264)].

- ❌ [cache-clearing-service](https://github.com/alphagov/cache-clearing-service)
  - ⚠ Missing Smoke test for the app running
  - Code coverage is 99% [[1](https://github.com/alphagov/cache-clearing-service/pull/321)].

- ❌ ckan ([ckanext-datagovuk](https://github.com/alphagov/ckanext-datagovuk))
  - Special case: not a GOV.UK app ([developed externally](https://github.com/KSP-CKAN/CKAN)).

- ❌ [collections](https://github.com/alphagov/collections) ([already enabled])
  - Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/smokey/pull/731)].
    - Check for connectivity to Memcached.
  - Missing contract tests for organisations API [[1](https://github.com/alphagov/govuk-rfcs/pull/128#discussion_r515248179)].
  - Code coverage is 98%.

- ❌ [collections-publisher](https://github.com/alphagov/collections-publisher)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to MySQL [[1](https://github.com/alphagov/collections-publisher/blob/c4a1e8eaf79ed37c50324b3d76c5f67b68f019dc/config/database.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/collections-publisher/blob/c4a1e8eaf79ed37c50324b3d76c5f67b68f019dc/config/sidekiq.yml)].
  - ⚠ Code coverage is 93% [[1](https://github.com/alphagov/collections-publisher/pull/1134)].

- ❌ [contacts-admin](https://github.com/alphagov/contacts-admin)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/contacts-admin/blob/f85a699aaad2be685e2f8faebdf3a42e70960eae/config/routes.rb#L4)].
     - Check for connectivity to MySQL.
  - ⚠ Code coverage is 91% [[1](https://github.com/alphagov/contacts-admin/pull/790)].

- ❌ [content-data-admin](https://github.com/alphagov/content-data-admin)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/content-data-admin/blob/b0e4c926c83dbb4c42add4aa23e91b73314331e5/config/routes.rb#L4)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/content-data-admin/blob/b0e4c926c83dbb4c42add4aa23e91b73314331e5/config/database.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/content-data-admin/blob/b0e4c926c83dbb4c42add4aa23e91b73314331e5/config/sidekiq.yml)].
  - Code coverage is 98% [[1](https://github.com/alphagov/content-data-admin/pull/839)].

- ❌ [content-data-api](https://github.com/alphagov/content-data-admin)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/content-data-api/blob/53c43dff1850ba95ca85bdef3ee67c0a72b391a5/config/routes.rb#L16)]:
    - Check for connectivity to Postgres.
    - Check for connectivity to Redis.
  - APIs only have a single live consumer: Content Data Admin [[1](e2e-interactions.md)].
  - Code coverage is 96% [[1](https://github.com/alphagov/content-data-api/pull/1534)].

- ❌ [content-publisher](https://github.com/alphagov/content-publisher)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/content-publisher/blob/d7e5c1cb001cc70fadd6c04d24ab3bd1c7589f46/app/controllers/healthcheck_controller.rb)]:
    - Check for connectivity to Postgres.
    - Check for connectivity to Redis.
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/content-publisher/blob/d7e5c1cb001cc70fadd6c04d24ab3bd1c7589f46/config/storage.yml)].
  - Code coverage is 98% [[1](https://github.com/alphagov/content-publisher/pull/2156)].

- ❌ [content-store](https://github.com/alphagov/content-store)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint (draft and live) [[1](https://github.com/alphagov/content-store/blob/4108942c99abf086b1ea2ce00bc9ec3757f3ad44/config/routes.rb#L15)]:
     - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/content-store/blob/4108942c99abf086b1ea2ce00bc9ec3757f3ad44/config/mongoid.yml)].
  - ⚠ Missing contract test for content API [[1](https://github.com/alphagov/email-alert-frontend/blob/dd3005dae1e99790d29460bc863ee57bc2394bbf/app/controllers/content_item_signups_controller.rb#L66)] [[2](https://github.com/alphagov/finder-frontend/blob/97b1da432811104a20076e9e81d7e8ee4598ff08/app/controllers/finders_controller.rb#L86)].
  - ⚠ Code coverage is 68% [[1](https://github.com/alphagov/content-store/pull/762)].

- ❌ [content-tagger](https://github.com/alphagov/content-tagger)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/content-tagger/blob/69a0d60ee2cc616bacf437c99e00b66e315632f5/config/routes.rb#L70)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/content-tagger/blob/69a0d60ee2cc616bacf437c99e00b66e315632f5/config/database.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/content-tagger/blob/69a0d60ee2cc616bacf437c99e00b66e315632f5/config/sidekiq.yml)].
  - ⚠ Missing tests for JavaScript [[1](https://github.com/alphagov/content-tagger/tree/e9cb37423b7b7cf4b88bd0f5a63c04dc957f6be3/app/assets/javascripts)].
  - ⚠ Code coverage is 92% [[1](https://github.com/alphagov/content-tagger/pull/1129)].

- ❌ [email-alert-api](https://github.com/alphagov/email-alert-api)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/email-alert-api/blob/d6b26bdd4848f5c0c122bf7f06b2615603e4afae/app/controllers/healthcheck_controller.rb)]:
    - Check for connectivity to Postgres.
    - Check for connectivity to Redis.
  - ⚠ Missing contract tests for frontend APIs [[1](https://github.com/alphagov/finder-frontend/blob/97b1da432811104a20076e9e81d7e8ee4598ff08/app/lib/email_alert_signup_api.rb#L31)] [[2](https://github.com/alphagov/email-alert-frontend/blob/dd3005dae1e99790d29460bc863ee57bc2394bbf/app/models/content_item_subscriber_list.rb#L6)] and backend [[1](https://github.com/alphagov/email-alert-service/blob/b93acff5ac7de5089a9c1b9e27c8edd5bfc15f74/email_alert_service/models/email_alert.rb#L15)] [[2](https://github.com/alphagov/travel-advice-publisher/blob/0d053f95b5656da9128757e20ef3157422f8eb3b/app/notifiers/email_alert_api_notifier.rb#L9)] APIs.
  - ⚠ Code coverage is 94% [[1](https://github.com/alphagov/email-alert-api/pull/1400)].

- ❌ [email-alert-frontend](https://github.com/alphagov/email-alert-frontend)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/email-alert-frontend/blob/a32156a677f3989623faf6953de6aa4c8e073e29/config/routes.rb#L43)]:
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/email-alert-frontend/blob/a32156a677f3989623faf6953de6aa4c8e073e29/app/services/verify_subscriber_email_service.rb#L52)].
  - Code coverage is 98% [[1](https://github.com/alphagov/email-alert-frontend/pull/869)].

- ❌ [email-alert-service](https://github.com/alphagov/email-alert-service)
  - ⚠ Missing Smoke test for healthcheck:
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/email-alert-service/blob/bb686bc7ac86435164946a9751a7c893ff6ff3e1/email_alert_service/models/lock_handler.rb#L96)].
  - Code coverage is 98% [[1](https://github.com/alphagov/email-alert-service/pull/398)].

- ❌ [feedback](https://github.com/alphagov/feedback)
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/feedback.feature#L7)].
  - ⚠ Missing tests for JavaScript [[1](https://github.com/alphagov/feedback/tree/5363c98e6c6e55871b01279d50349ea3682b6d32/app/assets/javascripts)].
  - Code coverage is 97% [[1](https://github.com/alphagov/feedback/pull/1083)].

- ✅ [finder-frontend](https://github.com/alphagov/finder-frontend) ([already enabled])
  - Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/finder_frontend.feature#L11)]:
    - Check for connectivity to Memcached [[1](https://github.com/alphagov/finder-frontend/blob/827a3dbee42a16917a6823e0fd8c2d07ebf10212/config/environments/production.rb#L6)].
  - Code coverage is 97%.

- ❌ [frontend](https://github.com/alphagov/frontend)
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/frontend.feature#L12)].
  - ⚠ Missing contract test for bank holidays API [[1](https://github.com/alphagov/smart-answers/blob/cf2c69430e3abae5ef949321469162a35e651ce1/lib/working_days.rb#L6)] [[2](https://github.com/alphagov/publisher/blob/ebbaee15f760087ce2b735f75d7c15ca58b73742/lib/working_days_calculator.rb#L28)].
  - Code coverage is 98% [[1](https://github.com/alphagov/frontend/pull/2472)].

- ✅ [government-frontend](https://github.com/alphagov/government-frontend) ([already enabled])
  - Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/smokey/blob/a79d996ef2756313855f1dcbacc85cb5b93a51ef/features/government_frontend.feature#L69)]:
    - Check for connectivity to Memcached.
  - Code coverage is 98% [[1](https://github.com/alphagov/government-frontend/pull/1852)].

- ❌ [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas)
  - Special case: support library with its own E2E tests [[1](https://github.com/alphagov/govuk-content-schemas/blob/87e58b64fbefedef3b29cd06304d50e2e304fa48/Jenkinsfile)].
  - ⚠ Code coverage is 73% [[1](https://github.com/alphagov/govuk-content-schemas/pull/1018)].

- ❌ [govuk_crawler_worker](https://github.com/alphagov/govuk_crawler_worker)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/govuk_crawler_worker/blob/a5a0ded96e899caec285eda412544cb279817b64/main.go#L148)]:
    - Check for connectivity to Redis.
  - ⚠ Code coverage unknown [[1](https://github.com/alphagov/router/pull/161#discussion_r503235260)].

- ❌ [hmrc-manuals-api](https://github.com/alphagov/hmrc-manuals-api)
  - ⚠ Missing Smoke test for the app running.
  - APIs are not consumed by any GOV.UK apps [[1](e2e-interactions.md)].
  - Code coverage is 95% [[1](https://github.com/alphagov/hmrc-manuals-api/pull/521)].

- ❌ [imminence](https://github.com/alphagov/imminence)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/imminence/blob/8669e7aa2aecf2bba306ea9430299ec7b4788959/config/mongoid.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/imminence/blob/8669e7aa2aecf2bba306ea9430299ec7b4788959/config/redis.yml)].
  - Missing contract tests for e.g. places API [[1](https://github.com/alphagov/govuk-rfcs/pull/128#discussion_r515248179)].
  - ⚠ Code coverage is 94% [[1](https://github.com/alphagov/imminence/pull/581)].

- ✅ [info-frontend](https://github.com/alphagov/info-frontend)
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/info_frontend.feature)].
  - Code coverage is 99% [[1](https://github.com/alphagov/info-frontend/pull/748)].

- ❌ [licence-finder](https://github.com/alphagov/licence-finder)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to Elasticsearch [[1](https://github.com/alphagov/licence-finder/blob/b76c4c1df8071fb04f26b3fb27fc9db03046fbd7/config/elasticsearch.yml)].
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/licence-finder/blob/b76c4c1df8071fb04f26b3fb27fc9db03046fbd7/config/mongoid.yml)].
  - ⚠ Missing tests for JavaScript [[1](https://github.com/alphagov/licence-finder/tree/1cfc1a4b6125be6a2c9683998fd15260aeac2ce7/app/assets/javascripts)].
  - ⚠ Code coverage is 89% [[1](https://github.com/alphagov/licence-finder/pull/841)].

- ❌ [licensify](https://github.com/alphagov/licensify)
  - Special case: not a GOV.UK app ([maintained externally](https://docs.publishing.service.gov.uk/apps/licensify.html#ownership)).

- ❌ [link-checker-api](https://github.com/alphagov/link-checker-api)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/link-checker-api/blob/444bf6ad63ad1c3028cfcd2519c2bfddb8dd9ed2/config/routes.rb#L2)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/link-checker-api/blob/444bf6ad63ad1c3028cfcd2519c2bfddb8dd9ed2/config/database.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/link-checker-api/blob/master/config/sidekiq.yml)].
  - ⚠ Missing contract tests for e.g. batch create [[1](https://github.com/alphagov/publisher/blob/2d10ec917c01b470dea7c19446a2c4714c772ae6/app/services/link_check_report_creator.rb#L48)] [[2](https://github.com/alphagov/whitehall/blob/95b39f5ff9d46db83320ed7eaf6debc7d8b615b4/app/services/link_checker_api_service.rb#L24)].
  - ⚠ Code coverage is 94% [[1](https://github.com/alphagov/link-checker-api/pull/411)].

- ❌ [local-links-manager](https://github.com/alphagov/local-links-manager)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/local-links-manager/blob/29855548a76dd41f4163bb6b7b217466872269b3/config/routes.rb#L4)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/local-links-manager/blob/29855548a76dd41f4163bb6b7b217466872269b3/config/database.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/local-links-manager/blob/29855548a76dd41f4163bb6b7b217466872269b3/app/lib/services.rb#L6)].
  - ⚠ Code coverage is 94% [[1](https://github.com/alphagov/local-links-manager/pull/704)].

- ✅ [manuals-frontend](https://github.com/alphagov/manuals-frontend)
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/manuals_frontend.feature#L10)].
  - Code coverage is 97% [[1](https://github.com/alphagov/manuals-frontend/pull/971)].

- ❌ [manuals-publisher](https://github.com/alphagov/manuals-publisher)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/manuals-publisher/blob/12b4d94d429509d32bccc01554ae1b5fba5ceec6/config/routes.rb#L45)]:
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/manuals-publisher/blob/12b4d94d429509d32bccc01554ae1b5fba5ceec6/config/mongoid.yml)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/manuals-publisher/blob/12b4d94d429509d32bccc01554ae1b5fba5ceec6/config/sidekiq.yml)].
  - Code coverage is 97% [[1](https://github.com/alphagov/manuals-publisher/pull/1661)].

- ❌ [mapit](https://github.com/alphagov/mapit)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/mapit/blob/b24ae72d7a3508aa866522cbdf61074836b13522/project/settings.py#L81)].
  - ⚠ Missing contract tests for e.g. postcode lookup [[1](https://github.com/alphagov/collections/blob/d0a7286456f9b0792a0a5f5e1abc2acb65715ebf/app/services/location_lookup_service.rb#L52)] [[2](https://github.com/alphagov/imminence/blob/b537a004d21d4defaf7d29b5c9712a6b39963c4a/app/controllers/areas_controller.rb#L18)].
  - ⚠ Code coverage unknown.

- ❌ [maslow](https://github.com/alphagov/maslow)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/maslow/blob/80c12a2c15bace7609c06eac1ee5e991f2c792ce/config/routes.rb#L4)]:
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/maslow/blob/80c12a2c15bace7609c06eac1ee5e991f2c792ce/config/mongoid.yml#L14)].
    - Missing check for connectivity to Memcached [[1](https://github.com/alphagov/maslow/blob/80c12a2c15bace7609c06eac1ee5e991f2c792ce/config/environments/production.rb#L54)].
  - API only has a single live consumer: Whitehall [[1](e2e-interactions.md)].
  - ⚠ Code coverage is 87% [[1](https://github.com/alphagov/maslow/pull/627)].

- ✅ [publisher](https://github.com/alphagov/publisher) ([already enabled])
  - Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/smokey/blob/a79d996ef2756313855f1dcbacc85cb5b93a51ef/features/publisher.feature)]:
    - Check for connectivity to Redis.
    - Check for connectivity to MongoDB.
  - Code coverage is 97% [[1](https://github.com/alphagov/publisher/pull/1336)].

- ❌ [publishing-api](https://github.com/alphagov/publishing-api) ([already enabled])
  - ⚠ Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/smokey/blob/a79d996ef2756313855f1dcbacc85cb5b93a51ef/features/publishing_api.feature)]:
    - Check for connectivity to Postgres.
    - Check for connectivity to Redis.
  - ⚠ Missing contract tests for e.g. expanded links [[1](https://github.com/alphagov/publisher/blob/ebbaee15f760087ce2b735f75d7c15ca58b73742/app/lib/tagging/link_set.rb#L6)] [[2](https://github.com/alphagov/whitehall/blob/fe3b0e3a76959ca1326748bf116104828f790b67/app/models/document/needs.rb#L35)].
  - ⚠ Code coverage is 90% [[1](https://github.com/alphagov/publishing-api/pull/1848)].

- ❌ [release](https://github.com/alphagov/release)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/release/blob/bd623a9905305695a9f8de35fcd6b0ae50bcf903/app/controllers/application_controller.rb#L18)]:
    - Missing check for connectivity to MySQL [[1](https://github.com/alphagov/release/blob/bd623a9905305695a9f8de35fcd6b0ae50bcf903/config/database.yml#L19)].
  - ⚠ Code coverage is 92% [[1](https://github.com/alphagov/release/pull/699)].

- ❌ [router](https://github.com/alphagov/router)
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/router.feature#L8)].
  - ⚠ Code coverage unknown [[1](https://github.com/alphagov/router/pull/161#discussion_r503235260)].

- ❌ [router-api](https://github.com/alphagov/router-api)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/router-api/blob/0121ebe49ae59d2f58367b0f1e26914ca08ec050/config/routes.rb#L10)]:
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/router-api/blob/0121ebe49ae59d2f58367b0f1e26914ca08ec050/config/mongoid.yml)].
  - APIs only have a single live consumer: Content Store [[1](e2e-interactions.md)].
  - ⚠ Code coverage is 90% [[1](https://github.com/alphagov/router-api/pull/347)].

- ❌ [search-api](https://github.com/alphagov/search-api)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/search-api/blob/1e7205c40eca1e57403ff4820f565740a75e112b/lib/rummager/app.rb#L310)]:
    - Check for connectivity to Elasticsearch.
    - Check for connectivity to Redis.
    - Check for connectivity to Tensorflow.
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/search-api/blob/1e7205c40eca1e57403ff4820f565740a75e112b/lib/rummager/app.rb#L331)].
  - ⚠ Missing contract tests for search [[1](https://github.com/alphagov/finder-frontend/blob/80e265c3b6be25e42a4108480d698bdd60f19642/app/lib/registries/people_registry.rb#L46)] [[2](https://github.com/alphagov/collections/blob/7bc125e5670ecba7b85a3918c8b02d339b0368d9/lib/services.rb#L20)].
  - ⚠ Code coverage is 92% [[1](https://github.com/alphagov/search-api/pull/2182)].

- ❌ [search-admin](https://github.com/alphagov/search-admin)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to MySQL [[1](https://github.com/alphagov/search-admin/blob/a2dd7a3f8882fa7b658632bb346beefcab69ae45/config/database.yml#L22)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/search-admin/blob/a2dd7a3f8882fa7b658632bb346beefcab69ae45/config/sidekiq.yml)].
  - ⚠ Missing tests for JavaScript [[1](https://github.com/alphagov/search-admin/tree/e0b3195f67039f1035361d730e7fd2db4a789a6d/app/assets/javascripts)].
  - ⚠ Code coverage is 85% [[1](https://github.com/alphagov/search-admin/pull/481)].

- ❌ [service-manual-frontend](https://github.com/alphagov/service-manual-frontend)
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/service_manual.feature#L7)].
  - ⚠ Code coverage is 92% [[1](https://github.com/alphagov/service-manual-frontend/pull/777)].

- ❌ [service-manual-publisher](https://github.com/alphagov/service-manual-publisher)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/service-manual-publisher/blob/29f9f932f3e87df17c7a8d54a4a60e3a9605f174/config/routes.rb#L2)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/service-manual-publisher/blob/29f9f932f3e87df17c7a8d54a4a60e3a9605f174/config/database.yml#L21)].
  - Code coverage is 97%.

- ❌ [short-url-manager](https://github.com/alphagov/short-url-manager)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/short-url-manager/blob/c00ee5ac4ec56d442b3ceefa6c104fcf4d95dcc4/config/routes.rb#L13)]:
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/short-url-manager/blob/c00ee5ac4ec56d442b3ceefa6c104fcf4d95dcc4/config/mongoid.yml#L9)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/short-url-manager/blob/c00ee5ac4ec56d442b3ceefa6c104fcf4d95dcc4/config/redis.yml#L9)].
  - Code coverage is 97% [[1](https://github.com/alphagov/short-url-manager/pull/526)].

- ❌ [sidekiq-monitoring](https://github.com/alphagov/sidekiq-monitoring)
  - ⚠ Missing Smoke test `/healthcheck` endpoint:
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/sidekiq-monitoring/blob/db5faf0140239fad06c3245d490999701ce69eda/config.ru)].
  - Special case: app has very little code and no tests [[1](https://github.com/alphagov/sidekiq-monitoring/blob/master/config.ru)].

- ❌ [signon](https://github.com/alphagov/signon)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/signon/blob/034b65579d60f03732595ccfd714f7ac265562c4/config/routes.rb#L2)]:
    - Check for connectivity to Postgres / MySQL.
    - Check for connectivity to Redis.
  - ⚠ Code coverage is 84% [[1](https://github.com/alphagov/signon/pull/1505)].

- ✅ [smart-answers](https://github.com/alphagov/smart-answers) ([already enabled])
  - Smoke test for the app running [[1](https://github.com/alphagov/smokey/blob/e0c62f0dbc6742ba04fd9c3b231ccc7b32e20424/features/smartanswers.feature#L14)].
  - Code coverage is 97% (needs fix to cope with parallelisation [[1](https://github.com/simplecov-ruby/simplecov/issues/718)]).

- ❌ [specialist-publisher](https://github.com/alphagov/specialist-publisher)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/specialist-publisher/blob/496503762f9b19847ff3c1e391226b03ac63e012/config/routes.rb#L2)]:
    - Check for connectivity to Redis.
    - Missing check for connectivity to MongoDB [[1](https://github.com/alphagov/specialist-publisher/blob/496503762f9b19847ff3c1e391226b03ac63e012/config/mongoid.yml#L17)].
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/specialist-publisher/blob/496503762f9b19847ff3c1e391226b03ac63e012/app/lib/s3_file_uploader.rb)].
  - ⚠ Missing tests for JavaScript [[1](https://github.com/alphagov/specialist-publisher/tree/8391549c8564e50cb0af3973742b5fed59ede278/app/assets/javascript)].
  - Code coverage is 96%.

- ❌ [static](https://github.com/alphagov/static)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/static/blob/cd0b6d2ac14db8ec9bec21c49cdcbac8fb015b6b/lib/emergency_banner/display.rb#L5)].
  - ⚠ Missing contract tests for templates [[1](https://github.com/alphagov/slimmer/blob/64482b28572a7d038827de214832317e75f0c1ae/lib/slimmer/skin.rb#L34)] [[2](https://github.com/alphagov/email-alert-frontend/blob/5dce6ef63ae97259b47dd2dc3869a3f83825589b/app/controllers/application_controller.rb#L2)] [[3](https://github.com/alphagov/frontend/blob/9fdfefcb11b9c1ef1653c7330d263ed042564d81/app/controllers/application_controller.rb#L3)].
  - ⚠ Code coverage for JavaScript unknown [[1](https://github.com/alphagov/govuk-rfcs/pull/128#discussion_r511936377)].
  - ⚠ Code coverage for Ruby is 65% [[1](https://github.com/alphagov/static/pull/2298)].

- ❌ [support](https://github.com/alphagov/support)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/support/blob/7b0ef907f143decabd64a1d073cd5461b7616d7e/app/models/support/requests/anonymous/paths.rb#L31)].
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/support/blob/7b0ef907f143decabd64a1d073cd5461b7616d7e/app/controllers/anonymous_feedback/export_requests_controller.rb#L81)] [[2](https://github.com/alphagov/support-api/blob/8d1b5dc375a4618f91b0221d71a3f9ab35217d7c/lib/s3_file_uploader.rb#L2)].
    - Missing check for connectivity to Zendesk [[1](https://github.com/alphagov/support/blob/7b0ef907f143decabd64a1d073cd5461b7616d7e/app/controllers/accounts_permissions_and_training_requests_controller.rb#L47)].
  - APIs only have a single live consumer: Feedback [[1](e2e-interactions.md)].
  - Code coverage is 97% [[1](https://github.com/alphagov/support/pull/822)].

- ❌ [support-api](https://github.com/alphagov/support-api)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/support-api/blob/9c8583e70a621899429ea053f5f8719c00b793c2/config/routes.rb#L70)]:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/support-api/blob/9c8583e70a621899429ea053f5f8719c00b793c2/config/database.yml#L21)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/support-api/blob/9c8583e70a621899429ea053f5f8719c00b793c2/config/sidekiq.yml)].
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/support/blob/7b0ef907f143decabd64a1d073cd5461b7616d7e/app/controllers/anonymous_feedback/export_requests_controller.rb#L81)] [[2](https://github.com/alphagov/support-api/blob/8d1b5dc375a4618f91b0221d71a3f9ab35217d7c/lib/s3_file_uploader.rb#L2)].
  - APIs only have single live consumers: Support or Feedback [[1](e2e-interactions.md)].
  - ⚠ Code coverage is 90% [[1](https://github.com/alphagov/support-api/pull/499)].

- ❌ [transition](https://github.com/alphagov/transition)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint:
    - Missing check for connectivity to Postgres [[1](https://github.com/alphagov/transition/blob/d7caaf29f30dccc0008a2251dca07bf060c2f8da/config/database.yml#L27)].
    - Missing check for connectivity to Redis [[1](https://github.com/alphagov/transition/blob/d7caaf29f30dccc0008a2251dca07bf060c2f8da/config/sidekiq.yml)].
  - ⚠ Code coverage is 89% [[1](https://github.com/alphagov/transition/pull/1000)].

- ✅ [travel-advice-publisher](https://github.com/alphagov/travel-advice-publisher) ([already enabled])
  - Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/smokey/blob/924f49d762dd618e7d8d15ef8a8eef38003e678e/features/travel_advice_publisher.feature)]:
    - Check for connectivity to MongoDB.
    - Check for connectivity to Redis.
  - Code coverage is 97% [[1](https://github.com/alphagov/travel-advice-publisher/pull/981)].

- ❌ [whitehall](https://github.com/alphagov/whitehall)
  - ⚠ Missing Smoke test for `/healthcheck` endpoint [[1](https://github.com/alphagov/whitehall/blob/4d1de9a6818041994f555ae40164b08cd85f043e/config/routes.rb#L418)]:
    - Check for connectivity to Redis.
    - Check for connectivity to MySQL.
    - Missing check for connectivity to Memcached [[1](https://github.com/alphagov/whitehall/blob/4d1de9a6818041994f555ae40164b08cd85f043e/config/environments/production.rb#L61)].
    - Missing check for connectivity to AWS S3 [[1](https://github.com/alphagov/whitehall/blob/4d1de9a6818041994f555ae40164b08cd85f043e/lib/s3_file_handler.rb)].
  - ⚠ Missing contract tests for world locations API [[1](https://github.com/alphagov/finder-frontend/blob/80e265c3b6be25e42a4108480d698bdd60f19642/app/lib/registries/world_locations_registry.rb#L46)] [[2](https://github.com/alphagov/smart-answers/blob/57b41bea27ed793e51b101467bd4616a4265e324/app/models/world_location.rb#L18)].
  - ⚠ Code coverage is 90% [[1](https://github.com/alphagov/whitehall/pull/5818)].

[already enabled]: https://github.com/alphagov/govuk-puppet/blob/c24ff191ce7fc8a38ceb464f0139faba04b9734b/hieradata_aws/common.yaml#L1162
