# Atomic host application implementation plan

> For agentic workers: use superpowers:executing-plans task-by-task under the user's standing execution authorization; independent branch review before integration. Tasks1–3 are implemented with standalone validation; Tasks4–6 remain planned and unqualified.

**Goal:** apply one declared unbanded rectangular project and its source in one controlled native operation, then prove rollback/undo/reopen consistency.

**Architecture:** bounded source-derived projection, closed host document, one per-Model-incarnation authority and opaque leases/candidates. A model port isolates transaction control from SketchUp calls; the first native port mutates registered scratch models only.

**Tech stack:** existing original Ruby modules, Ruby2.7 minimum, Minitest and Ruby standard library only.

**Spec:** [atomic-host-contract.md](atomic-host-contract.md).

## Global constraints

- First profile is `jp-host-unbanded-scratch-v1`; production dispatch remains disabled.
- No eval engine, external authoring sidecar, loader/RBZ or proprietary assets.
- Existing public source/checkpoint APIs and all132 baseline tests remain compatible.
- One existing CoreBudget per read/preparation; no raising/resetting max100,000 work/1MiB JSON.
- One cumulative native visit budget per read/apply, default/max50,000; caller can only lower limits.
- Source identity is authored UUID; native PID hints are decimal strings, never JSON numbers or authority.
- Host profile limits: solid edge extent at least0.1mm, absolute world vertex coordinate at most1,000,000mm, finite conversion;0.001mm vertex tolerance and volume policy from spec. These JP limits need native qualification.
- No mutation from observer callbacks; no operation nesting/active_path changes or automatic repairs.

## Review focus

- Two controllers for one Model must share authority and invalidate each other's candidates.
- Undo/redo restoring identical bytes must not make an old candidate valid again.
- Commit/abort uncertainty must retain quarantine across reattachment and ordinary reads.
- Empty accepted projects must work without an empty native Group.
- A manual/foreign child or translated article must not be silently overwritten or double-transformed.

Every item has tests below. A fake port establishes controller behavior only; it is never evidence for SketchUp rollback, geometry tolerances or event ordering.

## Task1 — bounded world projection and checkpoint reuse

Files: create `lib/jp_imos_pro/host/projection.rb`, `test/host/projection_test.rb`; modify checkpoint internals only to add trusted `record_from_owned_resolution(state:, snapshot:, numeric_policy:, budget:) -> owned Hash`. Public checkpoint encode/decode behavior stays unchanged.

Interface: `Host::Projection.build(state:, numeric_policy:, limits:{}) -> Result<PreparedProjection>`. PreparedProjection has private construction and owned frozen state/snapshot/checkpoint_record/plan/plan_sha256; it is not a wire input. Plan fields are exactly those in spec§4. Trusted `Projection.from_owned_resolution(state:, snapshot:, numeric_policy:, budget:)` reuses an already rebuilt resolution for Tasks2–3, checking its project/revision/policy bindings without another geometry rebuild. Resolve the physical source once; encode its checkpoint from that same trusted resolution. No native methods are called.

- [x] Write tests H-P01..H-P06 first: translated fixture bounds exactly left[100,200,300]..[118,760,1020], top[118,200,1002]..[682,760,1020]; width800 top maxX882; local basis not applied twice; source-index layer coverage; empty project parts[]; caller ownership/hash stability.
- [x] Add H-P07 limits:0.1mm layer accepted;0.099mm layer refused; world-bound vertex at1,000,000mm accepted and1,000,000.001mm refused. The exact coordinate bound also precludes nonfinite conversion from supported input; no native mutation exists here.
- [x] Run `ruby test/host/projection_test.rb`; missing entry-point assertion failed before implementation.
- [x] Implement projection plus trusted checkpoint record extraction under one shared budget. Captured baseline checkpoint SHA fixtures preserve byte compatibility on both real test backends.
- [x] Run focused and `ruby test/all_test.rb` in both real runtimes. All baseline/new tests pass; capped work fails with value=nil and fresh default succeeds. See [validation](projection-validation.md).

## Task2 — canonical host-document codec

Files: create `lib/jp_imos_pro/host/document_codec.rb`, `test/host/document_codec_test.rb`.

