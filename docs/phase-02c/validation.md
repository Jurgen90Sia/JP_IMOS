# Rectangular carcass preview qualification

Date:13 November2026(Europe/Berlin). Base4f093921e715eb426c1198430854b82c0e77e892. Branch feat/rectangular-carcass-core. Scope: pure finished-envelope construction preview.

| Fixture | Executed behavior |
|---|---|
| CC01 | Four18mm panels,564/684 opening,8 vertices/6 outward faces each,25885440mm3, full containment and zero pairwise interior overlap |
| CC02 | L18/R20/T16/B22 ->562/682 opening, right xmin580/top zmin704/bottom zmax22,27280960mm3 |
| CC03 | Nominal19 distinct from18.5 substrate;0.5+0.5 layers yield19.5 stack; empty surfaces preserve18.5; unsupported/ambiguous overrides fail |
| CC04 | Zero/negative/inexact thickness, empty opening, invalid schema/principle/ID/material pin/unknown fields fail atomically |
| CC05 | Front view and project translation do not double-transform panels; reused article definitions have distinct role occurrences; bad sibling zone fails full request |
| CC06 | Canonical property-order-independent request/project digests, changed request/document context, nested immutability and caller ownership |
| CC07 | Fractional600.5/560.5/720.5 dimensions ->25928730mm3, outward winding/closed edges,4096-bit stack/volume overflow, request work exhaustion/recovery |

The generic B14 contour-hole fixture is NOT implemented/passed: this converter accepts rectangular recipes only and rejects holes/general contours. Envelope volume is not a board/BOM material quantity. Caller catalog refs are unverified. Current output does not establish accepted host state, storage depth or physical load performance.

## Red/green and review

Missing finished context, carcass rule, geometry/public construction entry each failed before their respective implementations. A later overflow diagnostic initially had an empty pointer; regression tests observed the failure, then characteristic scoping was fixed. An asymmetric test's expected bottom xmax was corrected to W-R=580 for R20; production geometry was already correct.

One fresh-context static reviewer examined stack arithmetic, bases, face winding, asymmetric placement, hashing, ownership, shared limits and atomicity; no actionable high/medium issues were found. The reviewer did not repeat the suite or review later Task4 qualification additions; those were executed independently on both runtimes.

Final full-suite target/result: **74 tests,1260 assertions,zero failures/errors/skips** on real Ruby2.7.8p225 x64-mingw32 and Ruby3.2.9 x64-mingw-ucrt. Includes unchanged58-test/1012-assertion baseline. Exact repository-file, syntax and whitespace verification precedes commit/integration.

## Traceability and limitations

Evidence concepts/locators are carried from Phase1 reports04/09/12 and design22: Manual Menaxhimi i Elementeve.pdf pp.11,15,18,21 and65–69. PDFs were not newly extracted in this task. Additive stack and selected coordinates are explicit JP policy; SC01/SC08/SC16 stay unresolved beyond those policies.

Historical14 reports preserved. No proprietary manuals/figures, credentials, runtime binaries, eval engine, external implementation or new runtime dependency is published. Preview review artifacts are generated from original synthetic fixtures and stored outside the repository.
