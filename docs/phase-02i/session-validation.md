# Shared host session authority

Date:17 November2026. Task3 of the [host plan](atomic-host-implementation-plan.md), implementing the pure lifecycle/read/preparation slice of [contract§5](atomic-host-contract.md). No SketchUp model was changed. All model trees in these tests are original synthetic data in a test-only mutable port.

## Implemented boundary

`Reader.read(context:,numeric_policy:,limits:{})` reads source, rebuilds the document/projection and asks the trusted port to inspect the tree. It returns an immutable process-only Lease. `Preparation.initial(lease:,state:,numeric_policy:,limits:{})` and `Preparation.revision(lease:,replacement:,expected_revision:,numeric_policy:,limits:{})` return private Candidate objects; neither writes geometry or source. `Recovery.read(context:,fresh_grant:,numeric_policy:,limits:{})` performs the same complete inspection before clearing shared quarantine and rotating the epoch. All Results declare mutation_state=unchanged and failed Results have value=nil.

The trusted Registry lifecycle uses `open(model:)`, `attach(port:)`, `issue_grant(context:)` and `close(anchor:)`. One authority retains each live model reference by object identity plus a fresh incarnation nonce. Attachments to that anchor share counters, busy guard, leases, candidates and quarantine. Close revokes the old authority; reopening even the same wrapper creates a new anchor. Lease/Candidate/Context constructors are private. Registration checks object identity, so dup/clone/unregistered objects fail; opaque objects refuse Marshal persistence. This is process identity, not cryptographic protection from arbitrary Ruby code.

The authority exposes trusted lifecycle primitives `before_action!`, `notify_external!`, `quarantine!` and `with_guard`. A controlled harness must call before_action synchronously before native undo/redo/save/open/close/abort/switch dispatch. It must issue a fresh one-use settled grant only after the controlled action finishes. Observer callbacks may invalidate/quarantine but may not mint settled grants or write a model. These methods do not query SDK operation state or demonstrate general foreign-operation isolation. Native wiring is pending Tasks5–6.

Each read attempt consumes its grant and invalidates previous objects before inspection; a successful read publishes the new sequence. Failed reads therefore conservatively invalidate older objects too. Candidates are registered with immutable body, while consumed status remains in the authority. Ordinary reads can inspect quarantined state but yield read-only leases. Reattachment does not clear quarantine. Recovery requires a fresh unused grant and complete inspection; failure preserves quarantine and performs no repair.

## Data ownership and budgets

The reader retains exact frozen raw document bytes/SHA256, source/project revision and hash via its owned projection, accepted root/acceptance IDs in the document, policy, sequence and epoch. Observed PID hints can differ from stored hints without rewriting the document. The port supplies an Inspection with a borrowed mapping and opaque root handle; Reader copies/validates/freezes the mapping under the same CoreBudget before publishing it. Native handles themselves are never frozen or serialized.

Read/preparation uses one cumulative CoreBudget, existing work100,000/JSON1MiB maxima. Source byte size is checked before duplication. One separate VisitBudget is passed through every port inspection, with default/max50,000, lowered via limits.entity_visits. Negative/zero/noninteger charges are refused. Source work and visit limits are never reset. `PhysicalState.prepare_revision_with_budget` extracts the existing guarded revision path; public API behavior and baseline tests remain intact. The candidate projection/checkpoint reuse that one resolved revision rather than rebuilding physical geometry again.

The mutable test tree has roots/parts/solids, tags, transforms, locks, actual vertices and directed face loops. Inspection independently compares tree coverage, identity transforms, coordinates and directed quads; scans outside the owned root catch copied/orphan tags and ancestor cycles. Every visited node and inspected vertex/face is charged. The test fixture generator uses the source plan to populate geometry; inspection then reads the actual mutable tree rather than a stored success flag. This strict exact synthetic comparison does not qualify native tolerance, solid volume/manifold behavior, SDK event timing or undo.

## Evidence

| Tests | Verified synthetic behavior |
|---|---|
| H-S01..02 | Shared authority/guard/counter; second read invalidates older leases; reentry refused |
| H-S03 | Duplicated/unregistered/Marshal objects and another model with identical document bytes/IDs cannot transfer candidate authority; close/reopen revokes prior incarnation |
| H-S04..06 | Root move, wrong quad/vertex, foreign child, copied root, orphan tags, locked geometry and cyclic scan fail without rewriting source |
| H-S07 | Stale/null PID hints resolve to actual tree hints in RAM; raw source unchanged |
| H-S08..09 | Accepted empty differs from no document; imported snapshots and injected source frames refused; old physical transition guards/policy/revision retained |
| H-S10 | Controlled invalidation before identical-byte restoration makes the old candidate permanently stale; candidate consumption is single-use |
| H-S11 | Quarantine survives attachment/ordinary read; old used grant and failed recovery cannot clear it; fresh successful recovery rotates epoch and permits preparation |
| Additional | Edit path, wrong thread, source/event changes during inspection, resource caps, invalid port mapping and negative visit charge fail explicitly |

Focused commands: `ruby test/host/session_test.rb` and `ruby test/host/reader_test.rb`. Initial missing-authority assertion was observed RED before implementation. Invalid port mapping, negative visit charges and raw adapter exceptions were separately observed RED before their fixes. Adapter StandardError is translated to E_HOST_CONTEXT_UNSUPPORTED and retains shared quarantine; existing domain faults remain unchanged and pure-core programming errors are not hidden. Full `ruby test/all_test.rb` on real Ruby2.7.8/x64-mingw32 and Ruby3.2.9/x64-mingw-ucrt: each172 tests/2319 assertions,0 failures,0 errors,0 skips.

## Remaining gate

Independent whole-branch review reproduced the escaped adapter exception, confirmed its scoped fix and independently reran both full suites172/2319. No must-fix findings remain. One deferred minor: the test-only tree scanner pre-enqueues synthetic collections before visit charging. The future NativePort must use bounded incremental enumeration/allocation rather than copy that fixture pattern; this is part of its Task5 resource gate.

Application/CAS/native mutation/verified rollback remains Task4, actual native adapter Task5, actual SDK undo/abort/reopen/restart qualification Task6. No native transaction, controller or installable plugin is supplied by this unit. No proprietary source assets were added. General production dispatch and full imos equivalence remain unqualified.
