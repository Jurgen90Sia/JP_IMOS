# Canonical physical checkpoint — contract and plan

Original JP contract,13 November2026, under standing autonomous authorization. Scope is a pure authoring persistence codec; no host dictionary, file writer, accepted-state pointer or transaction is implemented.

## Format and API

`Design::PhysicalCheckpoint.encode(state:,numeric_policy:,limits:{})` validates the owning physical state, rebuilds its supported physical snapshot and returns canonical UTF-8 JSON. The closed record has schema=`jpimos.physical-checkpoint/1`, state (only `jpimos.physical-design/1` authoring), verification and content_sha256. No derived geometry or host entity IDs are stored.

Verification has exactly project_id(UUID), revision(safe nonnegative integer), state_sha256, catalog_sha256, snapshot_sha256 (lowercase64-hex SHA256), policy_id and backend_id. These are recomputed from fresh source resolution. content_sha256 covers canonical JSON of schema/state/verification, excluding itself. Canonical keys use the existing bounded plain-data copying/JSON convention; no timestamp is semantic.

`decode(source:,numeric_policy:,limits:{})` rejects duplicate JSON keys, unknown schemas/fields, malformed verification, checksum mismatch or an incompatible explicit numeric policy/backend. It then validates authoring, rebuilds the physical snapshot and compares every verification field. A repaired outer checksum cannot bypass stale state/catalog/snapshot verification. Output is immutable {state,snapshot,verification,content_sha256}; no caller snapshot is imported as authority. Checksum is consistency evidence, not a signature or proof of provenance; a newly valid authored record can produce a new valid checkpoint.

New diagnostics: E_CHECKPOINT_INTEGRITY for outer checksum mismatch; E_CHECKPOINT_MISMATCH with `/verification/<field>` for a rebuilt binding mismatch; E_NUMERIC_POLICY_CONFLICT for changed valid policy/backend. Incompatible backend IDs are refused even for currently exact geometry; migration/rebinding requires a separate explicit policy, not an automatic reopen fallback. Existing source, parse and resource diagnostics are retained. One CoreBudget covers parse/copy/normalization, reference checks, geometry, hashing, verification and output encoding. All failures return value=nil; no files or host data change.

The checkpoint is a candidate canonical source payload for a later namespaced model-dictionary contract. It does not mark a revision accepted or implement compare-and-swap, host mapping, undo recovery or SKP save/reopen. Those remain required before the host adapter. Existing PhysicalState authoring encode/decode is unchanged.

## Approach and implementation plan

Chosen: store source plus attestation and rebuild on read. Storing full derived solids would add a competing authority and a larger untrusted cache. Persisting an accepted marker now would invent a transaction boundary that does not yet exist.

Task1 files: create `lib/jp_imos_pro/design/physical_checkpoint.rb`, `test/design/physical_checkpoint_test.rb`; share the existing physical test fixture in `test/design/fixtures.rb`; update README/readiness.

- [x] RED: round-trip rebuild, canonical ordering, checksum rejection, repaired-checksum false bindings, changed backend, closed schema/duplicate keys, caller ownership and resource failures.
- [x] Implement bounded source-only encoding/rebuilding decode using owned helpers, no nested public boundary or file operation.
- [x] GREEN: full suites on Ruby2.7.8/3.2.9, independent review and published PR #12 under standing integration authorization.

Review focus: treating checksum as source authority; accepting a stale snapshot hash after repaired checksum; silently rebinding another numeric backend; freezing caller strings/state; resetting work during rebuild. Each has a focused test. Subsequent [native draft storage/reopen qualification](native-checkpoint-validation.md) passed in a probe-only dictionary; production persistence/transactions remain unresolved and NOT RUN.

## Qualification ledger

Base main `e90138a0404f604b881b80de3952b0c349f4d9b8`, clean;124 baseline tests /1,752 assertions. Isolated branch `feat/physical-checkpoint-codec` reuses the clean linked checkout. The shared physical-state test fixture moved into the existing fixtures utility; no production-only test hook was introduced.

Task1 RED:8 missing-entry-point errors before implementation. Focused GREEN:8 tests /87 assertions. Full real Ruby2.7.8 and3.2.9 suites each passed132 tests /1,839 assertions with no failures/errors/skips, preserving all124 baseline tests. Repairing the outer checksum after changing any individual verification binding still fails against freshly rebuilt data. Same-policy encode/decode/re-encode is byte-stable; a different valid backend is rejected. Aggregate decode under work48,000 fails atomically while default-budget retry succeeds.

No scope or schema ruling was required. This is a source persistence codec only. The existing local-builder native proof remains separately scoped and does not qualify this codec or native host persistence. No source manuals, binary assets, runtime dependency, file writer, model dictionary or loader is added.

Final review: independent read-only review of `e90138a..1ecc216` approved the documented pure codec scope with no actionable findings. Reviewer independently reran the full Ruby2.7.8 and3.2.9 suites:132 tests /1,839 assertions each, all passing. No fixes or deferred minors were requested.

Final Ruling: native host persistence/model dictionaries, transaction/CAS acceptance, undo/reopen recovery, backend migration, manufacturer authority and cryptographic authenticity were not judged by this review. The codec claims consistent source reconstruction only; these remain separate dependencies rather than implied guarantees. Checksums are not signatures or proof of acceptance.
