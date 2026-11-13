# Prepared Project Revisions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans task-by-task with TDD and one final fresh-context review. User instructed “vazhdo punen pa nderprer”; continue the approved design without further intermediate review/permission questions for reversible work.

**Goal:** Prepare one immutable next project revision and matching resolved ZoneSnapshot atomically, with stale/no-op/version-conflict rejection.

**Architecture:** Reuse ProjectCore validation and exact zone resolution under one CoreBudget. Compare validated authored data without Float conversion, enforce pinned-definition immutability within the current/replacement pair, create revision+1 only in an owned candidate, and resolve before returning a complete PreparedProjectRevision.

**Tech Stack:** Ruby2.7-compatible pure core/stdlib, existing Parametric/ProjectCore/Zones, real Ruby2.7.8 and3.2.9, Minitest development tests.

**Spec:** approved docs/phase-01/18-project-zones-spec.md section8, PC08/Q02; earlier units explicitly deferred this operation until real zone snapshots existed. Base integrated resolver ea15eb59d4f04e3454b60a4ff118eeca0f109fd5.

## Global constraints

- Public API: JPImosPro::ProjectCore.prepare_revision(current:,replacement:,expected_revision:,numeric_policy:,limits:{}).
- Both inputs are authored jpimos.project-core/1 Hash records, validated/copied without mutating/freezing caller objects. Full project migration/host persistence remain excluded.
- expected_revision is an exact Ruby Integer0..9007199254740991, equals current.revision; replacement must retain current project_id and revision. Stale/overflow fail before zone resolution.
- Success returns a frozen string-key record {project_id,base_revision,next_revision,document,zone_snapshot}; document.revision and snapshot.source_revision equal current+1 exactly.
- Compare normalized authored data: Hash property order insignificant; authored arrays, labels, locale, values, origins and definition pins remain semantic. No-op returns E_NO_CHANGE.
- A definition present in both inputs at the same(id,version) cannot change content; require a new version. This is local pair checking, not a global cross-project definition registry.
- One existing CoreBudget covers both document validations, comparison, metadata and candidate resolution. Existing byte/work/depth/number/occurrence caps cannot be enlarged. No fresh budget per stage or intermediate public resolve call.
- Prepared is not Accepted: no file/network/SketchUp transaction, persistence, UI, geometry/RBZ, materials/BOM/drawing or manufacturing functions.
- Existing48 tests/891 assertions and all historical14 reports remain preserved. Qualify on real Ruby2.7/3.2 with red/green evidence.

## Rulings and review focus

1. Current document is structurally validated, not re-resolved. This API can prepare a repair of unresolved authored source; it does not certify that current is a host-accepted snapshot. Replacement must fully resolve.
2. Validate current/expected and overflow, then replacement identity/revision/definition pins/no-op, then policy and candidate geometry. No-op/stale checks therefore do not require evaluating expressions.
3. Prefix current/replacement validation and candidate-expression pointers with /current or /replacement. Preserve wrapped engine spans/occurrence refs; numeric-policy pointer remains /numeric_policy.
4. Reuse the exact resolver policy validation (including encoding/byte guards) through one helper, without weakening resolve_zones behavior.
5. No acceptance/session lock or automatic revision publishing is invented. Two preparations against the same authored revision may both succeed; a future acceptance layer must enforce compare-and-swap.

Review tests must exercise stale revision with a division-by-zero replacement, invalid expected_revision types including Boolean/Float, no-op with reordered Hash keys, metadata-only edits, same-version definition edits, reused/frozen inputs, post-comparison resource exhaustion and independent recovery.

## Files / interfaces

Create lib/jp_imos_pro/project_core/revision.rb; test/project_core/revision_test.rb; docs/phase-02b/revisions.md and revisions-validation.md. Modify project_core.rb to expose the operation and extract validated_policy helper; update current README/API links. Test runner already discovers project_core tests.

Internal Revision.current(document,expected,budget)->validated current, checking expected type/equality and exhaustion; Revision.replacement(current,document,budget)->validated replacement with matching IDs/revision, immutable overlapping definition versions and meaningful change; Revision.candidate_snapshot(candidate,policy,budget)->resolved snapshot with prefixed errors. Revision.equal?(left,right,budget)->Boolean is iterative, counts inspected nodes/queued pairs, compares only owned plain JSON values and ignores Hash key order. No codec JSON serialization is used as a semantic comparison shortcut.

## Task1: Revision conflict and no-op boundary

- [ ] Write PC08/Q02 failing tests: absent operation, current7/expected6 ->E_REVISION_CONFLICT even when replacement source is1/0; expected7.0/true/nil ->E_INPUT_CONTRACT; max safe revision ->E_REVISION_EXHAUSTED; replacement ID/revision mismatch ->E_REVISION_CONFLICT; exact/reordered no-op ->E_NO_CHANGE. Verify originals unchanged.
- [ ] Observe failure with `ruby test/project_core/revision_test.rb`.
- [ ] Implement current/replacement validation and iterative semantic comparison in revision.rb; use scoped errors and one budget. Public prepare_revision may be added with complete success behavior in Task2; no placeholder successful prepared value.
- [ ] Internal focused tests can exercise Revision helpers before public operation exists. Confirm normal resize is identified as meaningful; commit `feat: validate prepared revision conflicts and semantic changes` after focused green.

## Task2: Complete candidate and matching snapshot

- [ ] Write failing public tests: W600->800 at revision7 gives base7/next8/document8/snapshot8, expected child400; locale sq->en alone produces revision8; origin edit preserved; no caller mutation, deeply frozen output; invalid replacement math returns no partial document/snapshot.
- [ ] Implement prepare_revision using boundary/one CoreBudget. Reuse validated_policy; create a new root Hash with revision+1 over already owned frozen child records, freeze candidate, resolve with Zones::Resolver directly, then freeze complete prepared outer record.
- [ ] Validate shared definition pins before candidate resolution; same version changed label/source/parameters/layout must fail E_DEFINITION_DUPLICATE, new version with updated article reference succeeds. Removing/referencing missing definitions fails existing structural diagnostics.
- [ ] Preserve core errors and prefix candidate expression pointer /replacement while keeping span/grammar/symbol/occurrence data. Errors do not mutate current/replacement, increment a global counter or publish any accepted state.
- [ ] Run both runtimes/full suite, commit `feat: prepare immutable revisions with matching zone snapshots`.

## Task3: Atomic resource qualification and review

- [ ] Add bounded comparator tests, shared-work exhaustion after validation, total input metadata/text quota, source error atomicity, fresh-request recovery, frozen inputs and reusable definitions. Repeated calls against unchanged current remain deterministic and return same next revision, not an invented global sequence.
- [ ] Run combined suite on real Ruby2.7.8 and3.2.9; capture actual counts, syntax and whitespace checks. Fresh-context whole-branch reviewer checks identity/revision guards, no-op semantics, version immutability, counter reuse, wrapping and no partial output. Fix material findings with red/green regressions.
- [ ] Document all scope/ordering decisions, local pair-version limitations and future acceptance requirement. Historical14 unchanged, no proprietary sources or generated runtime assets committed.
- [ ] Commit `test: qualify atomic prepared project revisions`; push/create PR and, under the user's uninterrupted-integration instruction, merge after verification and retest main. No further module scope is inferred from that integration.

## Self-review

The approved spec already defines this operation; no new construction behavior is designed. PC08/Q02 close the remaining revision contract. Unit1 codec and unit2 resolver remain separate APIs; helper extraction only shares policy checking. All numerical output is resolved before success, and all state remains pure prepared data. Host acceptance/undo and physical construction stay future work.
