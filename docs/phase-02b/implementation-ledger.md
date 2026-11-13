# SDD ledger — plan: docs/phase-01/19-project-core-implementation-plan.md

Design and execution plan approved; user instructed “vazhdo”.
Base: bf411e8242bf3d971f0753f0816e86a702a3bba0. Branch: feat/phase-2b-project-core.
Native inline implementation; one fresh-context whole-branch reviewer at completion.
Ruling: use the explicitly designated checkout on a feature branch; stage files under work/core in the chat's writable workspace before authorized copy/commits. POSIX skill bookkeeping scripts are replaced by this persisted ledger on Windows; no original work is deleted.
Preflight: Codec.parse -> Document.validate -> Parameters/References -> deep-freeze -> Codec.encode. One CoreBudget instance is shared through the request. Quantity adapter consumes existing Phase2A DTO validation; no new arithmetic. Zone allocation and prepared revisions remain deferred.
Tasks: 1 duplicate-aware parser; 2 closed immutable records; 3 parameter bindings; 4 pinned definitions/tree topology; 5 cross-version qualification and review.
Task 1: complete — missing entry file failed first; then 2 tests/40 assertions passed on Ruby2.7.8 and3.2.9. Stdlib JSON object_class retains decoded duplicate pairs, max_nesting64 rejects65. No partial public decoder exposed.
Task 2: complete — public API absence observed as failure; then document tests4/82 assertions passed on both runtimes. Closed records, exact string-key DTO adapter, cycle-safe copy, shared-value support, canonical key order and deep immutable output without freezing caller data.
Task 3: complete — invalid required/default/reserved bindings initially returned success; then 3 parameter tests/100 assertions passed on both runtimes. Explicit false/zero retained; defaults never inject authored overrides; W/H/D exact positive Lengths. Ruling: as approved in plan, approximate optional inputs are conservatively rejected before zone usage analysis exists.
Task 4: complete — structural violations initially succeeded; 4 topology tests/72 assertions then passed on both runtimes. Version pins, ID namespaces, slot roles and iterative cycles/depth/parent/reachability checks. Occurrence quota counts only each pinned instance, no occurrence arrays allocated. Structural codec deliberately does not evaluate expressions or physical containment.
