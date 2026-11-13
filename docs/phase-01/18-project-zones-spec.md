# Phase 2B design: project core and hierarchical zones

Date: 13 November 2026 (Europe/Berlin). Status: PROPOSED; documentation prepared at the user's request. This is a reviewable design, not authorization to implement another module. Implemented dependency: Phase 2A, merged in `cb17fb55d4a00a3aa6255865e041ef5c71cb2118`.

This additive document refines [08](08-system-architecture.md), [09](09-data-model.md), [10](10-module-dependencies.md), and tasks B01/B09/B10/B33 in [12](12-implementation-roadmap.md). The 14 historical reports remain unchanged. It is the proposed next-slice authority for the project-core/zone subset; it does not redefine materials, construction, geometry, BOM or drawing contracts.

## 1. Outcome and approaches

The next implemented slice should validate and serialize authored article inputs, instantiate a versioned zone hierarchy, and produce an immutable **ZoneSnapshot** using the existing exact division engine. It must provide useful dimensions before any SketchUp geometry exists.

| Approach | Benefit | Cost / decision |
|---|---|---|
| Derive zones from SketchUp groups and measured bounds | Immediate visual modeling | Makes source intent and dimension authority depend on host geometry; rejected for this slice |
| Full furniture project, construction, materials and zones together | Broad model coverage | Too many unresolved construction contracts for one independently testable deliverable; defer |
| Pure authored project-core component plus exact rectangular zones | Reuses Phase 2A, tests identity/references and dimensions without host effects | Recommended design choice delegated to the author; starts with orthogonal boxes and explicit reservations |

The third approach follows the existing pure-core architecture. No new runtime dependency or expression language is proposed. All new record/property names, limits, identity rules, diagnostics and policy decisions below are **PROPOSED JP behavior**. Source-supported concepts are distinguished in section 12.

## 2. Scope and stages

Deliver this as two sequential implementation units after design approval:

1. **Project-core contract:** lossless JSON codec, record validation, pinned definitions, parameter bindings, immutable prepared revisions.
2. **Zone resolver:** rectangular root envelope, explicit axis partition, independent contained layers, stable authored zone identities, exact local/article coordinates.

Do not implement both as one undifferentiated change. Unit 1 is independently acceptable with no zone arithmetic; unit 2 consumes its validated records and Phase 2A. A later host adapter decides when a prepared revision becomes accepted.

Excluded: physical panel recipes, automatic panel deductions, angled/nonrectangular zones, arbitrary rotations/mirrors, nested subarticle instantiation, material stacks, front/back construction policies, collision detection between physical parts, persistent model dictionaries, undo/redo hooks, UI, BOM, drawings, PDF, RBZ and all machining features. Those cannot be inferred from a valid box tree.

## 3. Canonical component and compatibility

Proposed serialized component schema: **`jpimos.project-core/1`**. It represents the authored core component owned by the future full ProjectDocument. It is not a second live project store or an alternative full-furniture schema. Its standalone JSON is a portable component export for this slice.

The historical `jpimos.project/1` in report 09 was a proposal and has no implemented importer. It contains broader fields and finite JSON numbers. Never relabel such a document as project-core/1 or silently discard materials, drawings, host state or unknown fields. Import of that schema returns E_SCHEMA_UNSUPPORTED with an explicit migration requirement. A future full-project envelope will own exactly one core component and one accepted revision; it must pin its schema/profile version.

**Precedence refinement:** exact core quantities use Phase 2A ratio strings, replacing report 09's proposed finite JSON numeric dimensions within this component only. No generic 0.001mm import rounding is allowed. Physical-host tolerances remain a separate future adapter concern. No change is made to the documented semantics of nominal versus finished thickness.

Authored documents and resolved outputs are separate record types. A ZoneSnapshot is a derived, immutable zone result, never a full furniture Snapshot or evidence that any physical part exists. Do not serialize it back into authored zone specifications. Re-resolving the same document under the same qualified policy must produce identical exact zone dimensions.

