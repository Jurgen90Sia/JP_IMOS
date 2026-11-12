# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Dependency discipline — PROPOSED

The table names **static imports**, not every data-flow arrow. “Shared contracts” is the common schema/value-types/diagnostic layer, not an eighteenth feature module. It has no host dependencies. Library data and resolved snapshots are passed as DTOs rather than obtained through global services.

| Module | May import | Output consumed by |
|---|---|---|
| Project Manager | Shared contracts, Validation, Expression, Linear Division, Zone, Article, Material, Geometry, BOM, Drawing, Layout/PDF, host and UI ports | UI and persistence/export orchestration |
| Expression Engine | Shared contracts | Project Manager, Division, Zone, Rules, Drawer, Door |
| Linear Division | Shared contracts, Expression | Zone, Article orchestration |
| Zone Hierarchy | Shared contracts, Expression, Linear Division, Validation primitives | Article, Rules |
| Article Designer | Shared contracts, Element Library, Construction Rules | Project Manager |
| Construction Rules | Shared contracts, Expression, Drawer, Door/MultiPart, Validation primitives | Article / Geometry recipes |
| Element Library | Shared contracts | Article |
| Furniture Geometry | Shared contracts, Validation primitives | Project Manager / Material |
| Drawer | Shared contracts, Expression | Construction Rules |
| Door/MultiPart | Shared contracts, Expression | Construction Rules |
| Material | Shared contracts, Validation primitives | Project Manager / final snapshot |
| BOM | Shared contracts | Project Manager / reports |
| SketchUp Adapter | Shared contracts, host API | Project Manager ApplyResult; UI selection DTOs |
| HTML/JS UI | Protocol/schema contracts, locale catalogs | Project Manager commands |
| Technical Drawing | Shared contracts, Geometry pure utilities, Validation primitives | Layout/PDF |
| Layout/PDF | Shared contracts; optional serializer dependency behind port | Files; optional LayOut port |
| Validation/Testing | Production validators import only Shared contracts; test harnesses may import subjects/adapters | Every boundary / test reports |

Validation must be split into production pure predicates and external test harnesses to prevent a dependency cycle. TestUp is development-only and cannot be imported by production validators. Geometry pure projection/contour utilities are shared by Drawing; neither imports the other's orchestration.

## Port contracts

| Port | Contract | Failure semantics |
|---|---|---|
| ProjectStore | load(document_id) → ProjectDocument; save(document, expected_revision) → revision | conflict/schema/io diagnostic; atomic replacement |
| HostApply | apply(candidate, previous_mapping) → ApplyResult{revision, mapping} | abort operation; retain old revision |
| LibraryStore | resolve(definition_ref) → immutable definition | missing/version/license source error |
| ExportSink | write_atomic(name, bytes, source_revision) → receipt | old file retained until completed replacement |
| PDFSerializer | serialize(SheetSet, DrawingDocument, font_manifest) → PDF bytes | unsupported primitive/font/export diagnostic |
| LayOutPort | translate vector scene and sheet metadata → native document/export | optional unavailable capability |
| UiBridge | request(EditCommand) → response{request_id, revision, result, diagnostics} | typed error; no implicit synchronous return |
| HostSelection | selection_to_logical_ids() → IDs + foreign entities summary | missing/deleted entity diagnostic |
| Clock/ID providers | supplied timestamp / new ID | excluded from deterministic snapshot hash |

## Data-flow payload map

Input UI → Project Manager: allowlisted edit commands with expected_revision. Project Manager → Material: inherited material choices and thickness policy; Material → Project Manager/Expression: pre-resolved material IDs and thickness inputs. Project Manager → Expression: global typed parameter/analytic-anchor DAG. Expression → Division/Zone: resolved quantities in dependency order. Zone → Article: bounds, orientation and semantic boundaries. Element Library → Article: immutable definitions. Article → Rules: construction requests. Rules → Drawer/Door: specialized typed requests; these return recipes to Rules, never call Rules again. Rules → Geometry: part recipes. Geometry → Material: geometric part specs and pre-resolved material contexts. Material → Project Manager: fully resolved assignments without dimension changes; Project Manager validates and assembles Snapshot.

Zone inputs cannot depend on descendant element results. Cross-element references may target only declared analytic anchors in the acyclic typed DAG, never generated geometry measurements. The Project Manager scheduler resolves those anchors before downstream recipes. Material and Expression exchange data through orchestration, not mutual imports. Host undo/redo restores the canonical document from model attributes, rebuilds mapping and clears caches before commands or exports resume, as specified in 08.

