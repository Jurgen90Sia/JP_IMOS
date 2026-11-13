# Exact Rectangular Zone Resolver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Continue the existing native inline/TDD workflow with one fresh-context whole-branch review after implementation.

**Goal:** Resolve validated project-core documents into immutable exact rectangular ZoneSnapshots: reference envelopes, named frames, physical partitions, explicit spacing reservations and independent contained layers.

**Architecture:** Validate authored input once, bind each pinned article definition, then traverse its zones parent-before-child in authored child order. The current Phase 2A parser/evaluator/allocator supplies arithmetic through a trusted adapter with one request-wide work counter. A signed-permutation frame module composes exact rational coordinates without SketchUp entities or trigonometry.

**Tech Stack:** Ruby 2.7-compatible syntax/stdlib, existing ProjectCore and Parametric, Minitest development tests, real Ruby2.7.8/3.2.9 qualification. No new runtime gem.

**Spec:** [18-project-zones-spec.md](18-project-zones-spec.md), approved design, sections5–10. Existing first-unit behavior: [project-core API](../phase-02b/README.md). Base integration commit: `10057315f39cfc77cc8d8af741030d3cda4f7d6e`.

## Global Constraints

- Work in the intended C:/Users/arkitekt2/Documents/JPMOS repository on a new feature branch, preserving main, all14 historical reports, current project-core contracts and all existing Phase2A fixtures.
- Public input is still jpimos.project-core/1; no schema migration or automatic dropping of fields. Ratios are exact normalized strings; no Float/epsilon rounding for zone allocation/containment.
- Numeric zone inputs remain exact; keep first-unit conservative rejection of approximate optional inputs. No manufactured defaults.
- Namespaced dimensions W/H/D retain article meanings. ZONE_U/ZONE_V/ZONE_W refer to the current oriented zone extents. Division X is selected-axis length; no synthetic Y.
- Physical partitions always use positive_intervals, reference origin0/direction+1. Reference-point/external-marker grammar cannot create physical zero/negative zones.
- Reservations/clearances occupy explicit authored slots. Never subtract panel thickness, groove depth, back setback or front allowance implicitly.
- Named plan/front/left_side frames are exact right-handed signed permutations from approved spec18. Article placement supports translation only. No arbitrary rotation/mirror approximation.
- Bounds for independent layers use the same unmodified parent; overlapping/coextensive zones are permitted, physical collision acceptance is not claimed.
- Project CoreBudget work100,000 is shared across validation, engine steps, frame math and traversal. Existing per-call Parametric caps, 4096-bit rational cap, 1000 expanded terms, zone depth32 and10,000 occurrence cap remain hard limits. Callers may tighten, never enlarge.
- No eval/user callbacks, thread-local/global counters, environment/file/network/host state, UI, geometry, RBZ, materials/BOM/drawing or machining features.
- Tests must pass on real Ruby2.7 and3.2; source examples and proposed rules retain their evidence labels. No new PDF inspection is claimed by this implementation plan.
- The user approves this execution plan before implementation, following the same review gate used for unit1.

## Scope boundary

This plan exposes **resolve_zones** only. Prepared revisions need the finished resolver but are independently reviewable transaction semantics; **prepare_revision remains deferred**, with PC08/Q02 explicitly not claimed here. No fake accepted state or placeholder snapshot is introduced. This preserves the user's immediate scope: calculate zones before geometry.

## Review Focus

1. Nested non-plan orientations can double-apply a basis/offset; Task2 tests front-under-front and Task3 tests oriented nested partitions using literal expected coordinates.
2. Many individually bounded expressions can bypass a request budget; Task1 tests shared-counter exhaustion and Task5 tests a whole document with many layer expressions.
3. Child authoring order differs from physical slot order; Task3 verifies ordering never changes coordinates or occurrence identity.
4. Layer endpoint0 without mm, approximate trig results, or unknown names in lazy branches can slip through; Task4 verifies exact Length typing and existing full declaration validation.
5. The same definition reused by two translated articles must not share mutable output or confuse article/project coordinates; Task3 tests independent immutable occurrences and project-point mapping.