## 4. Record contracts

Every object has a closed field set. Unknown fields fail validation at their JSON Pointer; fields are never silently removed. Fields shown as required must be present even if their value is an empty collection. UUIDs use lowercase canonical 8-4-4-4-12 hexadecimal strings, retained on unchanged identity; validators do not generate replacements.

| Record | Required fields | Contract |
|---|---|---|
| ProjectCoreDocument | schema, project_id, revision, locale, units, definitions, articles | schema above; nonnegative integer revision; locale sq/en; units mm; arrays preserve authored order |
| ArticleDefinition | id, version, label, parameters, root_zone_id, zones, source_refs | positive integer version; immutable pinned content; definition key is (id,version) |
| ParameterDefinition | name, expected_type, default_value, required | ASCII name; Length/Scalar/Boolean; default_value typed or explicit null; required Boolean |
| ArticleInstance | id, definition_ref, parameter_values, origin | definition_ref={id,version}; parameter_values maps names to typed values; origin is three exact Length values in project coordinates |
| ZoneSpec | id, orientation, layout, children, source_refs | no embedded parent pointer; parent inferred from unique incoming child link |
| LeafLayout | kind | kind=leaf; children must be empty |
| PartitionLayout | kind, axis, expression, slots | kind=partition; axis=u/v/w; expression={grammar_version:jp-division-v1,source}; slots described below |
| LayerLayout | kind, placements | kind=independent_layers; placements described below |
| ChildLink | zone_id, slot_id | one parent per zone; slot_id equals a partition slot ID or layer placement ID |
| PartitionSlot | id, role | stable UUID; role=zone/reservation/clearance; order matches expanded division term order |
| LayerPlacement | id, bounds | UUID; bounds={u:[start,end],v:[start,end],w:[start,end]}; each endpoint is an ExpressionSpec |
| ExpressionSpec | grammar_version, source, expected_type | jp-core-v1; source UTF-8/US-ASCII per engine; expected_type Length for dimensions/endpoints |
| SourceRef | requirement_id, classification, pdf, page, conflict_id | ID string; classification VERIFIED/INFERRED/PROPOSED/UNKNOWN; pdf string or null; page positive one-based integer or null; conflict_id string or null |

For PROPOSED/UNKNOWN refs without manual evidence use pdf=null,page=null. VERIFIED refs require both PDF filename and page. This validates provenance shape, not that a caller's VERIFIED assertion is true; source integrity needs the audit inventory/hash outside this component. No manual bytes, figures or executable paths belong in SourceRef.

Source-reference arrays may be empty for original designs. Text labels are valid UTF-8, at most 256 code points; sq/en user labels retain ë/ç and are not used as identifiers.

Identity checks:

- Project/instance/definition IDs are explicit. Article instance IDs are unique within the document. The same definition ID may occur only once per version; different versions may coexist.
- Within each pinned definition, zone IDs and layout slot/placement IDs are unique in their respective namespaces. Parameter names are unique and cannot rebind Phase 2A reserved names.
- root_zone_id identifies exactly one zone. Every other zone has exactly one incoming ChildLink. No self-link, cycle, missing link or unreachable authored zone is accepted.
- A partition zone-role slot has exactly one ChildLink; reservation/clearance slots have none. Every independent-layer placement has exactly one ChildLink. No child may reference another parent's slot.
- Resolved zone identity is the structured pair {article_instance_id, authored_zone_id}; identical definition zones in two article instances are distinct occurrences. Display order and dimensions are not identity.
- Definition content/version changes require a new version. Reusing a version with changed content in the same document is a duplicate-definition error. Cross-document version/content verification requires a future registry and is not claimed here.

## 5. Quantities, parameters and scope

Use the existing Phase 2A public typed DTOs unchanged:

```json
{"type":"Length","unit":"mm","numeric":{"numerator":"600","denominator":"1","exact":true}}
```

