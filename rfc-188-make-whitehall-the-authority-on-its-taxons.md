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
- Push a complete, authoritative set of taxon links to Publishing API:
  - as edition_links on draft save
  - as edition_links and link set updates on publish/republish

The list of available taxons (the taxonomy catalogue) will continue to be fetched and cached from the publishing stack.

## Problem

### User problem

After tagging an Edition with taxons in Whitehall, subsequent refreshes often do not reflect the change immediately, especially in the local dev environment.

This is caused by Whitehall reading taxon tagging from Publishing API at runtime while the update is processed asynchronously or cached (TBC: which?).

This results in:

- confusing UX ("did it save?")
- reduced trust in the system
- runtime coupling between Whitehall and Publishing API for editorial workflows
- friction and delays in local development

### Technical problem

Taxon tagging for Whitehall-managed content is currently treated as externally-owned state:

- Whitehall must query Publishing API at runtime to display tagging.
- Draft and live semantics are harder to reason about.
- Topic and world taxonomies must both be considered when reading/writing.
- Data flow differs from other Whitehall associations.

## Context

- Taxonomies (topic + world) are maintained outside Whitehall (in Content Tagger).
- Taxons are stored in Publishing API as content items.
- Publishing API stores links by `content_id`.
TODO: double-check the following definitions:
- Link sets are document-scoped (not edition-scoped).
- Edition links are draft-scoped and allow draft/live divergence.

Whitehall prefers draftable associations (e.g. organisations via edition_links) so that changes made on a draft edition do not affect the live edition until publish.

This RFC aligns taxon tagging with that model.

## Investigation: Publishing API behaviour

### Key findings

TODO: double-check and verify the below.

1. Taxons are not special in Publishing API.
   - They are just another link type: `"taxons"`.
   - There are no hardcoded business rules restricting which publishing app may set taxons.

2. Publishing API does not distinguish topic vs world taxonomy at storage level.
   - Both are stored under `"taxons"`.

3. Link sets are tied to `content_id` and are not edition-scoped.
   - Writing to link sets affects the document-level associations.

4. Edition links are draft-scoped and allow draft/live divergence.

5. Publishing API does not automatically merge partial link updates.
   - PATCHing links requires sending the full desired set.
   - Omitting links risks overwriting them.

6. Content Tagger writes taxons by mutating Publishing API link sets.
   - There is no enforcement that only Content Tagger may do so.

Conclusion:

There are no hidden business rules in Publishing API that prevent Whitehall from becoming authoritative for taxon tagging.

The main risk is partial overwriting of link sets, which can be mitigated by always sending the full combined set.

## Proposal

### 1. Persist taxons locally (edition-scoped)

Whitehall will store selected taxons per Edition.

This enables draft editions to differ from live editions.

Proposed model will be something like:

- `edition_taxon_links`
  - `edition_id`
  - `taxon_content_id`
  - `taxonomy_kind` (enum: `topic`, `world`)

When a new edition is created, it will inherit taxons from the previous edition.

### 2. Render from local persistence

Whitehall UI will render taxon tagging from `edition_taxon_links`.

Whitehall will no longer call Publishing API at runtime to determine which taxons an Edition is tagged to.

This removes:

- eventual-consistency issues
- runtime dependency on Publishing API
- cross-app state ambiguity

### 3. Draft vs Live semantics

Whitehall prefers draftable associations.

Therefore:

#### On save draft

- Taxons are written as edition_links only.
- Link sets are NOT updated.
- Live associations remain unchanged.

TODO: is there a case for dropping link set links altogether?

#### On publish / republish

- Taxons are written as edition_links.
- The document’s link set is updated via `PATCH /v2/links/:content_id`.
- The full combined set of topic + world taxons is sent.

This ensures:

- Draft changes do not affect live content prematurely.
- Link sets remain authoritative for live content.
- Downstream consumers receive correct associations.

### 4. Always send full combined taxon set

When updating link sets:

- Whitehall must always send the complete combined set of topic + world taxons.
- Partial updates are not permitted.

This avoids accidental overwriting of one taxonomy with another.

### 5. Continue fetching taxonomy catalogue

Whitehall will continue to fetch and cache the list of available taxons from the publishing stack.

This proposal changes tagging ownership, not taxonomy ownership.

## Migration Plan

### 1. Backfill

For each Whitehall document:

- Fetch existing taxon link sets from Publishing API.
- Populate `edition_taxon_links` for the latest edition.

Both topic and world taxons must be included.

### 2. Dual-read period (temporary)

For a limited period:

- Compare local taxon set vs Publishing API link set.
- Log diffs.
- Identify edge cases.

### 3. Switch UI reads

Switch Whitehall to render from local persistence only.

### 4. Switch publish writes

Update publish/republish flow to:

- Write edition_links
- PATCH link set with full combined taxon set

### 5. Remove runtime dependency

Remove all runtime reads of taxon tagging from Publishing API.

## Governance Considerations

After this change:

- Whitehall is authoritative for taxon tagging on Whitehall-managed content.
- If Content Tagger mutates taxons for Whitehall content, those changes will be overwritten on next republish.

Optional mitigations:

- Prevent Whitehall content from being edited in Content Tagger.
- Add validation/logging if non-Whitehall apps update taxons for Whitehall-owned content.

## Risks and Mitigations

### Risk: Partial link overwrites

Mitigation:
- Always send full combined taxon set on link set update.

### Risk: Draft save mutates live links

Mitigation:
- Do not update link sets on save draft.
- Only update link sets on publish/republish.

### Risk: Backfill misses world taxonomy

Mitigation:
- Explicitly backfill both topic and world taxons.
- Validate counts before switching.

### Risk: Unexpected downstream dependency on Content Tagger

Investigation shows:
- Downstream systems rely on link sets, not on Content Tagger as a writer.
- There are no hidden business rules coupling taxons to Content Tagger.

Mitigation:
- Dual-read phase and monitoring.

## Alternatives Considered

### Continue pulling from Publishing API

Pros:
- Single source of truth
Cons:
- Runtime coupling
- UX inconsistency
- Harder to reason about draft/live
- Requires careful topic/world handling on every read

### Optimistic UI but keep Publishing API authoritative

Pros:
- Less invasive
Cons:
- Does not align with “Whitehall is authoritative”
- Still runtime-coupled

### Make Content Tagger canonical for Whitehall content

Rejected:
- Whitehall is primary editorial interface.
- Cross-app editing causes ambiguity.

## Impact

- Immediate UX improvement for tagging.
- Reduced runtime coupling.
- Consistent association model across Whitehall.
- Clear ownership model for taxon tagging.
- Explicit handling of topic + world taxonomy together.
- Paves the way for easily configuring whether topic/world taxonomies should be required on a per-content type basis (following Whitehall's new config-driven approach).

## Success Criteria

- Tagging changes appear immediately after save.
- Draft tagging differs from live until publish.
- Publishing API link sets reflect correct combined taxon set after publish.
- Whitehall no longer depends on Publishing API for runtime taxon lookup.
