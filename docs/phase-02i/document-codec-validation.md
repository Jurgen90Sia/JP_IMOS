# Host document codec: source consistency

Date:17 November2026. Task2 of the [implementation plan](atomic-host-implementation-plan.md), implementing the document slice of [contract§3](atomic-host-contract.md). Original JP design with synthetic fixtures; this is not an imos format or a claim of full imos compatibility.

`Host::DocumentCodec.encode(state:,root_id:,acceptance_id:,manifest:,numeric_policy:,limits:{})` returns canonical JSON after rebuilding source and checking coverage. `decode(source:,numeric_policy:,limits:{})` returns an immutable `DecodedDocument` with `document` and rebuilt `projection`. Every Result declares mutation_state=unchanged. No native geometry is inspected or accepted, and no lease is minted.

The closed document stores one source-only checkpoint object, experimental scope/profile, project/root/acceptance UUIDs, a manifest and a canonical SHA256. The manifest must exactly match derived part order and substrate/source-indexed surface coverage. An empty project requires null root ID/null root hint/no parts. Missing or duplicate parts, extra fields, stale plan hashes, unsupported profiles, malformed identities and mismatched backends fail with value=nil. The caller supplies acceptance UUIDs; freshness across applications belongs to the later controller.

PID hints are nullable positive canonical decimal strings up to18446744073709551615, compared without integer/Float conversion. They never influence geometry derivation or authorize native ownership. A valid checksum establishes consistency, not authenticity: a fully consistent user-authored replacement can be encoded; source authorization/CAS/ownership remain later layers.

## Reuse and bounded work

Checkpoint decoding now exposes a trusted internal `rebuild_owned_record(record:,numeric_policy:,budget:)`. It retains all existing schema/checksum/backend/rebuilt-verification checks; public checkpoint decode delegates after the original bounded parse. Host decode passes its owned parsed checkpoint and reuses the resulting physical source/snapshot through Task1. There is one physical geometry rebuild per public host encode/decode and one cumulative CoreBudget, with no nested public boundary or raised/reset limits. `encode_owned` and `decode_with_budget` support later trusted composition. Trusted methods are not standalone untrusted import entry points.

No speedup percentage is claimed. The optimization is structural reuse of the source resolution. Existing checkpoint golden hashes/roundtrips continue to test compatibility.

## Test coverage

| Contract case | Actual test behavior |
|---|---|
| H-D01 closed format | Roundtrip compares rebuilt plan and canonical JSON; nested output frozen; duplicate JSON keys/unknown/missing fields refused |
| H-D02 integrity | Unrepaired outer checksum fails; repaired stale plan/source/project fails; even a fully rebuilt changed checkpoint cannot retain the old manifest digest |
| H-D03 coverage | Missing/duplicate/reordered/foreign parts and missing/duplicate/reordered components fail; two real dimensional layers retain source indices0/1 |
| H-D04 PID hints | UInt64 maximum and9007199254740993 survive exactly; null accepted; zero, leading zeros, negative, fraction, overflow, numbers and booleans refused |
| H-D05 version/backend | Unknown document/manifest schema or profile rejected; backend conflict retains /checkpoint/verification pointer |
| H-D06 empty | Empty authoring roundtrip has no placeholder root; mismatched root/hints rejected |
| H-D07 ownership/resources | Caller manifest unchanged/mutable; key reorder canonical; low work/JSON byte limits return nil; default retry succeeds; trusted composition produces identical bytes |

Verification: `ruby test/host/document_codec_test.rb` passes12 tests/199 assertions. `ruby test/all_test.rb` on real Ruby2.7.8/x64-mingw32 and Ruby3.2.9/x64-mingw-ucrt each passes154 tests/2108 assertions,0 failures,0 errors,0 skips. The missing entry-point assertion was observed failing before implementation.

Independent whole-branch review reported no blocking, important or minor findings and independently reran the focused Ruby2.7.8 suite12/199. It confirmed that checkpoint extraction preserves existing checks, manifest order/coverage is exact and cumulative budgets are retained. The review did not qualify later native/lease/controller behavior.

## Remaining qualification

Tasks3–6 remain: shared model authority and leases; transaction/CAS/rollback controller; native adapter; actual SketchUp undo/redo/abort/save/reopen/restart and geometry tolerance tests. None is qualified by this pure codec. The broader module-creation roadmap still includes backs/grooves, fronts/drawers, supported banding, reusable module library and drawing outputs with their own evidence gates. Full imos equivalence is not demonstrated by this milestone. No loader/RBZ or proprietary source assets are added.