## Public result contract

```ruby
JPImosPro::ProjectCore.resolve_zones(document:, numeric_policy:, limits: {})
# -> Result<ZoneSnapshot>; failure value=nil, never a partial tree
```

Outer Result keys remain Ruby symbols as in existing APIs. Snapshot/quantity record keys are strings, consistent with the authored document codec. Do not feed a snapshot to encode_document or pretend its derived schema is authored project-core/1.

Snapshot closed fields: schema=`jpimos.zone-snapshot/1`, project_id, source_revision, algorithm_version=`jp-rectangular-zones-v1`, policy_id, backend_id, articles, zones, diagnostics. diagnostics=[] on success; deep-freeze the entire value. Core metadata retains schema/profile_version and adds algorithm_version/policy_id/backend_id. Existing encode/decode metadata is unchanged.

Snapshot articles retain authored order and contain article_instance_id, definition_ref{id,version}, origin (three typed Lengths in project axes), reference_extents (W,D,H mapped to X,Y,Z), root_occurrence_ref. Do not add resolved physical bounds, usable volume or part counts.

Each zone has exactly the fields specified in18: occurrence_ref, parent_occurrence_ref or null, source_definition_ref, authored_zone_id, local_origin_in_parent, local_basis_in_parent, local_extents, article_origin, article_basis, occupied_slots, child_occurrence_refs. Occurrence refs are {article_instance_id,authored_zone_id}; definition refs are {id,version}. Positions/extents are three-element arrays of exact Length DTOs; basis is three basis-column arrays of signed integers, never Float. Top-level zones use parent-before-child depth-first order following authored ChildLinks; child_occurrence_refs preserves that same authored order.

Root's implicit parent frame is the article's plan box. Its parent_occurrence_ref is null, but local_origin_in_parent/local_basis_in_parent still record the named orientation transform (front origin(0,D,0), not an invented zero). article_origin/article_basis express the same resulting frame in article X/Y/Z. Project coordinates are article.origin + article-coordinate point; no translation is silently added twice to article_origin.

Occupied partition slots: slot_id, role(zone/reservation/clearance), axis(u/v/w), start, end, length; all positions refer to the current zone's oriented local axis. Slots remain in authored physical order. Independent-layer occupied records: slot_id, role=layer, bounds={u:[start,end],v:[start,end],w:[start,end]}; exact typed bounds in parent-oriented axes, placement order retained. Leaf occupied_slots=[]. Reservation/clearance slots create no zone or physical object.

Wrapped engine failures preserve code, grammar_version, source_span, symbol_ids, message_key and details; add json_pointer and entity_ref. A span indexes only that authored expression string. Example pointer: /definitions/0/zones/0/layout/expression/source. entity_ref identifies the failing occurrence. Do not replace a useful syntax span with a pointer into the whole JSON text. Non-expression frame/resource errors use an appropriate entity pointer and no fabricated span.

Validation order remains input/schema -> IDs/links -> topology -> parameter declarations/bindings -> resolution -> immutable output. Policy must be validated as required data. For resolution diagnostics collect bounded failures across independent branches/articles and choose lexical json_pointer, then article ID and zone ID as deterministic ties for reused definitions; skip descendants whose parent failed. Stop immediately on resource exhaustion. No error result publishes any successful sibling output.

## Files and internal interfaces

Create:

- lib/jp_imos_pro/parametric/work_counter.rb — engine-owned trusted counter with maximum100,000.
- lib/jp_imos_pro/parametric/internal.rb — trusted internal expression/division entry points sharing a counter; no new public grammar/policy callback.
- lib/jp_imos_pro/zones/frame.rb — exact Length/Rational frame math, signed bases, bounded numeric operations.
- lib/jp_imos_pro/zones/engine_bridge.rb — explicit DTO conversion, allowed scopes and wrapped diagnostics.
- lib/jp_imos_pro/zones/resolver.rb — iterative article/zone traversal, partition/layer scheduling, snapshot assembly.
- test/zones/{budget,frame,resolver,layers}_test.rb and fixtures.rb.
- docs/phase-02b/zones.md and zones-validation.md.

