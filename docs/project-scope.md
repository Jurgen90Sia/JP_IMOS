# JP IMOS PRO project scope

Date:12 November 2026. Repository:[Jurgen90Sia/JP_IMOS](https://github.com/Jurgen90Sia/JP_IMOS). Branch:main.

The long-term goal is an original parametric furniture construction extension for desktop SketchUp 2021–2026. User-facing languages:sq/en. Canonical measurement unit:mm. One furniture model is intended to feed geometry, materials, BOM and technical drawings/PDF.

This baseline preserves the 14 Phase 1B research reports unchanged and adds a source-conflict register, a narrow expression/division specification and baseline validation. Original source manuals and copyrighted figures remain outside the public repository. Research references are evidence, not a license to copy proprietary implementation or assets.

The **only proposed first technical module** is the Parametric Expression and Linear Division Engine:a host-independent Ruby 2.7-compatible typed parser, evaluator, dependency graph and one-dimensional allocator. Its accepted subset and deferred grammar cases are defined in [16](phase-01/16-expression-division-spec.md). No production implementation is authorized by this document.

Cabinet geometry, construction rules, drawers, doors/materials/BOM, UI, technical drawing/layout/PDF and host integration are future work. The broader report12 backlog is a roadmap, not the current first-module approval scope.

Strict project exclusions:drilling, CNC, CAM, nesting, toolpaths and machine postprocessors. Pure final construction/fit geometry is conceptually distinct from a machine procedure, but no such geometry is implemented here either.

Phase 1B evidence remains PARTIAL where a historical source conflicts or lacks a contract. Phase 1C can validate and publish a documentation baseline without inventing a resolution. Full historical imos grammar compatibility and manufacturer profiles are not promised. Project license, release packaging and broader implementation scope require subsequent decisions.

**Phase 2 has not started. Explicit authorization is required before any engine implementation.**


Phase 2A authorization update (13 November 2026): the user approved implementing only the pure Parametric Expression and Linear Division Engine. This feature branch contains that tested module; earlier baseline-status paragraphs above describe the historical documentation baseline. See phase-02a/README.md and phase-02a/validation.md. No downstream module, SketchUp extension, RBZ or resolution of source conflicts is implied.

## Current direction — 17 November2026

The user's subsequent standing authorization covers continuing implementation, verification and integration without repeated approval. The requested product goal is a complete parametric module-creation workflow comparable in usefulness to imos. This is a target, not a measured compatibility percentage or an expansion into the excluded machine-processing functions. Historical baseline authorization paragraphs above remain records of their date.

Current code covers the expression/division core, exact authored zones, supported four-panel carcass construction, declared materials, revision-owned unbanded rectangular physical parts, checkpoints, world projection and the experimental host-document codec. Actual source/geometry atomic application remains the next dependency chain, defined by the [host plan](phase-02i/atomic-host-implementation-plan.md).

Product acceptance must ultimately demonstrate a user creating, resizing, subdividing, saving/reopening and reusing furniture modules in SketchUp, with supported backs/grooves, fronts/drawers, materials/edges and derived reports/drawings where each feature's contract is qualified. These remain the existing roadmap's work, not features delivered by the codec. Historical source conflicts, manufacturer-specific profiles and unqualified host behavior remain explicit gaps; no unsupported imos rule is silently guessed. Progress is reported by independently tested behavior, not a claim of100% equivalence.
