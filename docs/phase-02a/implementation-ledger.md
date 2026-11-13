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