Modify existing Parametric::Budget/guard implementation only to support trusted shared counters internally; public operation signatures/results and normal step semantics stay unchanged. Modify ProjectCore::CoreBudget to own that trusted counter and debit core work into it; Document.validate still runs under one request budget. Extend ProjectCore::Fault diagnostic wrapping and public entry file; update test/all_test.rb to discover sorted zone test files with Dir.children, avoiding the known absolute-glob issue. Do not restructure unrelated modules.

Internal contracts:

- Parametric::WorkCounter.new(limit:) with integer1..100000; tick(count=1) and used; no callback registration.
- Parametric::Budget.new(limits, shared_counter: nil): preserve local steps cap; when present require exact trusted WorkCounter and debit both counters. Public caller data never constructs/injects the shared object through AST, symbols or numeric_policy.
- Parametric::Internal.expression(source:, symbols:, numeric_policy:, shared_counter:) and .division(source:, reference:, symbols:, context:, numeric_policy:, shared_counter:) -> existing engine Result shapes, using unchanged parser/type/evaluator/allocator bodies. Private common routines may be extracted to avoid duplicate evaluation logic. No thread-local meter or constant per-request state.
- ProjectCore::CoreBudget#counter gives the trusted request object; #tick maps exhausted engine-counter Fault to Core Fault with the current pointer.
- Zones::EngineBridge.expression(spec:, symbols:, pointer:, occurrence_ref:, policy:, budget:) -> exact Length DTO; .division(spec:, length:, symbols:, pointer:, occurrence_ref:, policy:, budget:) -> existing DivisionResult with explicit conversion, or wrapped Core Fault.
- Zones::Frame.plan(extents:, budget:) and .orient(frame:, orientation:, budget:) -> immutable internal frame={origin,basis,extents}, with Rational positions/extents and signed basis columns. .child(parent:, offset:, extents:, orientation:, budget:) -> {local_frame,article_frame}, retaining both the transform relative to the parent and its once-composed article transform for snapshot fields. .map_point(frame:, point:, budget:) -> three Rationals; bound every arithmetic operation.
- Zones::Resolver.resolve(validated_document:, policy:, budget:) -> immutable snapshot value. It consumes the one already validated document, binding helpers, and same request budget; it never invokes public decode again or creates a fresh CoreBudget per child.

### Task 1: Trusted shared engine budget

**Files:** work_counter.rb, internal.rb; minimal changes to parametric.rb/core.rb/division.rb and project_core/budget.rb; test/zones/budget_test.rb.

**Consumes:** unchanged Phase2A public contracts and current CoreBudget limits.
**Produces:** shared request accounting and trusted internal bridge entry points used by Tasks3/4.

- [ ] Write failing tests: a standalone simple expression succeeds; repeatedly evaluating individually valid expressions under one WorkCounter exhausts it; a new counter remains unaffected; division repeat expansion is charged; local10000 cap still applies when the shared counter has more capacity. Attempted public numeric_policy/AST user callback cannot become a work meter or execute.
- [ ] Run `ruby test/zones/budget_test.rb` and observe missing implementation/relevant failure.
- [ ] Implement typed WorkCounter and optional trusted Budget attachment; extract common evaluator/allocation routines behind internal entry points, sharing all parser/type/dependency/expansion work. Existing public functions continue to create independent local budgets and revalidate external ASTs. Engine-counter exceptions are never swallowed as successful partial results.
- [ ] Test invalid counter limits/type, frozen/untrusted policy data, failed calls consuming real work, and no request leakage. Use behavior tests, not source-text assertions about counter calls.
- [ ] Run `ruby test/all_test.rb` on both real runtimes, including all existing32 tests/706 assertions; commit `feat: share trusted work budgets across zone engine requests` after green.

### Task 2: Exact named frames

**Files:** zones/frame.rb; test/zones/frame_test.rb.

**Consumes:** trusted request budget, exact normalized quantities, signed-permutation conventions in spec18 section6.
**Produces:** Frame.plan/orient/child/map_point for traversal.

- [ ] Write literal expected fixtures:

