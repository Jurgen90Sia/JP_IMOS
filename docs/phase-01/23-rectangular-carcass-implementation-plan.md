# Rectangular Carcass Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans, inline TDD, one final fresh-context review. User explicitly delegated decisions and requested uninterrupted work without approval questions.

**Goal:** Build an exact four-panel construction preview with explicit finished material stacks and derived rectangular solid envelopes.
**Architecture:** Closed request -> Materials::Context -> Construction::CarcassRule recipes -> Geometry::RectangularPanel -> immutable bound preview. Reuse ProjectCore validation/policy/budget and full Zones::Resolver; one request budget throughout.
**Tech Stack:** Ruby2.7/3.2, stdlib Digest/JSON, existing pure core, Minitest tests.
**Spec:** docs/phase-01/22-rectangular-carcass-spec.md. No host/UI/CNC/BOM/release artifact.

## Global constraints / review focus

All constraints in22 apply, especially nominal/finished separation, unverified caller catalog refs, request+project context binding, exact arithmetic, right-handed inward right/top frames and preview-only acceptance. Preserve all58 baseline tests/1012 assertions and historical14 reports. Inspect unsafe thickness fallback, implicit deductions, transform double-application, dimensional volume labels, quota bypass and partial outputs in final review.

## Files / interfaces

Create materials/context.rb, construction.rb, construction/request.rb, construction/carcass_rule.rb, geometry/rectangular_panel.rb; tests materials/context_test.rb, construction/{fixtures,carcass_test}.rb, geometry/rectangular_panel_test.rb. Extend sorted test discovery to these directories. Current documentation updated; no project-core schema fields added.

- Materials::Context.resolve(characteristic:,budget:,pointer:) -> owned immutable context; caller data validated/copied, normalized without nominal fallback.
- Construction::Request.validate(raw,budget) -> owned normalized frozen closed request. Core Document copy/check helpers may be reused; no user-provided validator callbacks.
- Construction::CarcassRule.build(article:,contexts:,budget:) -> reference envelope/opening and4 recipes; no ready host PartSpecs. Internal article is from trusted resolved snapshot.
- Geometry::RectangularPanel.from_recipe(recipe:,budget:) -> immutable derived rectangular finished geometry, no arbitrary holes/contours.
- Construction.build_carcass(document:,request:,numeric_policy:,limits:{}) -> atomic Result<preview> with request SHA and matching source project context. Input policy validated via existing helper. Material refs are not catalog existence checks.

## Task1: Closed finished-stack context

- [ ] Write failing CC03/CC04 tests for nominal19 vs substrate18.5+0.5+0.5=19.5, empty surfaces, retained near/far contributions, invalid/unknown/Float/inexact values and17-layer quota. Observe missing module failure.
- [ ] Implement Context.resolve with closed shape checks and typed exact positive Lengths. Use existing quantity validation and Frame.safe for every arithmetic step; retain source fields and catalog-validation status. Context freezes a copy, not caller data.
- [ ] Implement closed Request validation using the same context contracts for exactly four roles; policy/principle enum never becomes method dispatch. Canonical record order for request hashing.
- [ ] Run focused plus full suites on2.7/3.2; commit feat: resolve explicit additive finished panel stacks.

## Task2: Selected carcass rule recipes

- [ ] Write failing CC01/CC02/CC04/CC05 rule tests: 564/684 opening, asymmetric562/682, literal origins/bases, invalid clear opening, no fallback principle or guessed thickness. Selected article reference_extents drive dimensions even if root view is front.
- [ ] Implement pure four-role recipe generation with the formulas in22; material context supplied upstream. Stable role/occurrence refs, explicit owner root, no host geometry. Exact bounds checked before recipes returned.
- [ ] Run both runtimes/full suite; commit feat: compile rectangular carcass panel recipes.

## Task3: Rectangular finished geometry and public preview

- [ ] Write failing exact8-vertex/6-face geometry tests: volume, bbox, outward face winding using independent cross-product expectations, no interior intersections, all vertices within envelope. Assert general holes unsupported rather than claiming B14 completion.
- [ ] Implement rectangular converter from trusted recipes with one budget and4096-bit intermediate guards. Canonical SolidSpec retained; mesh derives from it. Geometry does not resolve materials, mutate recipes or build host entities.
- [ ] Implement build_carcass orchestration, request digest, matching source_context and immutable complete output. Test unknown article, invalid sibling-zone math, request key order/hash, translated/reused occurrences, malformed policies, repeated failure/recovery and no caller mutation.
- [ ] Run full suites; commit feat: derive exact rectangular carcass preview geometry.

## Task4: Qualification/review/integration

- [ ] Complete CC01–CC07 with fractional dimensions, resource/text/volume overflow, face/ownership audit, unknown construction fields and atomic failures. Run all old and new tests on real Ruby2.7.8/3.2.9; syntax/whitespace and proprietary-asset exclusions.
- [ ] One fresh-context review for rule/frame/material-budget/context bugs. Fix material issues with observed red/green regressions. Document unsupported catalog/substrate/back/front/host work honestly; do not call this an accepted furniture Snapshot.
- [ ] Commit qualification, push/create PR, verify remote, merge under uninterrupted authorization and retest main. No automatic expansion into an untested host adapter.

## Self-review

This satisfies a bounded B11/B12/B13 slice and only rectangular finished-envelope geometry from B14. Full material inheritance/grain/edges, general extrusion holes and accepted project construction persistence remain explicitly future contracts. Request digest prevents two distinct previews sharing only a project revision. Every public success is complete and immutable under one budget.
