# Atomic application controller: synthetic conformance

Date:17 November2026. Task4 of the [host plan](atomic-host-implementation-plan.md), implementing [contract§6](atomic-host-contract.md) against a test-only mutable port. No SketchUp model was changed. A successful synthetic transaction is not evidence for actual SDK undo, abort, callbacks or native geometry behavior.

`Host::Application.apply(context:,candidate:,limits:{})` returns a verified new Lease only after one operation and post-commit inspection succeed. It consumes registered private Candidates, never a JSON snapshot/manifest. Source work and native visits retain one cumulative budget across preflight, staging, final inspection and any abort verification. Default/max visit limit remains50,000 and source limits remain work100,000/JSON1MiB.

## Protocol implemented

1. Acquire shared main-thread/reentry guard. Validate authority/candidate/lease, explicit current controlled grant, edit context and exact raw source bytes. Inspect the base tree; repeat cheap checks. No model write yet.
2. Consume the candidate. Mint root/acceptance identities and attempt exactly one `begin_operation('JP IMOS apply project')`. The native port contract normalizes begin/remove/write/commit/abort success to true; false is a failure. Even an ambiguous begin exception/false attempts one abort.
3. Recheck the base. Stage candidate geometry and inspect only the precisely identified old/staged pair as an internal exception to single-root coverage. Reinspect the old root immediately before removing it, ignoring only the known staged root; a newly inserted foreign old-root child must prevent erasure.
4. Create the canonical owned record from the already prepared source/checkpoint and observed mapping via `DocumentCodec.record_owned`; no second source/geometry rebuild. Erase only the freshly verified old root, write one canonical record, inspect final coverage and exact stored bytes, then commit once.
5. Inspect again after commit and repeat state checks through callbacks. Only then invalidate earlier process objects and publish the new owned Lease from private prepared data. The guard stays held throughout.

The root UUID survives nonempty replacement; acceptance UUID changes for every application. Empty projects use no native empty Group. A later nonempty revision creates a fresh root. Logical part IDs survive supported revisions; native handles/PIDs can change and remain hints.

## Failure states

| Situation | Result |
|---|---|
| Refused before begin attempt | Original typed error/value=nil, mutation_state=unchanged |
| Pre-commit failure and true abort plus complete restoration inspection | E_HOST_APPLY_FAILED, rolled_back; previous caches invalidated; candidate cannot replay |
| Abort false/exception or restoration cannot be verified within remaining limits | E_HOST_COMMIT_INDETERMINATE, unknown; shared quarantine |
| Commit false/exception, post-commit conflict/resource exhaustion, or lease-publication uncertainty | E_HOST_COMMIT_INDETERMINATE, unknown; no abort/undo/compensating write |
| Interrupt during an attempted pre-commit operation | Typed failure follows the same one-abort/verification protocol |
| Fatal exception outside StandardError/Interrupt | Best-effort one abort only before commit attempt, quarantine, then re-raise; no success/rollback Result asserted |

Diagnostics retain the full typed cause (including semantic entity reference/details), cause_code/cause_pointer and full rollback diagnostic/rollback_code/rollback_pointer where cleanup fails. Exhausted visits never grant a new verification budget. A constant-time abort attempt remains mandatory even when restoration cannot be inspected. Quarantine invalidation no longer requires fresh entropy: sequence advancement plus registered-object revocation suffices. Identity/epoch generation failures before begin are unchanged refusals; after commit they cannot prevent quarantine. Recovery still requires its own fresh grant and full read.

## Synthetic evidence

The test port retains actual before/after document/tree/extra dictionaries. Its memento abort restores those values; tests compare complete serialized data and preserve unrelated sentinel identity on successful replacement. This memento is a test mechanism, not a model of native handle/undo persistence. Faults cover begin, first actual solid, old-root erase, source write, commit and abort; callbacks can insert foreign geometry, change source or invalidate the authority. Geometry inspection reads actual mutable coordinates/directed quads and semantic tags rather than a Boolean success flag.

| Test IDs | Assertions |
|---|---|
| H-A01..02 | Initial apply; W600→800/grain edit revises7→8 with stable part/root IDs, new acceptance UUID, matching source/tree, unchanged unrelated sentinel/probe data |
| H-A03 | Fail after first solid, before/after erase and during source write; one abort and complete data equality; false/exception begin and cancellation also tested |
| H-A04 | Reentrant application refused; source changed after begin aborts; replay/clone/other-model/changed-source preflight refused |
| H-A05 | Commit false/exception, abort false, true abort with corrupted restoration, post-commit source/event/geometry changes all remain unknown/quarantined; no post-commit abort |
| H-A06 | Nonempty→empty→nonempty revisions7→8→9, no placeholder group, new root UUID after empty |
| H-A07 | Visits exhausted while staging still attempt abort once but cannot claim rollback; visits exhausted after commit also remain unknown without abort |
| Additional | Low-work preflight remains unchanged/unconsumed; explicit edit-context refusal; fatal cleanup/rethrow; entropy failures before begin and after commit |

Commands: `ruby test/host/application_test.rb` and `ruby test/all_test.rb` on real Ruby2.7.8/x64-mingw32 and Ruby3.2.9/x64-mingw-ucrt. Missing-controller assertion was RED before implementation. Entropy-failure and semantic-cause retention regressions were separately RED before fixes. Full suites on both runtimes pass194 tests/2599 assertions with0 failures,0 errors,0 skips; focused application suite passes22 tests/280 assertions.

## Pending native gates

Independent whole-branch review found no critical/important issues and reproduced both full suites194/2599. A preflight-only adapter failure can remain typed unchanged without quarantine because no operation began and a retry repeats all guards/CAS/tree checks; known external notifications still invalidate normally. The prior eager synthetic-scanner allocation minor remains deferred to NativePort's incremental enumeration gate.

NativePort/harness remains Task5 and actual SDK qualification Task6. The native observer integration must distinguish the controller's expected own transaction notifications from unexpected callbacks, keep the gate closed until settled, and detect actual post-commit interference; this synthetic controller does not qualify that wiring. The native harness must qualify the actual embedded numeric backend and controlled saved scratch context before granting dispatch. No general foreign-operation quiescence is inferred. Native inspection must enumerate incrementally within visit/allocation limits rather than copy the eager synthetic scanner pattern noted in Task3. No loader/RBZ, general production dispatch or full imos equivalence is delivered.