Scalar has no unit; Boolean has value true/false. Canonical normalized denominator is positive. The codec retains ratio strings; no Float conversion occurs. Revision and definition versions are JSON integers in 0..9007199254740991 (version starts at 1), checked without coercion. Reject JSON numeric dimension shortcuts such as width:600 and duplicate JSON keys before Hash materialization can overwrite them. Reject NaN/Infinity, invalid UTF-8, malformed ratios and unknown types.

Each definition declares **W, H, D** as required, exact positive Length parameters. They are ordinary declared names, not Phase 2A constants. All other parameters declare an explicit type; an exact typed default may be used only when the field is absent and required=false. If required=true and input absent, fail even if a default is supplied; validation therefore requires default_value=null for required parameters. Explicit zero is present, never a missing value. Reject undeclared overrides. All numeric inputs participating in zone geometry must be exact; missing manufacturer dimensions never get fabricated defaults.

Angle is not a supported Phase 2A type. This slice rejects Angle declarations as E_TYPE_UNSUPPORTED rather than labeling degrees/radians Scalar implicitly. Authored derived-parameter definitions and nested subarticles are deferred; no new variable-language adapter is needed in the first implementation.

Zone-local symbols: inputs are the resolved article parameters plus exact Length aliases ZONE_U, ZONE_V, ZONE_W for the current parent box extents. These aliases cannot be declared/overridden as article parameters. Division also receives reserved X equal to the selected axis length, as Phase 2A already implements. Y is not synthesized; this slice does not allow a user-declared Y. Each request gets a fresh symbol table; no global binding or geometry lookup.

Layer endpoints evaluate with jp-core-v1 and expected_type Length. Division source uses jp-division-v1 and `$name` for user variables. Neither form may read another zone's generated outputs, descendants, siblings, physical elements or host entities. Ancestor-relative behavior uses the current local box aliases, avoiding an unimplemented cross-zone DAG. Future analytic-anchor references require a new explicit contract.

## 6. Frames and envelope authority

Article reference dimensions are (W,D,H) along article axes (+X,+Y,+Z). Origin supplied by ArticleInstance translates into project coordinates. This slice supports translation only at article placement; arbitrary rotation and mirror import returns E_FRAME_UNSUPPORTED. A future host adapter must not silently coerce transforms to translation.

Every resolved box has an exact origin and a right-handed signed-permutation basis. Root plan frame is u=+X,v=+Y,w=+Z with extents W,D,H. Named orientation is a **view basis**, not a new envelope or a rotation of furniture:

| Orientation | u/v/w directions in the inherited box frame | New origin offset | Extent order |
|---|---|---|---|
| plan | +u,+v,+w | (0,0,0) | (U,V,W) |
| front | +u,+w,-v | (0,V,0) | (U,W,V) |
| left_side | +v,+w,+u | (0,0,0) | (V,W,U) |

These exact coordinate formulas are PROPOSED JP conventions. Historical view names are source-supported; these signed bases are not asserted to be vendor transforms. Compose each child orientation with its parent's basis once. For front, reversing w and shifting by V preserves the same occupied box. No arbitrary trigonometry or approximate transform participates in exact zone allocation.

Keep an inherited box's extents distinct from a parameter named W: in the table, U/V/W denote its pre-orientation local extent tuple, not a symbol-table rebinding. In tests and implementation use explicit names extent_u/extent_v/extent_w.

A root zone occupies the complete **reference carcass envelope**. Front/long-piece/physical-finished envelopes are not calculated here. Future fronts can extend physical geometry without mutating this reference box. This module cannot certify usable storage space or subtract a back panel.

## 7. Partition, reservations and layers

For a partition of local axis length L:

