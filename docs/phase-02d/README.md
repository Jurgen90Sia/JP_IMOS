# Phase 2D: revision-bound carcass design state

The owning authoring envelope closes the gap between a project-core component and separate construction previews. See [spec24](../phase-01/24-carcass-design-state-spec.md), [plan25](../phase-01/25-carcass-design-state-implementation-plan.md), [qualification](validation.md) and [host readiness](host-readiness.md).

```ruby
require_relative 'lib/jp_imos_pro/design'
state = {
  'schema' => 'jpimos.carcass-design/1',
  'project' => project_core_document,
  'construction_requests' => [carcass_request]
}
encoded = JPImosPro::Design.encode(state: state)
decoded = JPImosPro::Design.decode(source: encoded.fetch(:value))
prepared = JPImosPro::Design.prepare_revision(
  current: decoded.fetch(:value), replacement: edited_state,
  expected_revision: decoded.fetch(:value).fetch('project').fetch('revision'),
  numeric_policy: {
    policy_id: 'jp-rational-binary64-15-v1',
    backend_id: "#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"
  })
```

Every article has exactly one closed existing carcass request in this profile. Duplicate, unknown or missing coverage fails. Empty projects with no requests are valid. The root owns exactly schema/project/construction_requests; imported previews, snapshots, plain project-core records or newer schemas are rejected, never silently wrapped or stripped. The public validate/encode/decode methods return the existing Result pattern with immutable owned state or canonical UTF-8 JSON.

## One revision for all authored intent

The project component owns the single ID/revision. Editing only left thickness18->19 against current7 prepares8 in the state, zone snapshot and all previews. The opening becomes563mm wide without changing unrelated project values. A width edit and thickness edit together still increment once. Request order, explicit values and source metadata remain semantic; Hash property order does not create a change.

PreparedDesign={project_id,base_revision,next_revision,state,snapshot}. Snapshot schema is jpimos.carcass-design-snapshot/1, with profile/project/revision, canonical whole-state SHA256, policy/backend IDs, one zone_snapshot, ordered carcass_previews and diagnostics[]. All nested output is frozen; caller state/policy is not mutated or newly frozen. Snapshot revision and every preview context revision match the prepared state.

Guards retain expected-revision/safe-integer/no-op rules and immutable overlapping definition versions. Failure returns value=nil with no partial state/snapshot. Prefixes identify current/replacement, their owned project, and request index; engine spans/context survive wrapping. Validation and runtime request failures select lexical pointer order while successful preview arrays retain authoring order. Resource exhaustion stops immediately.

## Shared work and component compatibility

One CoreBudget covers both input copies/validations, comparison, numeric policy, full zone resolution, material contexts, geometry, hashing and freezing. Zones and canonical project digest are built once per design snapshot. Trusted internal owned-validation/preview helpers avoid nested public calls or counter resets. They are never selected by source fields or imported snapshots; existing public core/preview APIs retain their own guards and unchanged tests.

Existing core/request schemas are unchanged. Once a design envelope is the host/session authoring authority, its project component and request list must not be independently published as competing stores. The current pure API prepares data only; it does not create a session acceptance pointer or files.

## Acceptance boundary

This is a profile-specific complete **prepared** state. Material references remain caller-declared/unverified catalog references, geometry remains the finished-envelope four-panel subset, and a complete accepted general PartSpec/material model is absent. No host dictionary/apply/undo contract has yet been implemented or qualified. These are actual dependencies for production host application/export, not bypassed by a matching hash.

There is no SketchUp execution/loader/RBZ or production exporter. Encode/decode persists authoring JSON only; it is not a furniture-output exporter or snapshot importer. A later accepted-state/host adapter must rebuild derived data from validated authoring, verify its supported schema/material/geometry contract, and apply canonical persistence plus geometry in one native operation.

Run `ruby test/all_test.rb`. Existing74 baseline tests remain included. No new runtime dependency, construction principle or proprietary source asset is added.
