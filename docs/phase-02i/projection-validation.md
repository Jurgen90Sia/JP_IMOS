# Pure host projection validation

Date:17 November2026. Scope: Task1 of the [atomic host plan](atomic-host-implementation-plan.md). This is original JP analysis and synthetic test data. No SketchUp model was changed for this validation.

Implemented `Host::Projection.build(state:, numeric_policy:, limits:{})`, returning an immutable `PreparedProjection`. Public input is authoring only. One physical rebuild supplies owned source/snapshot, a canonical source checkpoint, and a world projection plan. Trusted composition guards source project/revision/hash and numeric policy/backend headers; it is not a hostile snapshot validator or a wire import API. `plan_sha256` hashes all canonical plan fields and is outside the plan body.

The source article origin is added exactly once to already framed article vertices. Every part emits one substrate solid followed by dimensional surfaces in source-index order. Finished-envelope proxies are omitted. Every solid retains exact world Length/mm coordinates, six oriented face loops and exact expected volume. No native entity IDs are present.

| Coverage | Reproducible assertion |
|---|---|
| H-P01 translation | Origin[100,200,300], W600/H720/D560/t18: left bounds[100,200,300]..[118,760,1020] |
| H-P02 top frame/resize | Top bounds[118,200,1002]..[682,760,1020]; W800 changes maxX to882 |
| H-P03 layers | Left far layer1/10mm and near layer1/5mm retain source indices0/1; substrate x[1/5,91/5], far[91/5,183/10], near[0,1/5] |
| H-P04 empty | No article/request/policy produces parts[], without placeholder geometry |
| H-P05 ownership | Nested returned data frozen, caller remains mutable; key reorder preserves digest |
| H-P06 source/checkpoint | Derived/unknown wire fields refused; mixed trusted revision/backend refused; checkpoint roundtrip rebuilds identical snapshot |
| H-P07 limits | Layer0.1mm accepted/0.099mm refused; max coordinate1,000,000mm accepted/1,000,000.001mm refused; negative bound also checked; low work returns E_RESOURCE_LIMIT/value=nil |
| Host result | Success/refusal both declare metadata.mutation_state=unchanged |

Profile limits are JP design choices, not imos or SDK construction rules. The exact coordinate bound precedes Float conversion and guarantees finite supported values. This is no evidence for native0.1mm tolerance; that remains Task6.

Test command: `ruby test/all_test.rb` on real Ruby2.7.8/x64-mingw32 and Ruby3.2.9/x64-mingw-ucrt. Both: **142 tests,1909 assertions,0 failures,0 errors,0 skips**. Focused suite: `ruby test/host/projection_test.rb`. RED was observed for the missing entry point, the plan profile field and mutation-state metadata before corresponding implementation/fixes.

Checkpoint regression hashes were captured independently by loading the original implementation from baseline3036d44b3527d295482b1183ad9ae49d679c31f6 with unchanged synthetic source and each backend policy. Tests compare current checkpoint bytes to these SHA256 values:

| Backend | SHA256 of canonical checkpoint bytes |
|---|---|
| 2.7.8-x64-mingw32-Math | 50d7cf52a203d66dcea5a1534869d4d63ab0ebb53ef409e6d4fea4bf036e64e1 |
| 3.2.9-x64-mingw-ucrt-Math | 15390ad562fde77adbf32c8de6e2331d7b23abc7d3686a968e307ebdced0cd32 |

These are backend-specific fixtures; other backends still run the source roundtrip. Public checkpoint schema, profile, canonical ordering and bytes remain unchanged for these fixtures. Work accounting includes bounded trusted-header checks; caller limits are never increased/reset.

Independent code review found one contract mismatch: missing mutation_state metadata. A failing regression test preceded the fix; success and refusal now both declare unchanged. The reviewer reran the complete Ruby3.2 suite and reported no remaining important issues; stale documentation status was updated before integration.

Remaining: Task2 host-document codec, shared authority/leases, transaction controller, native port and actual undo/abort/reopen qualification. Production host readiness remains BLOCKED. No extension registration, RBZ, manufacturer authority or automatic model mutation was introduced.
