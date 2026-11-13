# Revision-bound carcass design state

Date:13 November2026. Original JP design for the next autonomous slice. Base e99a97e7c64452c3fa5ad1809cb8e475fed2e6b5. It closes design22's construction-intent persistence gap without claiming host acceptance or a complete general furniture model.

## Authority and alternatives

Choose one explicit `jpimos.carcass-design/1` authoring envelope owning a project-core component and ordered construction requests. Rejected alternatives: inject unknown fields into closed project-core/1, or persist unrelated preview requests in a second live store. No historical/full-project schema is silently migrated. Old core and preview APIs remain compatible and useful as independent components.

State fields are exactly schema,project,construction_requests. project is jpimos.project-core/1 and owns the single project ID/revision. construction_requests is an authored array of existing jpimos.carcass-request/1 values. Every article must have exactly one request in this profile; no duplicate/unknown/missing article coverage. Empty project+empty requests is valid. Maximum requests100 and existing article/byte/work quotas apply. Material references remain caller-declared/unverified catalog refs. The profile supports only the current four-panel principle.

Core document remains a component, not another independently accepted live state once owned by a design. Codec canonicalizes project/requests with existing field orders and retains authored array order. Unknown fields, imported snapshots, unsupported/newer schema and malformed sources fail explicitly. No legacy source data is dropped or reinterpreted.

## Public API

Namespace JPImosPro::Design:
- validate(state:,limits:{}) ->Result<immutable State>;
- encode(state:,limits:{}) ->Result<canonical UTF-8 JSON>;
- decode(source:,limits:{}) ->Result<immutable State>, duplicate-aware bounded JSON;
- prepare_revision(current:,replacement:,expected_revision:,numeric_policy:,limits:{}) ->Result<PreparedDesign>.

PreparedDesign fields:project_id,base_revision,next_revision,state,snapshot. expected_revision equals current.project.revision; replacement keeps that project ID/revision; success sets state.project.revision=current+1. All semantic authoring changes, including construction thickness/material/layers or request order, require one revision increment. Hash property order is insignificant. Exact no-op ->E_NO_CHANGE. Existing overlapping definition versions remain immutable; no global registry is claimed.

CarcassDesignSnapshot fields:schema=jpimos.carcass-design-snapshot/1,profile_version=jp-carcass-design-v1,project_id,source_revision,state_sha256,policy_id,backend_id,zone_snapshot,carcass_previews,diagnostics[]. All source revisions agree with the prepared state. State hash binds canonical complete authoring, including construction intent; each unchanged existing preview retains its project/request digest contract. Previews preserve request array order; occurrence refs stay article+role.

## Build and failure semantics

Validate/copy current and replacement once each, sharing one CoreBudget. Validate revision and immutable-definition guards without a second public API/budget. Compare the whole owned state, including requests. No-op/stale/max checks precede policy/geometry work. Prepare an owned next project/state root; full zone resolution occurs once per snapshot. Reuse a trusted internal construction builder for each already validated request, using the same zone snapshot and project digest, rather than recursively invoking public build_carcass and resetting budgets.

All numeric policy checks, material contexts, requests, frame/volume math and resource limits are existing policies. Construction failure in any article yields value=nil, no partial state/snapshot, no caller mutation or global revision change. Inputs are frozen only in owned copies. Pointer prefix /current or /replacement distinguishes authoring; project fields append /project and request entries append /construction_requests/i, retaining expression spans/context. Policy errors remain /numeric_policy. Resource exhaustion halts immediately.

Trusted validate_owned helpers may avoid duplicate copies only after the enclosing state has passed the existing bounded plain-data copy; public core/request entry points retain their copy/type guards. Public request/state data cannot choose that trusted route or pass callback validators/meters. Semantic comparisons are iterative and metered. Normalized project digest is computed once and shared by internal preview calls.

Prepared is not Accepted. No files, model dictionaries, host entities, undo stack or accepted-session pointer is mutated here. A future SketchUp adapter must apply/store this entire authoring envelope and matching source context in one operation. The current snapshot is profile-specific and does not certify sourced catalog data, BOM quantities or full-furniture export.

## Independent fixtures

DS01:lossless round-trip, sq text/ratios, canonical Hash order, deep freeze; plain project/snapshot unsupported.
DS02:unknown fields/duplicate JSON keys/newer schema, duplicate request, missing/unknown article coverage fail; empty state succeeds.
DS03:current revision7, request left18->19 with unchanged project fields ->next8 in state/zones/all previews; new left bbox19, opening563; no-op reordered keys ->E_NO_CHANGE.
DS04:W600->800 and thickness edit together ->one increment, source digests/state hash change; stale/max/bad definition pin uses existing guard behavior.
DS05:two articles/two requests yield8 panels with distinct refs; bad second thickness/principle/math fails atomically; request order remains semantic and correctly bound.
DS06:shared resource exhaustion and fresh recovery, frozen callers, malformed policies and safe integer maximum; no nested public operation resets.

Qualify with real Ruby2.7.8/3.2.9 and all74 baseline tests/1260 assertions. Preserve historical14 and existing public APIs. No SketchUp loader/RBZ, host compatibility claim, general material inheritance, backs/fronts or manufacturing functionality is introduced.