Interfaces: `Host::DocumentCodec.encode(state:, root_id:, acceptance_id:, manifest:, numeric_policy:, limits:{}) -> Result<String>` rebuilds source via Task1 and checks manifest shape/coverage. `decode(source:, numeric_policy:, limits:{}) -> Result<DecodedDocument>` rebuilds source/plan but does **not** accept native geometry or mint a lease. Trusted internal `encode_owned(projection:, root_id:, acceptance_id:, manifest:, budget:) -> String` reuses private Task1 output during a native operation. `decode_with_budget(source:, numeric_policy:, budget:)` is the shared internal read path. Extract `PhysicalCheckpoint.rebuild_owned_record(record:, numeric_policy:, budget:)` from its existing decoder, preserving all format/checksum/rebuild checks; DocumentCodec passes only its bounded parsed checkpoint object. Reuse Task1's owned-resolution projection helper after this one rebuild; do not nest public boundaries or reset counters.

- [x] Write H-D01..H-D07: closed schema, checksum repair with stale plan/source refused; duplicate/missing part/component rejected; PID string2^64-1 accepted without float conversion, leading-zero/overflow/JSON-number hints refused; unknown profile; empty document root_id=null/manifest empty; nonempty root_id UUID; source/checkpoint backend mismatch.
- [x] Run `ruby test/host/document_codec_test.rb`; missing entry-point assertion failed before implementation.
- [x] Implement the experimental document exactly as spec§3. Host IDs remain hints; this pure codec makes no native-ownership claim.
- [x] Run focused and complete suites on Ruby2.7.8/3.2.9, verify deterministic canonical output and resource refusal. See [validation](document-codec-validation.md).

## Task3 — shared authority, read leases and explicit recovery

Files: create `lib/jp_imos_pro/host/registry.rb`, `lease.rb`, `reader.rb`, `preparation.rb`, `recovery.rb`; tests `test/host/session_test.rb`, `test/host/reader_test.rb`, and a test-only port/tree utility.

Interfaces: exactly Reader/Preparation/Recovery from spec§5. Registry.attach on the same trusted ModelAnchor returns the same authority; ModelAnchor retains the native Model reference plus native open-incarnation nonce. All candidate/lease constructors are private and registry-issued object identities are checked. Native access is supplied by a trusted Port, never parsed from JSON. Task1 output carries new source/plan. Extract `PhysicalState.prepare_revision_with_budget(current:, replacement:, expected_revision:, numeric_policy:, budget:)` from the existing public revision boundary with unchanged validation/guards/scoped diagnostics; Host preparation shares its budget and reuses the resolved output through Task1's trusted helper.

Read-port contract: `anchor`, `controlled_grant`, `document_json`, `edit_path_open?`, `inspect_empty(budget:)` and `inspect_projection(plan:, root_id:, manifest:, budget:, staging:nil)`. Inspections return private observed handles/mapping only after tree/geometry validation. Every enumerated entity is charged. The test port uses a real owned tree and independent inspection rules, not just a mocked success boolean.

- [x] Write H-S01..H-S09: two attachments share identity/guard/counter; second read invalidates first lease; cross-model/clone/unregistered-copy lease refusal; manual root move, wrong face/quad and foreign child fail; copied root/orphan tags fail; stale PID hint recovers in RAM without writes; accepted empty differs from no document; source imported snapshot/frame injection fails.
- [x] Add H-S10 ABA: gateway primitive invalidates synchronously before identical-byte restoration; old candidate remains rejected. Delayed notification alone is not the test mechanism. Native action wiring remains Task5.
- [x] Add H-S11 recovery: indeterminate quarantine survives attach/read; only fresh controlled grant + complete valid source/tree inspection rotates shared epoch and enables preparation. Failed inspection preserves quarantine and does not repair.
- [x] Run focused tests; missing authority entry-point assertion failed before implementation.
- [x] Implement per-model-incarnation authority, leases and candidates; controlled lifecycle primitives and one-use settled grants; quarantine makes ordinary reads read-only and preparation returns E_HOST_RECOVERY_REQUIRED. Application remains Task4.
- [x] Run full suites on both runtimes, including invalid source/resources. See [session validation](session-validation.md). No native compatibility claim.

## Task4 — transaction controller against a conformance port

Files: create `lib/jp_imos_pro/host/application.rb`, `test/host/application_test.rb`; extend only the test port utility.

Interface: `Host::Application.apply(context:, candidate:, limits:{}) -> Result<verified Lease/binding>` follows spec§6. Mutation-port methods are begin_operation(name), stage_projection(projection:, root_id:, budget:), remove_root(handle), write_document(json), inspect_projection(...), commit_operation and abort_operation. Native hints are available only after staging; trusted document encoding must reuse the prepared source/plan rather than rebuild it inside the operation.

