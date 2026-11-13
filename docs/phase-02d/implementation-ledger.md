# SDD ledger — plan: docs/phase-01/25-carcass-design-state-implementation-plan.md
User continues autonomous work without approval questions. Basee99a97e7c64452c3fa5ad1809cb8e475fed2e6b5, branch feat/carcass-design-state; work/design staging.
Ruling: explicit profile-specific owning envelope instead of adding unknown fields to core schema or accepting a second live request store. All request changes must increment the project revision.
Preflight: bounded state copy -> trusted owned project/request validation -> shared revision guards/state comparison -> one zone snapshot/project hash -> reused preview builder -> immutable prepared state. No nested public calls/reset budgets.
Tasks1 state codec;2 complete snapshot/preparation;3 qualification/review/integration.
Task1 complete: missing design entry observed failing;77 tests/1298 assertions green on Ruby2.7/3.2. Closed owning state, canonical duplicate-aware codec, exact coverage and trusted-owned helper extraction preserve all74 baseline tests.
Task2 complete: absent Design.prepare_revision failed first;81 tests/1345 assertions green on both runtimes. Request-only edits increment shared project revision; zone snapshot/previews match. Core revision guards and construction common path extracted, public74-test baseline preserved; zones/project digest built once per design snapshot.
