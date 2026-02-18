---
status: proposed
implementation: not_started
status_last_reviewed: 
---

# Make Whitehall authoritative for taxon tagging (topic + world) on Whitehall-managed content

## Summary

Whitehall currently pulls taxon tagging ("taxons") from Publishing API at runtime to determine which topics and worlds an Edition is tagged to.

This differs from other Whitehall associations (for example organisations), where Whitehall persists associations locally and pushes them to Publishing API at publish time.

This RFC proposes that, for Whitehall-managed content, Whitehall becomes the authoritative editor of taxon tagging for:

- the GOV.UK topic taxonomy, and
- the GOV.UK world taxonomy (legacy taxonomy).

Whitehall will:

- Persist selected taxons locally, scoped to Editions.
- Render taxon tagging from local persistence (removing eventual-consistency delays).
- Push a complete, authoritative set of taxon links to Publishing API, as edition_links

The list of available taxons (the taxonomy catalogue) will continue to be fetched and cached from the publishing stack.

It is also worth noting that this proposal makes Whitehall the canonical source of Topic/World Taxonomy associations for Whitehall content _only_. The RFC does not propose changing the canonical source of these associations for any non-Whitehall content, which remains the responsibility of Content Tagger.

### Benefits

- Eradicates the root cause of a race condition.
- Simplifies Whitehall and makes it more internally consistent.
- Enables different topic/world taxonomies on draft vs live content.
- Removes runtime coupling between Whitehall and Publishing API for tagging.

## Context