1. Parse the authored jp-division-v1 source with bounded Phase 2A parsing.
2. Call allocate_division with reference length L, origin 0, direction +1 and context **positive_intervals**.
3. Expanded term count must equal authored slots.size exactly. Otherwise E_ZONE_TOPOLOGY_CHANGED; do not remap IDs by nearest coordinate or array truncation.
4. Slot i occupies [b_i,b_(i+1)] on that axis and full parent extents on the other axes. Zone-role slots create child boxes; explicit reservation and clearance slots consume space but create no physical object or child zone.
5. Apply the child's named orientation to that inherited box, then resolve the child's own layout. Output traversal is parent-before-child in authored child-link order; partition coordinates are always determined by slot order.

There is no additional thickness_reservation field that secretly subtracts from L. To reserve an 18mm divider in 600mm, author `1:18mm:1` with roles zone/reservation/zone: lengths 291/18/291 and second child starts at 309. An expression `1:1` gives 300/300, regardless of any future material. Reservation role is a spacing intent, not a panel recipe, material thickness or BOM quantity.

Thickness/inner/outer/center construction choices remain upstream unresolved references until a separate construction module supplies an explicit box or spacing expression. Do not copy SC01's 19mm panel interpretation into zone arithmetic. A caller that intends a pre-deducted span must supply that span once; it cannot also add an implicit reservation.

Independent layers resolve all endpoint expressions against the same unmodified parent frame/extents. Require 0 <= start < end <= extent on every axis, exactly. Layers may be coextensive and overlap; their order does not subtract space from neighbors. Descendant partitions occur independently inside each layer. Bounds of one layer cannot refer to a previously resolved sibling. Overlap permission concerns abstract zones only; it does not approve physical intersections in later generated parts.

No reference_points division output may be promoted to a physical zone partition. The existing `0:1:0` markers and `-200mm:1:-200mm` external points remain valid Phase 2A pointsets and invalid positive physical partitions. Containment uses exact ratios; no tolerance makes a tiny negative span valid.

## 8. Public operations and revisions

Proposed namespace: JPImosPro::ProjectCore. Methods below are contracts only, not existing APIs.

| Operation | Inputs | Result value |
|---|---|---|
| decode_document | source:String, limits:CoreLimits | validated immutable ProjectCoreDocument |
| encode_document | document:ProjectCoreDocument, limits:CoreLimits | deterministic UTF-8 JSON string |
| resolve_zones | document:, numeric_policy:, limits:CoreLimits | immutable ZoneSnapshot |
| prepare_revision | current:, replacement:, expected_revision:Integer, numeric_policy:, limits:CoreLimits | PreparedProjectRevision; no mutation or publication |

Result fields follow Phase 2A ok/value/diagnostics/metadata. Core diagnostics add json_pointer and entity_ref; wrapped engine diagnostics retain original code, grammar_version, source_span and symbol_ids plus an expression-field json_pointer. A source span always indexes the expression string, never the whole JSON file. Policy/backend IDs are retained. Error value is null; no partial tree/snapshot is published.

ZoneSnapshot fields: schema=`jpimos.zone-snapshot/1`, project_id, source_revision, algorithm_version=`jp-rectangular-zones-v1`, policy_id, backend_id, articles, zones, diagnostics. Each zone includes occurrence_ref, parent_occurrence_ref or null, source_definition_ref, authored_zone_id, local_origin_in_parent, local_basis_in_parent, local_extents, article_origin, article_basis, occupied_slots and child_occurrence_refs. All positions/extents are typed exact Lengths; bases contain only -1/0/1. Snapshot diagnostics is empty on successful v1 resolution; failures return Result diagnostics.

PreparedProjectRevision fields: project_id, base_revision, next_revision, document, zone_snapshot. expected_revision must equal current.revision; replacement must keep project_id and current revision. Caller cannot select a revision jump. Successful preparation sets document.revision and snapshot.source_revision to current.revision+1. A stale or maximum revision fails before resolution. All semantic replacements, including labels/locale edits, create one prepared revision; no-op replacements are rejected as E_NO_CHANGE. Caller can compare normalized authored records; derived fields are excluded because authored records do not contain them.

