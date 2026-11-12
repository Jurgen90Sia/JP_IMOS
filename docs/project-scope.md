# JP IMOS PRO project scope

Date:12 November 2026. Repository:[Jurgen90Sia/JP_IMOS](https://github.com/Jurgen90Sia/JP_IMOS). Branch:main.

The long-term goal is an original parametric furniture construction extension for desktop SketchUp 2021–2026. User-facing languages:sq/en. Canonical measurement unit:mm. One furniture model is intended to feed geometry, materials, BOM and technical drawings/PDF.

This baseline preserves the 14 Phase 1B research reports unchanged and adds a source-conflict register, a narrow expression/division specification and baseline validation. Original source manuals and copyrighted figures remain outside the public repository. Research references are evidence, not a license to copy proprietary implementation or assets.

The **only proposed first technical module** is the Parametric Expression and Linear Division Engine:a host-independent Ruby 2.7-compatible typed parser, evaluator, dependency graph and one-dimensional allocator. Its accepted subset and deferred grammar cases are defined in [16](phase-01/16-expression-division-spec.md). No production implementation is authorized by this document.

Cabinet geometry, construction rules, drawers, doors/materials/BOM, UI, technical drawing/layout/PDF and host integration are future work. The broader report12 backlog is a roadmap, not the current first-module approval scope.

Strict project exclusions:drilling, CNC, CAM, nesting, toolpaths and machine postprocessors. Pure final construction/fit geometry is conceptually distinct from a machine procedure, but no such geometry is implemented here either.

Phase 1B evidence remains PARTIAL where a historical source conflicts or lacks a contract. Phase 1C can validate and publish a documentation baseline without inventing a resolution. Full historical imos grammar compatibility and manufacturer profiles are not promised. Project license, release packaging and broader implementation scope require subsequent decisions.

**Phase 2 has not started. Explicit authorization is required before any engine implementation.**

