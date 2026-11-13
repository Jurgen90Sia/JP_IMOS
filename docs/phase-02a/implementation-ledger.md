# SDD ledger — plan: docs/phase-01/16-expression-division-spec.md

Authorized by user: “ok vazhdo”, Phase 2A only.
Base: 5371e7e4e826dedfcb366c9179367cf6c522c995.
Branch: feat/phase-2a-parametric-engine; main and the 14 historical reports preserved.

Ruling: use the explicitly designated JPMOS checkout on a feature branch — user specified this workspace; no separate worktree was requested — main remains unchanged but this checkout changes branch.
Ruling: stage source in this chat's writable work/phase2 before copying reviewed slices into JPMOS — repository writes require sandbox escalation — test the exact copied files before commits.
Ruling: ASCII '-' is the operator in E14 — grammar defines ASCII operators, table uses typographic minus — pasted Unicode minus receives a lexical error.
Pre-flight: shared quantities and budgets feed expression evaluation and division allocation; division adds affine typing without weakening core unit rules. Definition graph validates all syntactic branches before lazy arithmetic evaluation. Exactness must survive both layers.

Tasks: 1 quantities/lexing; 2 parser/functions; 3 definitions; 4 affine allocation; 5 repeat/quantum; 6 cross-version qualification and review.
No SketchUp adapter, UI, RBZ or other plugin code is authorized.
Task 1: complete — observed missing implementation, then 2 tests/29 assertions green on Ruby 2.7.8. Task 2: complete — observed E_UNKNOWN_FUNCTION for sin, then 3 tests/65 assertions green; lazy branch type validation and explicit Math allowlist.
Task 3: complete — missing evaluate_definitions failed first; 4 tests/88 assertions green. Iterative lexical topological sort, complete syntactic dependencies, atomic publication, cycle path diagnostics.
Task 4: complete — missing parse_division failed first; 6 tests/156 assertions green. Exact affine lifting, explicit reference context, stable boundary IDs, frame mapping, negative coefficient versus negative solved interval distinction.
Task 5: complete — repeat fixture initially returned E_UNSUPPORTED_GRAMMAR; 7 tests/191 assertions green on real Ruby 2.7.8 and Ruby 3.2.9. Bounded expansion and exact positive single-quantum restriction, no rounding or historical auto-repeat.
Task 6: complete — review regressions observed failing, then fixed; final 14 tests/383 assertions green on Ruby 2.7.8 and 3.2.9. All E01–E20/N01–N24 families covered. Limits checked on source/tokens/AST/depth/literal digits/rational bits/steps/expansion/definitions. 1000 definitions and 1000 intervals accepted within budget.
Ruling: UTF-8/US-ASCII sources only; other encodings return E_INPUT_CONTRACT — prevent incompatible-encoding native errors while retaining Unicode code-point spans — adapters must transcode before calling.
Ruling: runtime dependencies and declared dependencies are separate Result fields — lazy arithmetic must report actual reads while all names still require declarations — callers must select the appropriate field.
Ruling: exactness propagates through conditional conditions — approximate comparisons cannot launder an exact allocation coefficient — a condition based on approximate math prevents exact division even if its selected literal is integral.
Review: one fresh-context reviewer identified six issues; all addressed in the final fix pass with red/green regressions. Dependency traversal uses indegrees/reverse edges rather than repeated full-graph rescans. No remaining critical/high findings from that review are deferred.
Implementation only; no merge or push yet. Original Phase 1 reports and source-conflict register remain unchanged.