Prepared is not Accepted. Until a host adapter exists, no project file/model dictionary or geometry is mutated by these operations. Future acceptance must publish the document, matching snapshot and host operation together. A failed preparation leaves the current immutable object unchanged.

JSON encoding policy: closed keys in documented record order, symbol-table keys sorted ASCII, authored arrays preserved, no insignificant whitespace, no timestamps, ratios unchanged, UTF-8 labels retained. A JSON string decoded and re-encoded may change key order/whitespace but must preserve all semantic data. Runtime Ruby hashes are not returned to UI without this explicit string-key codec.

## 9. Errors and resource controls

Core codes: E_INPUT_CONTRACT, E_SCHEMA_UNSUPPORTED, E_DUPLICATE_JSON_KEY, E_DUPLICATE_ID, E_REFERENCE_MISSING, E_DEFINITION_DUPLICATE, E_TYPE_UNSUPPORTED, E_PARAMETER_REQUIRED, E_PARAMETER_UNKNOWN, E_ZONE_CYCLE, E_ZONE_MULTIPLE_PARENTS, E_ZONE_UNREACHABLE, E_ZONE_TOPOLOGY_CHANGED, E_ZONE_CONTAINMENT, E_FRAME_UNSUPPORTED, E_REVISION_CONFLICT, E_REVISION_EXHAUSTED, E_NO_CHANGE and E_RESOURCE_LIMIT. Typed numerical/syntax/allocation errors reuse Phase 2A codes rather than invent equivalent messages.

Validation order: input/size/JSON duplicate keys -> closed schema/field types -> IDs/links/version pins -> tree topology -> parameters/types -> exact zone resolution -> immutable output. Within one stage use JSON Pointer lexical order for deterministic first error. Missing references and cycles cannot be hidden by a leaf's lack of arithmetic. Do not depend on object insertion order for diagnostic priority.

Proposed defaults (tighten only): JSON UTF-8 bytes 1,048,576; JSON nesting 64 before recursive materialization; definitions 100; article instances 100; zones per definition 1000; total resolved zone occurrences 10,000; zone depth 32; parameters per definition 256; label 256 code points; total document work 100,000 counted record/reference/node/engine steps. Fixed quotas apply to both authored and expanded occurrence counts; check products before allocating occurrence arrays. Deep/cyclic structures require bounded iterative validation, not native stack failures.

Phase 2A's existing per-call limits remain hard caps. The core must also debit all Phase 2A parse/type/evaluate/dependency/expansion steps into one request budget. An implementation may add a trusted internal budget adapter to Phase 2A, but cannot expose callbacks through public numeric_policy or allow limits above engine defaults. This adapter is a necessary dependency change, not an existing capability. Stop with E_RESOURCE_LIMIT before starting a call when no budget remains; never reset the global quota per zone or per article.

For JSON, Ruby stdlib JSON is the proposed dependency. Duplicate-key detection and pre-materialization nesting limits must be proven on both Ruby 2.7 and 3.2; a default Hash parse that silently overwrites duplicates is insufficient. A bounded dedicated duplicate-aware parse hook/codec may be needed; no evaluator dependency or native gem is approved. Read encoding errors as E_INPUT_CONTRACT without echoing credentials/source dumps.

## 10. Independent acceptance fixtures

These are proposed tests, not tests executed by this design task. Fixtures use exact Length DTOs even where short numbers are printed below.

