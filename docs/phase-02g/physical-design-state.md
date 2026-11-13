# Revision-owned physical design: contract and implementation plan

Original JP supported profile, 13 November2026. Work proceeds under standing authorization without intermediate approval. No unresolved proprietary formula is assigned a guessed value.

## Owning authoring contract

`Design::PhysicalState` owns exactly schema=`jpimos.physical-design/1`, design (existing carcass-design/1), catalog (existing material-catalog/1) and part_policies. Its single project ID/revision is design.project.project_id/revision. It does not accept an independent revision or sidecar authority. No implicit import/migration from older design, previews, physical parts or snapshots occurs.

Each closed policy has exactly id(UUID part identity), article_instance_id(UUID), role(left/right/top/bottom), grain and edges using the existing physical-part contract. Every article has exactly one policy per role. IDs and article/role pairs are unique. References must exist in the design. Surface grain indices must cover that role's declared dimensional surfaces. All four edges explicitly say none. Policies normalize by article ID then role order; registry entries normalize by UUID/version, so their input order is not semantic. Request/article arrays retain existing authoring order.

Catalog refs resolve for every substrate/surface during validation. All provenance remains user_declared. Across prepared revisions, content of a surviving catalog UUID/version pin is immutable; changing it requires a new version. A surviving article/role keeps its part ID; an old part ID cannot be reassigned to another pair in that transition. Deletions can remove policies only with their article. This has no persistent tombstone/history registry beyond the compared states.

## API and derived boundary

Public APIs: validate(state:,limits:{}), encode(state:,limits:{}), decode(source:,limits:{}), resolve(state:,numeric_policy:,limits:{}) and prepare_revision(current:,replacement:,expected_revision:,numeric_policy:,limits:{}). All use the existing Result envelope. Validation/codecs return only owned authoring; resolve returns {state,snapshot}. Revision preparation additionally returns project_id/base_revision/next_revision. Expected-revision, safe-integer, project identity and immutable definition-version guards are inherited. No-op returns E_NO_CHANGE. Any semantic design/catalog/grain/edge change prepares exactly one increment; no mutable acceptance pointer or host model is written.

Snapshot schema=`jpimos.physical-design-snapshot/1`, profile=`jp-physical-design-v1`, status=`prepared_registry_bound_user_declared`. It contains project_id, source_revision, whole-authoring state_sha256, catalog_sha256, rebuilt design_snapshot, existing material_report, parts[], diagnostics[] and content_sha256. The material_report.state_sha256 binds the inner carcass design and equals design_snapshot.state_sha256; its scope is explicitly recorded as `design`. The outer state_sha256 also covers the registry and part policies. Snapshot content hash covers canonical JSON of every other snapshot field.

Parts follow construction request order then left/right/top/bottom. Each entry is {source_binding,part}. Binding has project_id/source_revision/whole-state state_sha256/catalog_sha256. The local part retains prepared_unbound_part status and caller-declared material status; the wrapper establishes its supported project/registry relationship, never manufacturer authority or production acceptance. Part ID/grain/edges come from the owned policy; owner zone, frame, dimensions and rule come only from freshly rebuilt project construction. Callers cannot inject dimensions or frames through policies.

One CoreBudget covers authoring copies/validation, reference resolution, policies, comparisons, zones, all geometry, hashing and freezing. Trusted internal owned helpers avoid nested public boundaries/counter resets. Failures return value=nil with no partially publishable state. New diagnostics: E_PART_IDENTITY_CONFLICT and E_MATERIAL_VERSION_CONFLICT. Existing typed diagnostics are preserved with scoped paths. Whole-state and snapshot hash canonicalization uses the existing bounded plain-data copying/JSON encoding convention.

## Chosen approach and plan

Chosen: an owning profile plus trusted helper composition. A list of physical parts attached to a material-bound preview would leave grain/edge edits outside the authored revision. An immediate SketchUp loader would bypass the unresolved transaction/persistence boundary. Existing public schemas/APIs remain unchanged.

Task1: create `design/physical_state.rb`, `design/physical_record.rb`, `design/physical_snapshot.rb` and `test/design/physical_state_test.rb`; extract owned helpers in existing design record and local physical builder; update README/readiness.

- [x] RED: owning codec, coverage, source/material binding, stable resize identities, grain-only and catalog-version revision edits, stale/no-op/exhausted revisions, source rejection, ownership and resource exhaustion.
- [x] Implement closed authoring and scoped diagnostics; no implicit policies or catalog characteristics.
- [x] Compose freshly resolved construction/local physical geometry under one budget and bind complete state/catalog hashes.
- [ ] Run focused/full suites in Ruby2.7.8 and3.2.9, review independently, publish and integrate.

Review focus: policy-only edits failing to increment; same material pin changing silently; forged frame/derived input accepted as authority; identity reassignment on resize; shared-budget reset while composing parts. All have corresponding tests. Project persistence, acceptance CAS, undo/reopen, host transaction qualification and general banded/nonrectangular parts remain future dependencies.

## Qualification ledger

Base main `96d7a403bdb66151dfc46c1cb8dfef74d8a748cb`, clean;111 baseline tests /1,607 assertions passed before changes. Isolated branch `feat/revision-bound-physical-design` reuses the clean linked checkout.

Task1 RED:10 missing-entry-point errors observed before implementation; first GREEN10 tests /123 assertions. Extended qualification caught a normalization diagnostic defect: reversing submitted policies caused conflict pointer index3 instead of the submitted index0. The regression failed before correction; submitted policy/catalog position maps now preserve original paths through normalization. Focused GREEN13 tests /145 assertions. Full real Ruby2.7.8 and3.2.9 runs:124 tests /1,752 assertions each, no failures/errors/skips, retaining all111 baseline tests.

Aggregate qualification: authoring validates under work16,000; full composition under work48,000 refuses atomically and deterministically; a new request at default limits succeeds. Resource ceilings can refuse larger otherwise-valid projects; count caps are not a throughput guarantee. Standalone native qualification of the local builder remains historical at its recorded source hash; this newly composed owning profile is NOT RUN in SketchUp.

No change in implementation scope or source interpretation was required. No host model dictionary, runtime acceptance pointer, loader, RBZ, export route, third-party implementation or proprietary asset is introduced.
