# Zone resolver qualification

Date: 13 November 2026 (Europe/Berlin). Implementation branch: feat/exact-zone-resolver. Base integrated project-core:10057315f39cfc77cc8d8af741030d3cda4f7d6e. Approved execution plan:report20. Scope: exact rectangular zone resolution only.

## Executed fixtures

| Design fixture | Covered behavior |
|---|---|
| Z01/Z02 | Equal partitions, explicit18mm reservation and291/18/291 lengths; no implicit deductions |
| Z03/Z05 | Nested height240/480, oriented parent frame composition |
| Z04/Z06 | Plan/front/left-side bases, front-under-front, left-side depth partition |
| Z07/Z08 | Coextensive independent layers, child orientation, exact fractional bounds, negative/zero/oversize rejection |
| Z09 | No zero or external-reference intervals promoted to physical zones |
| Z10/Z12 | Expanded slot count mismatch rejected; stable refs on resize600->800 |
| Z11 | Existing structural missing/cycle/shared-parent/orphan tests retained and rerun |
| Z13 | Explicit article translation separated from article-local zone coordinates |
| Z14 | Unknown physical/front fields rejected by unchanged closed project schema; no physical envelope claim |
| Z15 | Caller-authored1500 span with two18mm reservations yields three488mm zones; source conflict remains unresolved |
| Q01 | Whole-request/shared engine budget, local parser/depth/expansion caps, backend bytes and rational4096-bit overflow |

Additional cases: child-link order differs from physical slot order, definition reuse by independent instances, frozen output without freezing caller policy/input, empty projects/layers, endpoint Scalar/inexact failure, unknown symbols in lazy branches, lexical diagnostics across placements2/10 and tied occurrence IDs, deterministic repeated exhaustion and fresh-request recovery.

The existing Phase2A and project-core suites are included exactly once by the combined runner. PC08/Q02 prepared revisions are NOT IMPLEMENTED. No host/UI/geometry qualification is claimed by arithmetic tests.

## Red/green and review evidence

Task1 began with missing WorkCounter; Task2 with missing Frame module; Task3 with absent resolve_zones; Task4 with unsupported layer diagnostics. Focused tests were observed failing before each implementation and passing afterward. Existing Ruby2.7 tests caught a keyword/positional-Hash compatibility regression in guard; the trusted internal argument was made positional without changing public operation signatures.

One fresh-context reviewer identified an uncaught malformed backend encoding before policy validation. Regression tests reproduced it; encoding/type checks now precede the engine's string operations. UTF-16 and invalid UTF-8 return E_INPUT_CONTRACT. Backend metadata is also charged before copying, with an observed red/green quota test. False/nil trusted-counter bypass cases were rejected under regression tests. The review reported no additional concrete frame/scope/atomicity/caller-immutability/shared-budget findings.

Final full-suite results are recorded after testing the exact repository files, not just scratch staging. Verification includes real Ruby2.7.8p225 x64-mingw32 and3.2.9 x64-mingw-ucrt, syntax checks, git whitespace checks, preserved historical14 and asset exclusions.

## Evidence boundaries

Source concepts/locators are inherited from report18 and the inspected Phase1 audit; PDFs were not re-extracted during this implementation. Exact transform conventions, snapshot schema, reservation-slot rules and resource policy are original approved JP choices. Abstract overlapping zones do not establish physical construction fit, usable storage volume or collision clearance.

Distribution licensing remains undecided; no third-party evaluator or proprietary implementation was reused. Prepared revisions and downstream modules need separate implementation/integration work.
## Final repository-file results

Full command ruby test/all_test.rb passed on both real runtimes:48 tests,891 assertions,zero failures/errors/skips each. Ruby2.7.8p225 x64-mingw32; Ruby3.2.9 x64-mingw-ucrt. All production Ruby files passed syntax checks; git diff --check passed. The historical14 reports and previous fixture files are unchanged. The added report20 is the approved execution plan, not a rewritten source audit.