| ID | Input / trigger | Independent expected result |
|---|---|---|
| PC01 | Round-trip W=3/10mm, Unicode label `Kuzhinë çeliku`, revision 7 | Ratio strings, label and revision unchanged; deterministic canonical JSON |
| PC02 | Duplicate JSON key revision, mixed field types, invalid UTF-8, unknown property | Structured error at pointer; no overwritten value or dropped property |
| PC03 | Full historical jpimos.project/1 or newer unknown core schema | E_SCHEMA_UNSUPPORTED; original source remains untouched |
| PC04 | Two instances share one pinned definition | Distinct resolved occurrence refs; definition zone identities reused only inside their definition |
| PC05 | Missing version, duplicate (id,version), duplicate article/zone ID | Missing/duplicate diagnostics; no implicit latest-version selection |
| PC06 | Missing required W; optional a absent default0; explicit a=0 | W missing fails; optional default0 and supplied0 both retained; no null-to-zero coercion |
| PC07 | Host Float, approximate W or Angle parameter | E_INPUT_CONTRACT/E_INEXACT_DIVISION_INPUT/E_TYPE_UNSUPPORTED respectively |
| PC08 | Replacement expected_revision6 against current7 | E_REVISION_CONFLICT, current object unchanged; valid replacement yields revision8 in both document and snapshot |
| Z01 | Root W600,D560,H720, plan, split u `1:1` | Children origin u0/u300, extents (300,560,720); total root remains (600,560,720) |
| Z02 | Same root split u `1:18mm:1`, roles zone/reservation/zone | Zone widths291,291; second origin309; reservation18 creates no zone or part |
| Z03 | First 300mm child from Z01 splits w `1:2` | Grandchild heights240,480; second origin z240; no thickness subtraction |
| Z04 | Root orientation front | Same occupied article envelope; basis (+X,+Z,-Y), origin(0,560,0), extents(600,720,560) |
| Z05 | Front-oriented root splits v `1:2` | Child heights240/480 in article Z; basis composed once; full article Y coverage retained |
| Z06 | Root orientation left_side | Basis (+Y,+Z,+X), extents(560,720,600); axis u partition divides depth, not article width |
| Z07 | Two coextensive independent layers, each bounds full parent | Both preserve full extents and distinct occurrence refs; one layer's partition does not shrink the other |
| Z08 | Layer start -1mm, end > extent, equal endpoints | E_ZONE_CONTAINMENT; no clipping, epsilon or fallback |
| Z09 | Partition 0:1:0 or -200mm:1:-200mm | E_DEGENERATE_INTERVAL from positive_intervals; no zero/negative physical zone |
| Z10 | 8{1} with eight slots then source changed to 7{1} | First resolves; changed topology fails E_ZONE_TOPOLOGY_CHANGED; no deleted ID remapping |
| Z11 | Root references missing child; shared child; cycle; orphan | Respective missing/multiple-parent/cycle/unreachable failure before allocation |
| Z12 | Resize W600 to W800 with `1:1` and unchanged zone IDs | Widths300->400; occurrence refs unchanged; prepared revision increments once |
| Z13 | Origin(10,20,30), plan partition u1:1 | Second child article-origin(300,0,0), project-origin(310,20,30) derived by explicit translation |
| Z14 | Front/part metadata not part of core input | Unknown fields rejected; module never changes carcassD or claims physical collision clearance |
| Z15 | SC01 reference1500, explicit two18mm reservations | No vendor interpretation: arithmetic uses exactly the caller-authored slots; no additional 19mm deduction |
| Q01 | Deep JSON65, zone depth33, oversized occurrence product, depleted engine-step budget | E_RESOURCE_LIMIT before native recursion/allocation; deterministic repeated failure |
| Q02 | max revision9007199254740991; no-op replacement | E_REVISION_EXHAUSTED; E_NO_CHANGE respectively |

Z15 is a scope-isolation test, not evidence resolving the historical 1500/19mm conflict. Add a fully explicit numeric counterpart when implementing it: `1:18mm:1:18mm:1`, L1500 => three488mm zones and two18mm reservation slots.

## 11. Proposed implementation sequence after approval

This is design decomposition, not the execution plan. No task is started here.