```ruby
# Input extents(W,D,H)=(600,560,720), origin0.
assert_equal [0,560,0], front.origin
assert_equal [[1,0,0],[0,0,1],[0,-1,0]], front.basis
assert_equal [600,720,560], front.extents
assert_equal [0,560,720], front_under_front.origin
assert_equal [[1,0,0],[0,-1,0],[0,0,-1]], front_under_front.basis
assert_equal [560,720,600], left_side.extents
```

These shorthand values are hand-derived Rational arrays in tests, not a new public frame API with Float accessors.

- [ ] Observe failing test, implement the named axis permutation/origin offsets exactly, composing child offset and orientation once. Basis handedness remains positive. Invalid orientation/basis input returns E_FRAME_UNSUPPORTED; no arbitrary rotation normalization.
- [ ] Test signed mapping, fractional Lengths, project translation(10,20,30), read-only inputs and 4096-bit overflow in arithmetic. Example map point with independent input coordinate and origin each at2^4096-1 must fail the computed4097-bit sum; no giant result serialized.
- [ ] Run focused/frame plus combined suite on2.7/3.2; commit `feat: compose exact rectangular zone frames`.

### Task 3: Root/partition resolution and public snapshot

**Files:** engine_bridge.rb, resolver.rb, project_core.rb/diagnostics.rb, test/zones/resolver_test.rb and fixtures.rb; test/all_test.rb.

**Consumes:** validated ProjectCore records, Parameters.bind, trusted internal engine division and Frame methods.
**Produces:** resolve_zones with immutable closed snapshot fields, leaf/partition behavior and complete atomic failure. Independent layers return an explicit unsupported error at this intermediate commit until Task4; never a fake valid empty result.

- [ ] Reuse complete unit1 fixtures; add explicit slot IDs/roles and child links. Write Z01/Z02/Z03/Z05/Z06/Z09/Z10/Z12/Z13/Z15 independent expected tests. Z15 numeric counterpart: L1500, `1:18mm:1:18mm:1` ->488/18/488/18/488, without an extra deduction.

```ruby
assert_equal [291,560,720], first_child_extents
assert_equal [309,0,0], second_child_article_origin
assert_equal [291,560,720], second_child_extents
assert_equal [310,20,30], second_child_project_origin # u300 plus article origin10/20/30
```

The first three assertions are the reservation fixture; the last is the distinct equal-halves translation fixture. Helpers read typed DTOs without using resolver math to derive expected answers.

- [ ] Observe failures. Validate document/policy once, get definition pins, create root box(W,D,H), apply root orientation, and traverse an explicit bounded stack. Inject article parameters + current ZONE_U/V/W, then let division inject X. Y remains absent. Use positive_intervals/reference0/+1 only. Enforce actual expanded term count equals authored slots before creating child output.
- [ ] Fill occupied slots and child boxes from exact boundaries. Match child by slot ID, never by ChildLink array index. Reservation and clearance slots have no child. Preserve article order and parent-before-child authored link order separately from physical slot order.
- [ ] Test reversed child link ordering produces unchanged slot coordinates; unchanged zone IDs survive W600->800; repeated definition instances have distinct refs/data; root front frame is not shifted twice; empty projects yield complete empty snapshots; unused definitions stay validated structurally but generate no occurrences.
- [ ] Test engine syntax error wrapping retains exact source span/grammar/symbol IDs with definition expression pointer and occurrence context; failed sibling/child yields value=nil for the whole request. Snapshot and nested collections are frozen; caller input remains unchanged.
- [ ] Run both runtimes and existing contracts; commit `feat: resolve exact rooted zone partitions`.

### Task 4: Independent contained layers

**Files:** resolver.rb, engine_bridge.rb; test/zones/layers_test.rb.

**Consumes:** Task3 public snapshot/traversal, exact expression bridge and parent frame.
**Produces:** independent_layers resolution with explicit bounds and independent descendants.