- Taxonomies (both topic + world) are:
  - Maintained outside Whitehall (in Content Tagger).
  - Stored in Publishing API as content items (see examples below).
  - Presented as a combined `taxons` link on content items ([example](https://www.gov.uk/api/content/government/publications/latvia-list-of-medical-facilities)).
- Publishing API [link lifecycles](https://docs.publishing.service.gov.uk/repos/publishing-api/link-expansion.html#link-lifecycles):
  - Link sets are document-scoped (not edition-scoped).
  - Edition links are draft-scoped and allow draft/live divergence.
- Whitehall prefers draftable associations (e.g. organisations via edition_links) so that changes made on a draft edition do not affect the live edition until publish.

Taxons are not special in Publishing API — they are stored as a standard `"taxons"` link type. There are no hardcoded rules requiring Content Tagger to be the canonical writer.

```rb
# Publishing API

topic_taxon = Document.find_by(content_id: "71f685fe-0dc3-469d-92c2-1000ad86d7d9").editions.last
=> 
#<Edition:0x0000ffff68066130
 id: 3359281,
 title: "River maintenance, flooding and coastal erosion",
 publishing_app: "content-tagger",
 rendering_app: "collections",
 update_type: "major",
 document_type: "taxon",
 schema_name: "taxon",
 first_published_at: "2018-03-08 16:32:37.000000000 +0000",
 last_edited_at: "2018-09-16 10:36:13.350772000 +0000",
 state: "published",
 content_store: "live",
 routes: [{"path" => "/environment/river-maintenance-flooding-coastal-erosion", "type" => "exact"}]>

world_taxon = Document.find_by(content_id: "7283f126-c578-4df7-949e-44662d4c086b").editions.last
=> 
#<Edition:0x0000ffff5e47a780
 id: 4682028,
 title: "Living in Latvia",
 publishing_app: "content-tagger",
 rendering_app: "collections",
 update_type: "major",
 document_type: "taxon",
 schema_name: "taxon",
 first_published_at: "2017-06-29 14:02:28.826713000 +0000",
 last_edited_at: "2020-03-03 16:56:27.160273000 +0000",
 state: "published",
 content_store: "live",
 routes: [{"path" => "/world/living-in-latvia", "type" => "exact"}]>
```

## Problem

Taxon tagging for Whitehall-managed content is currently treated as externally-owned state. Whitehall queries Publishing API at runtime to display tagging.

Consequences:

- Inconsistent with how Whitehall models other associations.
- Makes consolidation of a config-driven association architecture more difficult.
- Introduces runtime coupling to Publishing API.
- Code is more complex to reason about.
- Race conditions have been observed whereby saving new taxon selections takes time to “stick”, showing stale data on refresh.
  - This hinders local development (topic-less documents are invalid and cannot be force-published).
  - The issue has also been observed in integration.
- Taxon tagging is currently implemented as link set links, meaning draft changes immediately affect live associations.

## Proposal

### 1. Persist taxons locally (edition-scoped)

Whitehall will store selected taxons per Edition.

Proposed model:

- `edition_taxon_links`
  - `edition_id`
  - `taxon_content_id`
  - `taxonomy_kind` (enum: `topic`, `world`)

When a new edition is created, it will duplicate taxon links from the previous edition.

This enables draft editions to differ from live editions.

### 2. Render from local persistence

Whitehall UI will render taxon tagging from `edition_taxon_links`.

Whitehall will no longer call Publishing API at runtime to determine which taxons an Edition is tagged to.

Whitehall will continue to fetch and cache the list of available taxons from the publishing stack.

This proposal changes tagging ownership, not taxonomy ownership. The question of taxonomy ownership and governance is being investigated separately by the `#govuk-publishing-tagging-workflow` team.

### 3. Update Publishing API integration

Taxon links will no longer be managed via `patch_links`.

Instead, taxons will be sent via `put_content` as edition links, like Whitehall's other associations.

Whitehall must always send the complete combined set of topic + world taxons. Partial updates are not permitted.

At this stage we have fully editionable taxonomies — no further use of link sets for taxons.

## Implementation Plan

### Phase 1 – Introduce local persistence

- Create `edition_taxon_links`.
- Continue writing to Publishing API as currently implemented. In addition, write the taxon selections locally.
- Duplicate taxon links when new editions are created.
- Continue reading taxon selections from Publishing API. Do not yet switch rendering.

### Phase 2 – Backfill existing data

For each Whitehall document:

- Fetch existing taxon link sets from Publishing API.
- Populate/overwrite `edition_taxon_links` for both the live and draft editions (if applicable).
- Ensure both topic and world taxons are captured.

### Phase 3 – Switch read path

- Render taxon tagging from `edition_taxon_links`.
- Remove runtime reads from Publishing API.

### Phase 4 – Remove link set updates

- Remove `patch_links` usage for taxons.
- At this stage, taxonomies are updated solely on edition_links via `put_content`.

## Governance Considerations

After this change:

- Whitehall is authoritative for taxon tagging on Whitehall-managed content.
- If Content Tagger mutates taxons for Whitehall content, those changes will be overwritten on next republish.
- NB: Content Tagger as an application has [low and poorly defined usage](https://gds.slack.com/archives/C0A5B765LUV/p1771244116138289?thread_ts=1770918971.536859&cid=C0A5B765LUV) and has not received meaningful updates in several years.

Optional mitigations:

- Prevent Whitehall content from being edited in Content Tagger.
- Add validation/logging if non-Whitehall apps update taxons for Whitehall-owned content.

## Risks and Mitigations

### Risk: Partial link overwrites

Mitigation:
- Always send full combined taxon set via `put_content`.

### Risk: Draft save mutates live links

(Currently true under link set model.)

Mitigation:
- Remove `patch_links`.
- Use edition_links only, ensuring draft changes do not affect live until publish.

### Risk: Backfill misses world taxonomy

Mitigation:
- Explicitly backfill both topic and world taxons.
- Validate counts before and after switching.

### Risk: A taxon is deleted from Content Tagger

Mitigation:
- Update the [Taxonomy::RedisCacheAdapter](https://github.com/alphagov/whitehall/blob/07d624404ba3dd3fd06d5bbc241354c4a57ecb46/lib/taxonomy/redis_cache_adapter.rb#L1-L2) such that, on update, it cross-references all taxons by their content ID in the `edition_taxon_links` table and drops any rows where the taxon no longer exists.
- Note that this could lead to previously valid editions now being 'invalid' as a result of having their only topic taxonomy removed. This is considered a better situation than continuing to assume the edition is valid (which has been the cause of bugs - see [whitehall#10440](https://github.com/alphagov/whitehall/pull/10440)).

## Success Criteria

- Tagging changes appear immediately after save.
- Draft tagging differs from live until publish.
- Publishing API reflects correct combined taxon set after publish.
- Whitehall no longer depends on Publishing API for runtime taxon lookup.
