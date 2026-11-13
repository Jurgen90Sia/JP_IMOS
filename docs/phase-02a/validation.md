# Phase 2A qualification

Scope: Parametric Expression and Linear Division Engine only. Base documentation commit: `5371e7e4e826dedfcb366c9179367cf6c522c995`. Implementation branch: `feat/phase-2a-parametric-engine`.

## Evidence fixtures

The tests use independently specified rational results from Phase 1C report 16. No source PDF or figure is included.

| Specification fixtures | Executed behavior | Source reference / classification |
|---|---|---|
| E01–E04 | equal weights, endpoint markers, fixed end offsets | Manual Ndarja Lineare.pdf pp.5–6; source examples plus inferred exact allocation |
| E05–E06 | 817/3 and 817/4 ratios, exact internal coordinates | Manual Ndarja Lineare.pdf pp.5–6; inferred arithmetic |
| E07 | eight 100mm intervals and bounded 1000-term expansion | Manual Ndarja Lineare.pdf p.6; inferred coordinates, proposed resource policy |
| E08 | -200/1200 internal positions | Manual Ndarja Lineare.pdf pp.7–8; documented external-position family |
| E09–E11 | affine offsets, X and bound variables | Manual Ndarja Lineare.pdf pp.8–9; documented syntax plus inferred arithmetic |
| E12 | exact 32mm quantum, count 8; reject infeasible 601mm span | Manual Ndarja Lineare.pdf p.7; restricted JP policy |
| E13–E15 | reversed reference mapping, typed W-2*T, decimal 3/10 | Proposed JP behavior |
| E16 | sin(pi/2), approximate flag and 1e-12 tolerance | Manual Ndarja Lineare.pdf p.8 radians; proposed numeric policy |
| E17–E20 | lazy typed branches, negative affine offset, scalar-before-lifting | Proposed JP behavior |
| N01–N08 | negative/zero spans, weights/intervals, fixed closure, grid infeasibility | Specified boundaries, no clamping |
| N09–N12 | deferred repeat/descriptor/power/function/legacy-unit grammar | Explicit unsupported families |
| N13–N17 | unit/domain/declaration/cycle and forbidden-source failures | Typed diagnostics, atomic definition results |
| N18–N24 | source/token/node/depth/digit/bit/step/expansion/definition limits, presence, nonlinear gaps, malformed numbers, exactness | Proposed bounded input policy |

Additional regressions cover mixed-key objects, UTF-16 input rejection, required numeric policy, frozen/fabricated ASTs, actual versus declared dependencies, 1000 independent definitions, cycle paths and Unicode diagnostic offsets.

## Review disposition

A fresh-context reviewer identified malformed-hash native exceptions, incompatible source encodings, nil/false numeric-policy bypass, reserved function rebinding, omitted expression dependency output, and repeated dependency rescans. Regression tests were observed failing before fixes. Fixes validate key membership without sorting mixed keys, reject unsupported encodings, require evaluator policy, reserve built-ins, expose runtime/static dependencies separately, and use indegrees plus reverse adjacency for graph traversal. Test results recorded below apply to the final repository files, not merely staging copies.

## Remaining boundaries

The engine has not been integrated with SketchUp; no UI, geometry, RBZ or host compatibility claim is made. Backend IDs are caller-qualified; transcendental output is tolerance-qualified across Ruby/Math builds. Exact division fixtures remain rational. Repository distribution licensing remains undecided; no candidate third-party implementation was reused.

Merge and publication of the implementation branch require the user's integration choice. Main retains the Phase 1 research baseline until then.

## Final runtime qualification

On 13 November 2026, the full suite passed on both real Windows executables:

| Runtime | Results |
|---|---|
| Ruby 2.7.8p225, x64-mingw32 | 14 tests, 383 assertions, zero failures/errors/skips |
| Ruby 3.2.9, x64-mingw-ucrt | 14 tests, 383 assertions, zero failures/errors/skips |

Ruby 3.2 was extracted only into task scratch space from the [official RubyInstaller release](https://github.com/oneclick/rubyinstaller2/releases/tag/RubyInstaller-3.2.9-1). Downloaded rubyinstaller-3.2.9-1-x64.7z SHA256: `d732a4d02236b623a18dedcfacc00dc0e09cf3a10b172d58255887693791d300`. This records the downloaded bytes, not a separately verified release signature. Neither runtime is vendored or added to production dependencies.

Phase 2A pure-core status: PASS for the specified subset. Full imos compatibility, resolved construction rules, SketchUp host integration and downstream modules remain outside this acceptance.