- [ ] Write Z07/Z08 tests: two full coextensive layers each retain600/560/720; one subdivides without shrinking the other; zero-width, negative start, end past parent, reversed bounds each fail E_ZONE_CONTAINMENT. A fraction below0 is invalid even when its magnitude is less than0.001mm.
- [ ] Observe failures. Evaluate each axis's start/end using jp-core-v1 against the same parent bindings; require exact Length and 0<=start<end<=extent. Derive inherited child offset(start_u,start_v,start_w) and extents(end-start), then apply child orientation. Do not accumulate sibling offsets or subtract previous layer widths.
- [ ] Test endpoint Scalar0 -> E_UNIT_MISMATCH; `sin(pi/2)` converted to a Length -> E_INEXACT_DIVISION_INPUT; unknown symbol in an unselected lazy branch -> E_UNKNOWN_SYMBOL; division user variables require `$`; core optional-prefix behavior remains unchanged. No cross-zone lookups by string ID/path.
- [ ] Test placement order vs child-link order, empty independent-layer containers, front-oriented child bounds and fractional endpoints. Empty layers create no fake part or child. Complete occupied layer bounds remain explicit in snapshot.
- [ ] Run focused and combined suites on both runtimes; commit `feat: resolve independent exact zone layers`.

### Task 5: Atomic diagnostics, limits and full qualification

**Files:** final narrow corrections in affected modules; docs/phase-02b/zones.md, zones-validation.md; README.md; all affected tests.

**Consumes:** Tasks1–4 working public resolver.
**Produces:** reviewed narrow resolver ready for PR, exact qualification report and honest deferred-scope list.

- [ ] Add multi-error fixtures: independent invalid layer bounds/syntax at zone indexes2/10; reused definition failing in two articles; parent failure with an invalid descendant. Assert lexical expression pointer/tied occurrence IDs and no partial value. Global schema/link/topology/parameter errors still precede resolution errors.
- [ ] Add request-budget fixture with many individually valid20-term endpoint expressions: document validation alone fits the chosen work cap, shared resolution must exhaust it rather than reset per endpoint. Show the equivalent request succeeds with the normal cap if all quotas fit. Never enlarge hard defaults for the test.
- [ ] Verify source/token/AST/depth/rational/expansion limits remain enforced by real engine paths, plus zone depth and total occurrence cap before output growth. Failed request does not affect a fresh request or mutate inputs; repeat exhaustion is deterministic.
- [ ] Run complete suite on real Ruby2.7.8 and3.2.9, capture actual versions/counts, syntax and whitespace checks. All prior tests remain green; tests for new behavior must have observed red/green failures.
- [ ] One fresh-context whole-branch reviewer checks shared accounting, signed bases, topology/slot identity, endpoint typing, exactness, immutable/atomic results and unresolved construction assumptions. Resolve critical/high findings with regression tests before final qualification; document any genuine unresolved limitation.
- [ ] Record implemented fixtures Z01–Z15 where applicable; Z11 structural coverage is inherited and rerun. Explicitly leave PC08/Q02 prepared revisions NOT IMPLEMENTED. Describe named frames as original JP policy, not verified imos transforms.
- [ ] Commit `test: qualify exact zone resolution on supported Ruby versions`; publish branch and create a reviewable PR using the established workflow. Merge is a separate integration step. No proprietary PDFs/assets or runtime binaries are included.

## Self-review / handoff

Interfaces align: one CoreBudget/WorkCounter travels through validation, engine bridge, frame math, traversal and freezing. Task1 supplies shared accounting; Task2 supplies frames; Task3 consumes both and owns the complete public snapshot; Task4 extends the same traversal with layers. Task5 qualifies every boundary without adding a new module.

Design coverage: spec18 sections5–7 and ZoneSnapshot/resolve_zones parts of8 are implemented;9's combined quotas/diagnostics are tested; numerical Z fixtures become executable evidence. PreparedProjectRevision/prepare_revision and host acceptance remain explicitly deferred, avoiding a mixed transaction implementation in this arithmetic slice. Source references remain the inherited Phase1 audit; SC01/SC04/SC08/SC15 are not silently resolved.

This plan is ready for user review. Recommended method remains native inline execution with TDD and one final fresh-context review. After confirmation, execute continuously through Task5 without intermediate permission questions for reversible implementation work.
