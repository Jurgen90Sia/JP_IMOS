# Material-bound design preparation

Date: 13 November 2026. Original JP design and implementation plan under the user's standing authorization to continue without intermediate approval.

## Design

The next pure boundary binds the existing design snapshot and the closed user-declared material registry in one owned, immutable result. Existing `Design.prepare_revision` remains unchanged. New `Design::MaterialPreparation.prepare(state:, catalog:, numeric_policy:, limits: {})` resolves the current authored revision without incrementing or accepting it. It takes authoring, never an imported derived report or snapshot.

The result uses the standard Result envelope. Successful value has exactly schema `jpimos.material-bound-design/1`, profile_version `jp-material-bound-design-v1`, state, catalog, snapshot, material_report and content_sha256. State is the validated `jpimos.carcass-design/1` record. Catalog is the complete normalized registry sorted by UUID/version, including unused declarations. Snapshot is rebuilt from state with the explicit numeric policy. Material report binds the same whole-state hash and catalog hash and includes all substrate/surface references. content_sha256 is SHA256 of canonical JSON of the other six fields, excluding itself. Catalog provenance remains `user_declared`; this does not establish manufacturer authority or host acceptance. Existing preview reference status is retained.

One CoreBudget covers input ownership, validation, reference resolution, zone/geometry construction, canonical encoding and freezing. Missing pins, category mismatches, malformed source records, unsupported schemas, invalid numeric policy or exhausted resources return value=nil. No input is mutated/frozen and no file, session pointer or host dictionary is written. Closed existing request schemas remain unchanged. Error precedence is state validation, catalog validation, material reference resolution, policy validation, derived construction. Existing Catalog.verify_references behavior and output remain compatible.

Chosen approach: reuse trusted owned-state helpers under one boundary. Calling the two public APIs separately would reset resource accounting and retain multiple caller-owned versions. General accepted PartSpecs would require additional substrate/finish/edge/grain contracts; that is a separate dependency, not inferred from this preparation bundle.

## Implementation plan

**Goal:** atomically prepare material-bound derived geometry for an authored revision.

**Architecture:** extract reference report construction from Catalog.verify_references without changing its public behavior; compose that helper with Design::Record and Snapshot under one budget. No new dependency; Ruby 2.7 minimum.

**Task 1 — material-bound preparation**

Files: modify `lib/jp_imos_pro/materials/catalog.rb`; create `lib/jp_imos_pro/design/material_preparation.rb` and `test/design/material_preparation_test.rb`; update current readiness/README and qualification documentation.

- [x] Write tests for actual four-panel geometry/material correspondence, missing and mismatched pins, dimensional surfaces, ownership/freezing, canonical hashes, revision-sensitive output, unsupported derived imports, empty projects and aggregate work limits.
- [x] Run the focused test and observe the absent entry point before implementation.
- [x] Extract the owned reference report helper and implement `prepare` with one budget and no nested public calls.
- [x] Run focused and complete tests on Ruby 2.7.8 and 3.2.9; review compatibility, resource accounting, diagnostic paths and ownership.
- [ ] Record native scratch-host evidence separately from production host qualification; update readiness, commit and publish the branch/PR under existing authorization.

Review focus: forged derived state; independently changed registry content; shared nested input mutation; aggregate limits across material and geometry work; empty-state behavior. Each is covered by a corresponding focused test. General PartSpec acceptance, persistence, undo/reopen and graphical host inspection remain outside this unit.

## Qualification and execution ledger

Baseline: main `25b949f68625ea1054d9ec4f194fba0ec443b329`, clean; Ruby 2.7.8 suite 91 tests / 1,433 assertions passed. Isolated linked checkout on `feat/material-bound-preparation`. Native worktree creation was unavailable for this projectless chat; the Git fallback created a separate checkout without changing main.

Task 1: RED observed 8 missing-entry-point errors before implementation. GREEN first focused run: 8 tests / 59 assertions. Additional aggregate-budget and construction-failure qualification brought the total to 101 tests / 1,505 assertions; full suite passed on Ruby 2.7.8 and 3.2.9, no failures/errors/skips. At work=16,000 standalone reference checking and standalone carcass geometry both succeed, while aggregate preparation fails atomically, deterministically; a default-budget retry succeeds. Tests also retain all 91 baseline cases.

Task 1 Ruling: the existing authored width parameter is `W`, not `width`; the fixture was corrected to use the established schema before GREEN. No production schema migration was introduced.

Native qualification is recorded in [scratch validation](native-scratch-validation.md), separately from this standalone module's tests. The previous user-executed fixture was not rerun on the later material preparation code. No second native execution or graphical inspection is claimed.

Next dependencies: supported physical PartSpec with explicit substrate/finished/surface/edge/grain semantics; accepted-state model dictionary and compare-and-swap transaction; native apply/undo/abort/reopen qualification; then host UI/packaging and dependent drawing modules. Unknown manufacturer characteristics and unresolved manual formulas remain unresolved rather than guessed.