| Unit | Responsibility / likely files | Acceptance |
|---|---|---|
| 1a | project_core/codec.rb; test/project_core/codec_test.rb | PC01–PC03, duplicate-aware bounded parse and exact DTO round-trip |
| 1b | project_core/document.rb; validator.rb; test/project_core/document_test.rb | PC04–PC07, Z11 structural invariants, quotas |
| 2a | zones/frame.rb; test/zones/frame_test.rb | Z04–Z06/Z13; signed-permutation basis and containment |
| 2b | zones/resolver.rb; parametric trusted request-budget adapter; test/zones/resolver_test.rb | Z01–Z03/Z07–Z10/Z12/Z15, Q01 |
| 2c | project_core/revision.rb; test/project_core/revision_test.rb | PC08/Q02, immutable prepared revision and atomic failures |

Keep public entry points in lib/jp_imos_pro/project_core.rb and focused files under lib/jp_imos_pro/project_core and lib/jp_imos_pro/zones. Use Ruby 2.7 syntax/stdlib; run meaningful red/green tests and the existing Phase 2A suite on real Ruby2.7 and3.2 after each affected slice. Do not restructure the current engine merely for naming consistency.

## 12. Evidence trace and unresolved decisions

This design inherits inspected manual evidence from the existing Phase 1B/1C audit; PDFs were not newly re-extracted in this design task. Exact pages below are evidence locators carried forward from reports 02/09/13/15. They support historical concepts, not the proposed JSON schema or coordinate formulas.

| Requirement | PDF | Page | Documented behavior | Formula / explicit JP policy | Module | Test | Status |
|---|---|---|---|---|---|---|---|
| PB-AD01 | Manual Artikull Parametrik.pdf | 4–6 | Carcass reference differs from overall projections/fronts | Preserve caller W/D/H; no union-derived resizing | ProjectCore/Zone | Z01,Z14 | VERIFIED concept; PROPOSED DTO |
| PB-AD02 | Manual Artikull Parametrik.pdf | 37–50 | Hierarchical zones/subarticles | One rooted zone tree; nested subarticles deferred | Zone | Z03,Z11 | VERIFIED concept; PROPOSED limited subset |
| PB-AD03 | Manual Artikull Parametrik.pdf | 51–52 | Independent overlapping zone layers | Same parent, independent contained boxes | Zone | Z07 | VERIFIED concept; PROPOSED validation |
| PB-LD07 / SC01 | Manual Ndarja Lineare.pdf | 12 | 487.3/474.7 discrepancy in 1500/19 example | No implicit panel count/deduction | Zone/Construction boundary | Z15 | UNKNOWN source resolution; contained |
| PB-LD02 / SC04 | Manual Ndarja Lineare.pdf | 6 | Fixed repeat and historical n* family | Only existing fixed repeat; explicit slot-count failure | Zone/Parametric | Z10 | VERIFIED family; UNKNOWN n* edge behavior |
| PB-LD03 | Manual Ndarja Lineare.pdf | 7–8 | Reference/external point family | Existing reference_points stays separate from physical zone partitions | Zone | Z09 | VERIFIED concept; PROPOSED boundary |
| JP-PC01 | null | null | Original exact project-core codec | Ratios retained, no 0.001mm rounding | ProjectCore | PC01–PC03 | PROPOSED |
| JP-PC02 | null | null | Original prepared-revision contract | next=current+1; no host acceptance | ProjectCore | PC08,Q02 | PROPOSED |
| JP-ZF01 | null | null | Original named signed-permutation frame convention | Explicit bases/origins in section6 | Zone | Z04–Z06 | PROPOSED |

Open source conflicts remain listed in report15. In particular SC01 construction deductions, SC04 repeat topology, SC08 face offsets and SC15 cross-edition X/Y pointset labels are not solved by this model. The engine accepts explicit spans/bounds and never stamps inferred construction math VERIFIED.

Design approval is needed before the implementation plan and code. Required follow-on decisions within that review: accept the project-core component boundary, exact serialized ratios, the named frame conventions and the explicit reservation-slot policy. These are presented as the author's recommendation, not prior user-approved behavior. Future decisions on full-project schema migration, arbitrary transforms, physical construction, host transaction acceptance and distribution licensing remain outside this slice.