The conformance port retains before/after source and trees and supports explicit stage/attribute/erase/commit/abort fault injection. Assertions inspect complete resulting source/tree and unrelated sentinel data, not merely method call counts.

- [ ] Write H-A01 initial application, H-A02 width600→800 and grain edit preparing revision7→8 with stable logical part IDs; metadata and geometry move together; unrelated sentinel and probe dictionary unchanged.
- [ ] Write H-A03 failures after first solid, before/after old-root removal and during source write: verified abort restores original source/tree exactly, value=nil and mutation_state=rolled_back.
- [ ] Write H-A04 reentrant apply and document change after begin: reject/abort without publishing new lease; candidate replay remains rejected.
- [ ] Write H-A05 commit false/exception, abort failure and post-commit observer mutation: mutation_state=unknown, quarantine retained, no automatic undo/repair.
- [ ] Write H-A06 nonempty→empty→nonempty: no empty Group dependency, stable project ID/revisions, new root UUID after an empty state. H-A07 capped visits during staging attempts one abort; if remaining capacity cannot verify restoration, return unknown/quarantine with E_RESOURCE_LIMIT cause. No counter reset or unconditional rolled_back assertion.
- [ ] Run focused tests; Expected: missing controller RED. Implement main-thread/guard/CAS and single-use candidate protocol, then full dual-runtime suites. Commit.

## Task5 — experimental native port and controlled harness

Files: create `lib/jp_imos_pro/host/native_port.rb`, `test/host/native_support.rb` and a manually invoked `test/host/native_qualification.rb`. They must not register an extension or execute automatically when pure core is loaded.

Interfaces: Port from Tasks3–4. NativePort creation requires an opaque registry-issued ControlledContext registered by the harness for an exact newly saved workspace scratch copy and current Model incarnation. Unknown/generic model dispatch returns E_HOST_QUIESCENCE_UNPROVEN. The controller/harness supplies an explicit idle assertion; observers cannot manufacture one. This is a cooperative scratch-environment condition, not a solution for arbitrary foreign operations or a security barrier against arbitrary Ruby execution.

- [ ] Add port contract tests for denied unregistered paths/models, missing grant, edit path, locked root, global orphan scan cap and cyclic container traversal. Expected: RED until guards exist.
- [ ] Implement only Group-based geometry from exact world vertices, mm→inches once, strict topology/normal/coverage inspection, experimental attributes and PID hints. Use supported SDK methods only; no silent active_path switching or transparent operations.
- [ ] Add observer registration/lifecycle invalidation and gateway before-action invalidation. No observer performs native writes. Document the opaque native-anchor binding and how open/close revokes an incarnation.
- [ ] Full standalone suites must pass, but report native cases NOT RUN until Task6. Commit.

## Task6 — actual SketchUp qualification and release gate

Files: maintain qualification evidence outside Git; create original analysis in `docs/phase-02i/native-validation.md` only after actual observation. Do not publish SKP/PNG/source manuals.

- [ ] H-N01 initial apply and H-N02 resize600→800 on a separate saved model: compare accepted record/rebuilt plan to native vertices/volumes/IDs and unchanged outside-root sentinel. Native faces must pass profile tolerances; exact host/Ruby version recorded.
- [ ] H-N03 controlled undo/redo restores the matching source and geometry in each direction; an old revision8 candidate stays invalid after undo7/redo8. Invalidate before native action and wait for settled completion before reading.
- [ ] H-N04 forced pre-commit failure verifies native abort of both source and staged geometry. H-N05 stale/reentrant requests do not overwrite. H-N06 indeterminate/post-observer conflict remains read-only until explicit recovery; record any untestable SDK behavior as unqualified.
- [ ] H-N07 save, switch away, reopen and full application restart are separate cases; backend binding and semantic mapping survive or fail explicitly. Never discard unsaved user changes.
- [ ] H-N08 native0.1mm/world-limit boundary qualification and below/above-profile refusals; H-N09 empty-project transitions; H-N10 duplicate/orphan/manual-edit/locked-root refusals.
- [ ] Independent review of code + actual evidence, dual-runtime full suites and public-content checks. Publish via PR. General production namespace, foreign-operation isolation, external native dependencies and backend migration remain BLOCKED even if the scratch profile passes.

## Plan audit and current status

Tasks1–2 are pure source/projection contracts;3–4 prove session/controller behavior;5–6 are the conditional native boundary. All spec sections and five review-focus risks map to explicit tests above. Tasks1–3 are implemented and standalone tested. Tasks4–6 remain pending; this does not qualify native atomic application.
