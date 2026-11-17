# Atomic host application contract

Date:17 November2026. **PROPOSED original JP design; no adapter implemented by this document.** First profile: `jp-host-unbanded-scratch-v1`, controlled scratch models only. Standing user authorization covers choosing the design and proceeding without intermediate approval. Production host readiness remains BLOCKED until implementation and qualification.

## 1. Outcome, alternatives and scope

Apply one supported physical project so the native geometry and its canonical source describe the same accepted revision. A failed pre-commit application must restore both. Undo/redo must move both together. The model record is authoritative; Ruby objects are disposable projections.

Chosen approach: one owned root rebuilt from exact source plus one model-level record, changed in one nontransparent native operation. This preserves logical part IDs but deliberately does not promise stable native entity/face IDs after replacement. In-place topology editing would complicate rollback and identity tracking; an external JSON sidecar would create a second authority. Neither is used in this first profile.

Only existing explicit user-declared material policy, four-panel carcass rules, unbanded rectangular substrate/layer solids and translation-only article placements are supported. No renderer texture/grain qualification, manufacturer authority, drawing/hardware references, general contours, startup loader or RBZ is added. Existing probes and their dictionaries are never promoted automatically.

## 2. SDK facts and the controlled-context limit

SketchUp operations are sequential: beginning another operation can close an existing one. Changing the active editing path can introduce additional operations. Therefore apply requires no open edit path, never changes that path itself, and uses `model.entities`, not whichever active editing collection happens to be selected. [Model API](https://ruby.sketchup.com/Sketchup/Model.html#start_operation-instance_method).

Transaction observer events are delayed; observers cannot prove the absence of an open foreign operation. Observer callbacks must only invalidate session data or schedule later work, never mutate the model. [ModelObserver API](https://ruby.sketchup.com/Sketchup/ModelObserver.html).

**Decision:** there is no fabricated `operation_open?` check. Mutation requires a private `ControlledContext` issued by the native test harness for an exact registered scratch copy, an explicit idle test boundary and a cooperative test environment. Unknown transaction ownership returns E_HOST_QUIESCENCE_UNPROVEN before start_operation. Unsaved user edits/open contexts must be preserved or refused, not silently closed/discarded by the adapter. The harness may create a fresh saved copy in a user-authorized workspace. This controlled assertion is not a guarantee against arbitrary third-party extensions. General production dispatch remains out of scope and blocked.

## 3. One source record and strict ownership

Experimental namespace: model attribute dictionary `JP_IMOS_PRO_HOST_V1_EXPERIMENTAL`, key `accepted_document_json`. The value is canonical UTF-8 JSON. No other model key is authoritative. The existing `JP_IMOS_PRO_PHASE_02H_CHECKPOINT_PROBE` dictionary is unrelated and remains untouched.

Closed `jpimos.host-document/1` fields:

| Field | Rule |
|---|---|
| schema | `jpimos.host-document/1` |
| scope | `controlled_scratch` |
| profile | `jp-host-unbanded-scratch-v1` |
| project_id | UUID; equals the checkpoint's rebuilt project ID |
| root_id | UUID for a nonempty projection; null exactly when there are no parts |
| acceptance_id | Fresh UUID on every successful application; restored with the record by undo |
| checkpoint | Existing source-only checkpoint **object**; no duplicated source/snapshot store |
| projection | Closed derived manifest described below |
| content_sha256 | SHA256 of canonical other fields; consistency check, not a signature |

Projection manifest fields: schema=`jpimos.host-manifest/1`, plan_sha256, root_pid_hint and parts[]. Each part record has exactly part_id, container_pid_hint and solids[]. A solid entry has component=`substrate`/`surface`, source_index=null for substrate or the original nonnegative layer index for surface, and pid_hint. Every expected part/component occurs exactly once, with no extras. Part ordering follows the rebuilt physical snapshot; substrate precedes source-index ordered layers. Every hint field is present but may be null; root_pid_hint must be null for an empty projection. Non-null hints are canonical positive decimal strings with at most64bits, never JSON numbers.

Native persistent IDs are lookup hints only. A missing/stale hint triggers bounded lookup and validation by semantic tags; it does not authorize a different part or a source rewrite. Read-only recovery updates RAM hints only. Supported entity types expose persistent IDs, but logical identity remains the authored UUID. [Entity API](https://ruby.sketchup.com/Sketchup/Entity.html#persistent_id-instance_method).

Entity dictionary is the same experimental namespace, key `binding_json`. Closed tags have schema=`jpimos.host-entity/1`, kind and the following fields only:

- root: kind=root, root_id, project_id.
- part container: kind=part, root_id, part_id.
- solid group: kind=solid, root_id, part_id, component, source_index.

Exactly one top-level root Group is allowed for a nonempty accepted document. Its transform and all descendant container transforms are identity. Its children are exactly the declared part Groups; each contains exactly substrate and dimensional-surface Groups. Each solid has8 vertices/12 edges/6 outward faces. No finished-envelope proxies, other geometry, shared component definitions, hidden extra children or foreign entities are permitted inside this root. Empty projects store source/manifest with root_id=null and no owned root, avoiding dependence on empty-group persistence.

Unknown schema/profile, malformed record, orphan tags, duplicate/copied root tags, unknown children, locked geometry or missing/ambiguous ownership fail read/apply without cleanup. Scanning for tagged copies includes nested Group/ComponentInstance paths, bounded by the host visit budget and active-definition cycle detection. Extra unrelated entities outside the owned tree are preserved. External references into the owned tree are unsupported; the controlled fixtures must exclude them. A production claim about arbitrary dimensions, glue relationships or observer side effects requires later native qualification.

## 4. Rebuild and geometry comparison

A read validates the host envelope, decodes/rebuilds its checkpoint using the caller's qualified numeric policy, derives the expected projection and inspects actual entities. The manifest cannot waive inspection or import cached geometry as source. Old backend/profile versions fail clearly; no silent migration or repair.

For each part, `article_vertices` are already in article coordinates. Add the matching preview's `article_origin` exactly once to obtain world-mm vertices. Do not apply the part basis a second time. All containers stay at identity; the native boundary converts mm to inches once by division by25.4. Substrate/layer Groups are physical solids; a container need not itself report manifold volume. Selection, camera and display color are not source and do not affect semantic validation; hidden objects still count toward coverage.

Projection plan schema=`jpimos.host-projection/1`, profile, project_id, source_revision, state_sha256, catalog_sha256, policy_id, backend_id and parts[]. Each part has part_id and solids[]; each solid contains component/source_index, world_vertices in exact Length/mm DTOs, existing face_loops and expected exact volume DTO. plan_sha256 is stored outside the plan body and hashes all canonical plan fields. The plan contains no native IDs.

JP host restrictions for this profile, **proposals requiring native qualification**: minimum solid edge extent0.1mm; absolute world coordinate at most1,000,000mm. Float conversion must be finite. These are conservative supported-profile limits, not asserted SketchUp/manufacturer tolerances. Unsupported inputs fail before mutation, never thicken/resize automatically. Actual vertex matching must be bijective within0.001mm per axis, with exact supported topology/coverage and outward normals; ambiguous matching fails. Every native quad must match exactly one expected face's four vertices, with the expected outward normal; bounding-box agreement alone is insufficient. Native positive volume must differ by at most max(0.000001mm³, expected_volume*1e-8). Do not use rounded native-coordinate hashes instead of geometric comparison.

Independent translated fixture: article origin[100,200,300], W600/D560/H720 and18mm finished panels gives left bounds[100,200,300]..[118,760,1020], top bounds[118,200,1002]..[682,760,1020]. W800 changes the top maximum X to882. Grain/identity come from policies; placement/shape always come from rebuilt source.

## 5. Lease, preparation and stale-state protection

Public operations return the existing Result pattern. Task3 implements Reader/Preparation/Recovery against trusted ports with synthetic standalone tests; see [session validation](session-validation.md). Task4 implements Application against the synthetic conformance port; see [application validation](application-validation.md). Actual native wiring/qualification remain planned:

| API | Input / success |
|---|---|
| Host::Reader.read(context:, numeric_policy:, limits:{}) | Read/inspect only; returns a private immutable Lease for an empty or valid accepted model |
| Host::Preparation.initial(lease:, state:, numeric_policy:, limits:{}) | Only a model without accepted document or experimental orphan tags; returns private Candidate |
| Host::Preparation.revision(lease:, replacement:, expected_revision:, numeric_policy:, limits:{}) | Uses PhysicalState.prepare_revision against the lease's owned current state; returns private Candidate |
| Host::Application.apply(context:, candidate:, limits:{}) | One native operation; returns verified new Lease and accepted source binding on success |
| Host::Recovery.read(context:, fresh_grant:, numeric_policy:, limits:{}) | Explicit read-only recovery inspection; only full success plus a new controlled grant restores mutation authority |

One `Host::Registry` authority exists per actual Model incarnation, shared by every context/port/reader/busy guard for that model. Registry attachment returns the existing authority, never an independent counter. The authority retains the Model reference plus an internally minted open-incarnation token; file paths, authored UUIDs and native IDs do not establish process identity. A native model-open/close transition revokes the old incarnation even if the SDK reuses a Ruby wrapper. Context/Lease/Candidate constructors are private, never wire JSON or Marshal imports.

Leases/Candidates retain this shared authority, random epoch, sequence, exact raw document SHA256 (nil for initial), acceptance/root IDs, source revision/hash, numeric policy and owned rebuilt data. The registry registers issued object identities; unregistered copies/Marshal recreations are rejected and apply reads only the registered immutable body. Consumption lives in the shared authority, not a mutable field inside a frozen candidate. A successful new read invalidates all older leases/candidates across every attachment to the same authority. Plans cannot transfer to another model, including another SKP clone with identical stored IDs.

These opaque objects protect the source/wire boundary; they are not a security barrier against arbitrary trusted-process Ruby execution. Hashes and namespace tags establish consistency/ownership conventions, not cryptographic authenticity.

The controlled harness/controller must invalidate the shared authority **synchronously before dispatching** known undo/redo, save/open/close, abort or model-switch actions. It holds the gate closed until the action settles and a full bounded read succeeds. Thus restoring old bytes after undo/redo does not revive old candidates (ABA). Delayed observer events provide additional invalidation, not the only ABA mechanism. Events outside the controlled gateway conservatively quarantine the authority until explicit recovery; arbitrary unobservable foreign transactions are excluded by the scratch-only assumption. No claim of intercepting all production user/extension actions is made. A candidate begun in apply is single-use, including an aborted attempt.

Preparation takes authoring only, not supplied physical snapshots or arbitrary host manifests. It performs existing project/definition/material-pin/part-identity guards and computes one new revision. Initial application may retain a valid imported author's revision. The controller generates root/acceptance UUIDs; these are host ownership IDs, not replacements for physical part IDs. A surviving nonempty project retains root_id across root replacement; transitioning through zero parts removes it and later creates a fresh root ID.

One CoreBudget (existing max100,000 work and1MiB JSON) covers each read or preparation. Do not raise/reset it or rebuild the entire candidate a second time just to encode a checkpoint: extract a trusted encode-from-owned-resolution helper while retaining the guarded public checkpoint API. apply consumes only its private prepared data. One native visit budget, default/max50,000 entity visits per read/apply, bounds scans/inspection/creation across all passes; caller limits can only lower it. Entity count caps are not throughput promises. Resource exhaustion before mutation has mutation_state=unchanged; after start it enters the abort protocol.

## 6. Native transaction protocol

All model access runs on SketchUp's main/UI thread. An in-memory per-model busy guard rejects same-model reentry before any native operation. Callback handlers never call apply or mutate source; they only invalidate/queue later reads.

1. Acquire guard; verify candidate model/epoch/sequence/not-consumed, explicit controlled idle context, no edit path, matching numeric policy and exact raw document bytes/hash. Inspect current owned tree against the base projection; detect external/manual changes and ownership conflicts. No write has occurred.
2. Consume candidate; begin exactly `start_operation('JP IMOS apply project', true)` with no transparent flags. No active_path change or nested operation is allowed.
3. Repeat the cheap document/lease checks immediately after start. Stage and inspect the candidate's new root; ignore the known old/staging pair only within this guarded internal phase. Do not publish session head yet.
4. After the new tree passes all checks, erase only the verified old owned root (if any), set final tags/manifest hints and the single canonical accepted_document_json attribute. Inspect final coverage, exact record bytes and geometry before commit. Never edit unrelated objects or a foreign child.
5. Commit once. Retain the busy guard through callbacks and verify stored bytes/tree afterward. Only verified success may publish a new Lease derived from the private candidate plus the final inspected native mapping/updated sequence. Do not re-run another public preparation under a reset budget.

Before commit, any exception/cancellation/refusal after start attempts exactly one abort. Verify restoration of the base document and owned tree within the remaining shared limits and invalidate candidate/session caches. Return failure value=nil. **Do not claim rollback if abort/verification failed.** The single constant-time abort attempt remains mandatory cleanup even when entity visits are exhausted; it does not grant further visits or reset a counter. If no budget remains for restoration inspection, report mutation_state=unknown and quarantine even when abort returned true. Preserve E_RESOURCE_LIMIT as the cause of the indeterminate diagnostic.

Outcomes:

| Outcome | Required result |
|---|---|
| Refused before start | Typed diagnostic; mutation_state=unchanged |
| Pre-commit failure, verified abort | E_HOST_APPLY_FAILED plus cause; mutation_state=rolled_back |
| Commit returned success and post-checks pass | ok=true; mutation_state=committed; new Lease |
| Commit exception/false, failed abort, or post-commit observer mutation | E_HOST_COMMIT_INDETERMINATE; mutation_state=unknown; invalidate context to read-only until explicit full recovery |

No automatic compensating write/undo is attempted after an indeterminate commit; that could undo unrelated observer/user work. Application commit is not a disk save. Save happens separately after a successful native operation.

Quarantine is stored in the shared authority. Ordinary Reader.read may inspect a quarantined model but yields a read-only lease; Preparation/Application return E_HOST_RECOVERY_REQUIRED. Reattaching/replacing a context cannot clear quarantine. Recovery.read requires a fresh private harness idle grant, full bounded envelope/checkpoint/projection/native-tree inspection, and settled callbacks. Only complete success rotates the shared epoch, revokes all earlier candidates and enables mutation. Failed recovery leaves quarantine intact and does not repair source/geometry. Actual model close/open also requires a fresh grant/full read before mutation; it is not a reset shortcut.

For every host Result, metadata.mutation_state is explicitly unchanged, rolled_back, committed or unknown. Failure value is nil; an indeterminate result must never be presented as rolled_back merely because an exception was caught.

## 7. Undo, redo and reopen

Undo/redo must restore source record and geometry together under the native operation. Callbacks invalidate RAM; the next explicit read rebuilds source/mapping and issues a fresh epoch/sequence lease. No observer writes a repaired record, replays a stale candidate, assumes native IDs survived or promotes a draft dictionary. Reopen follows the same bounded read/inspection; corrupted source/tree is an explicit conflict and remains untouched. Same-process reopen and full application restart are separate qualification cases.

## 8. Required diagnostics and readiness

Retain existing source/parser/material/geometry diagnostics. New proposed codes: E_HOST_CONTEXT_UNSUPPORTED, E_HOST_QUIESCENCE_UNPROVEN, E_HOST_EDIT_CONTEXT, E_HOST_REENTRANT, E_HOST_LEASE_CONFLICT, E_HOST_OWNERSHIP_CONFLICT, E_HOST_GEOMETRY_CONFLICT, E_HOST_GEOMETRY_UNREPRESENTABLE, E_HOST_APPLY_FAILED, E_HOST_COMMIT_INDETERMINATE and E_HOST_RECOVERY_REQUIRED. Unknown document schema/profile uses E_SCHEMA_UNSUPPORTED. Every refusal identifies a source pointer or host semantic part/root reference; failure value is nil and mutation_state is explicit.

The contract is not a passing implementation. Its controlled gate, source/geometry coupling, rollback, event/ABA behavior, observer interference, min-feature/world-bound limits and restart recovery must all be tested. General production namespace/dispatch, foreign-operation isolation, external native dependencies, manufacturer claims and backend migration remain blocked; none is inferred from the earlier draft checkpoint proof.

## 9. Design review disposition

Independent builder check identified per-model shared authority/ABA timing and explicit recovery from indeterminate commits; follow-up also identified the risk of exhausting visits before rollback verification. These were resolved in§5–6: a single registry authority per Model incarnation, synchronous gateway invalidation, shared quarantine/explicit recovery, and unknown/quarantine when an abort cannot be verified within remaining limits. These are design decisions, not passing runtime tests. No new user preference was needed under standing authorization. All implementation and native cases remain NOT RUN.