Snapshot → HostApply: authoritative parts, assembly occurrence tree, placements and finishes. Snapshot → BOM: physical parts/hardware and grouping policy. Snapshot → Drawing: topology and semantic anchors. Drawing → Layout/PDF: vector scene plus view metadata. SheetSet + title fields → Layout/PDF: paper placement. Layout/PDF → serializer/sink or optional LayOutPort: immutable output data. UI receives summaries/diagnostics, not mutable core objects.

## Change propagation example

Changing width 600→800 invalidates clear width, X subdivisions, dependent front/drawer/shelf rules, affected solid geometry and their grouping/projections. Unchanged material definitions retain identity, but every exported document still carries the new snapshot revision. A failure in a drawer allowance blocks publication of the candidate; it does not leave a new BOM beside old geometry.

Dimension-affecting edge treatment choices, band thickness and allowance policy are part of Material's early context, not its late finish-binding stage. Recipes consume these inputs using declared semantic segment keys; Geometry validates the resulting contour and mapping. Late Material binding rejects missing mappings and cannot resize parts.

## Enforcement for Phase 2

Automated import checks should forbid Sketchup, UI, Layout and filesystem access in the pure domain core. No global active_model lookup outside the host adapter. No worker may discover parameters by traversing generated entity geometry. Module interfaces accept revisioned immutable DTOs; custom code callbacks are not library data.

The dependency graph is acyclic after excluding orchestration and test harness edges. Do not turn the evaluation data-flow diagram into mutual Ruby requires.



## Phase1B dependency additions and refinements

These refine the existing17 modules without creating a second architecture. Sources: Manual Artikull Parametrik.pdf pp. 6,25–26,43,51–55; Manual Menaxhimi i Elementeve.pdf pp. 11–24,29–42,77–80; Manual Manager.pdf pp. 9–10,89–91; Manual Skuadrim dhe Layout.pdf pp. 6–12.

1. Early Material emits finished substrate, dimensional surface-stack and edge-allowance inputs, not nominal procurement thickness alone. All dependent zone reservations, junctions, back seating and physical parts consume those resolved values. Late Material handles texture/visual bindings and cannot resize.
2. Division emits either typed interval/reference results or a part-local construction-pointset, depending on context. Zone Hierarchy consumes partition/layer references; MultiPart consumes pointsets/contours. Do not feed a pointset into compartment thickness subtraction.
3. Back reference-face/fit changes propagate through Construction Rules → Geometry → actual back/shelf/drawer clear envelopes → Drawing sections/dimensions. Geometric recess data belongs to final solid shape; no manufacturing dependency is introduced.
4. Part-local edge1 and measurement-frame transforms feed BOM reporting AND drawing orientation. They do not alter actual geometry volume. Independent-layer assembly intersections are validated before export.
5. Project Manager owns authored OrderGroup membership and recording scope; BOM remains a derived projection. Selection/filter commands consume typed domain predicates and return logical IDs, not mutable host objects.
6. Shared-front references and hardware proxies resolve to physical occurrence identities before BOM and Drawing. Multiple referring drawers cannot duplicate the same physical front.
7. Layout receives resolved TitleFieldBindings, viewport policies and metadata from one accepted Snapshot. It does not read mutable Manager UI or source DWG as authority.

Additional PROPOSED port contracts:
- LibraryStore.resolve(ref) remains read-only; LibraryStore.publish(definition, expected_version, scope) returns a new immutable version or conflict. No arbitrary code callbacks or mutation of library objects in-place.
- TemplateStore.resolve(ref, project_overrides) returns a frozen template; publish(template, scope, expected_version) explicitly distinguishes global and project-only changes.
- MetadataResolver.resolve(bindings, snapshot) returns typed values or missing/ambiguous-source diagnostics. PDF serializer never guesses proprietary malformed tags.
- ProjectSelection.query(predicate, scope, union, invert) returns a stable logical-ID set; adapter translates host selection independently.

Drawing and construction share read-only geometry/anchor contracts. A section engine must receive final fit/recess geometry and finished layer boundaries to show construction accurately; merely drawing the unmodified substrate bounding box would lose the documented back and finish relationships. Drawing never calls Rules to resize a part.
