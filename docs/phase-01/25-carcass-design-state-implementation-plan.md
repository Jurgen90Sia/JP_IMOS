# Carcass Design State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans; inline TDD and one fresh-context final review. User delegated autonomous uninterrupted work, so no intermediate approval pause.

**Goal:** Bind construction authoring to one prepared project revision and complete exact snapshot.
**Architecture:** Closed state owns unchanged project-core + existing requests. Trusted owned validators and revision guards are shared; full zone resolution/project digest occur once, followed by pure internal preview compilation under one counter.
**Tech Stack:** Ruby2.7/3.2, existing pure modules and stdlib JSON/Digest, Minitest.
**Spec:** docs/phase-01/24-carcass-design-state-spec.md.

## Constraints/review focus

No new host/publication behavior, schema ambiguity, duplicated live authority or opaque imported preview acceptance. Protect material-catalog limitations. Reuse one budget and caller-owned data guards. Watch request-only edits being falsely treated as no-op; stale snapshot/project digests; public recursive calls resetting counters; ownership/freezing; coverage and prefix errors.

## Files/interfaces

Create design.rb, design/record.rb, design/snapshot.rb and test/design/{fixtures,state_test,revision_test}.rb; docs/phase-02d API/qualification. Refactor only common trusted paths in ProjectCore::Document, ProjectCore::Revision, Construction::Request and Construction builder; public compatibility remains covered by baseline.

- Record.validate(raw,budget,prefix='')->owned immutable state. Full bounded copy first; then trusted project/request shape normalization with scoped errors and exact article coverage.
- Core Document.validate_owned(owned,budget) and Request.validate_owned(owned,budget)->existing closed records, reachable internally after plain-data copying. Existing public validate methods still copy before this path.
- Revision.check_current(validated,expected) and check_replacement(current,validated,budget)->guards without no-op; old current/replacement methods continue validation and old no-op behavior.
- Construction.preview_from_validated(document:,request:,zone_snapshot:,project_sha:,policy:,budget:)->existing preview shape, no public budget/validation reset. Builder is trusted, never called on imported caller snapshots.
- Design::Snapshot.build(state,policy,budget)->frozen profile snapshot; zones/project digest once, then requests in order. Design.prepare_revision orchestrates one budget and returns only complete prepared value.

## Task1: Owned-state contract/codec
- [ ] Write DS01/DS02 failing tests. Implement explicit closed envelope, coverage, prefix diagnostics, canonical codec and copies. Extract trusted owned normalization only, preserve old APIs. No snapshot stub.
- [ ] Run focused+all baseline on both runtimes; commit feat: validate revision-bound carcass design states.

## Task2: Shared snapshot and prepared state
- [ ] Write failing DS03–DS05 public tests for request-only changes, one increment and matching revision/hashes,8 distinct panels, no-op/stale/max and atomic failures.
- [ ] Extract existing revision guard/body paths; keep public Core.prepare_revision behavior. Refactor Construction builder into a common trusted preview path so design snapshot reuses zones/project digest and one budget. No duplicated geometry logic.
- [ ] Implement complete Design.prepare_revision with scoped request/project errors and deterministic output. Candidate root/state frozen over owned children; no host acceptance.
- [ ] Run both runtimes/full suite; commit feat: prepare complete revision-bound carcass snapshots.

## Task3: Qualification and integration
- [ ] Add DS06, failing second request, JSON duplicate source, immutable/frozen/reused input, changed request order, shared quota/recovery and malicious policy/data cases. Existing74 tests unchanged and green.
- [ ] One fresh-context review, fix material findings with observed regression red/green. Document explicit profile and accepted-state boundary, future host transaction contract and runtime limits.
- [ ] Full Ruby2.7/3.2 tests, syntax/whitespace/history/assets checks; commit qualification, push/create PR, verify/merge and retest main under uninterrupted authorization. No RBZ or untested host claim.

## Self-review

State owns the component and construction intents; a complete state digest and one project revision govern all outputs. Old preview API remains a pure standalone tool. No new construction rules are invented. Input guards and one counter survive trusted helper extraction, while transaction side effects remain future work.
