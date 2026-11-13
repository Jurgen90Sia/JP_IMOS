# SDD ledger — plan: docs/phase-01/20-zone-resolver-implementation-plan.md
User approved execution with “vazhdo punen”. Base fecbd1032fc6501eae6b4b1b0d78eb80982bf0cc; feature branch feat/exact-zone-resolver.
Native inline TDD and one final fresh-context review; existing checkout preference retained. Scratch staging work/zones, same established Windows copy/commit workflow, no unrelated work removed.
Preflight: WorkCounter -> CoreBudget/engine Budget -> Frame + EngineBridge -> Resolver -> complete frozen snapshot. Parameters and definition pins are already validated. One request counter must survive every stage.
Tasks: 1 shared budgets; 2 frames; 3 partition snapshots; 4 layers; 5 diagnostics/limits/cross-version review. Prepared revisions/host/geometry remain excluded.
Task1 complete: missing WorkCounter failed first; full34 tests/715 assertions green. Ruby2.7 keyword-hash regression caught by existing limits tests and corrected with positional trusted guard argument; public signatures unchanged.
