# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Schema principles — PROPOSED

Use a versioned JSON-compatible document schema (`jpimos.project/1`) shared by Ruby and UI boundaries. The following is a concrete schema specification for planning, not implemented validation code. Reject unknown executable fields. Store mm as finite JSON numbers, IDs as strings, arrays in declared order and object property names in stable ASCII. Decimal serialization policy must round-trip dimensions within 0.001 mm; display rounding is independent. Proposed geometry comparison epsilon is 0.001 mm, subject to real-host small-edge tests; it is not a substitute for SketchUp's own tolerance.

## Record definitions

“Required” refers to valid authoring or resolved state as stated. Optional fields cannot change output semantics without revision change.

| Record | Required fields and types | Invariants / links |
|---|---|---|
| ProjectDocument | schema:string; id:UUID; revision:integer≥0; locale:sq/en; units:mm; definitions:map; articles:array; materials:map; order_metadata:map; order_groups:array; recording_intents:array; template_refs:array; project_template_overrides:map; drawing_specs:array; resolved_snapshot:Snapshot | Unique IDs, finite numbers; document owns authored group/scope/template data; accepted snapshot revision matches document |
| ArticleDefinition | id, version, name_key, parameter_defs[], root_zone_spec, element_specs[], source_refs[] | Definition references acyclic; immutable version |
| ArticleInstance | id, definition_ref{id, version}, parameter_values:map, placement:RigidTransform, overrides:map | W/H/D resolve to positive Length; occurrence ID distinct from definition ID |
| ParameterDefinition | id, type:Length/Scalar/Boolean/Angle, expression or default, bounds, required:boolean | Exactly one input policy; bounds typed |
| ExpressionSpec | id, grammar_version, source:string, expected_type, scope_ref | Parsed AST is derived, not trusted imported executable data |
| ZoneSpec | id, parent_id or null, orientation, envelope_refs, divisions[], children[], anchors[] | One parent; child containment; no implicit thickness |
| DivisionSpec | id, axis:X/Y/Z, basis_frame_ref, tokens[], reservation_policy, boundary_ids[] | Tokens tagged fixed_length/weight/repeat; positive physical extents |
| ConstructionElement | id, owner_zone_id, type, rule_ref{id, version}, params, material_context, anchors | Produces zero or more parts; virtual flag explicit |
| AssemblyOccurrence | id, parent_occurrence_id or null, element_id, child_occurrence_ids[], physical_part_ids[], hardware_item_ids[] | No cycles or double ownership; stable occurrence path |
| PartSpec | id, occurrence_id, owner_element_id, role, geometry:SolidSpec, placement, substrate_dimensions_mm, finished_dimensions_mm, material_id, faces[], edges[], grain_uv, anchors[], provenance[] | Positive physical volume; valid contour; no host face IDs as authority |
| SolidSpec | kind:extruded_contour/profile_sweep; contour_uv_mm:loops; thickness_mm or sweep_path; topology_version | Outer loop and holes distinct; winding normalized; no self-intersection |
| Material | id, version, label, category, nominal_thickness_mm, surface_defaults, texture_ref or null, grain_policy, density_kg_m3 or null, source_refs[] | Hardware can omit panel thickness; density optional, never fabricated |
| FaceFinish | face_id, finish_id, texture_transform, side:front/back/edge | Own local reference; finish does not override substrate thickness |
| EdgeTreatment | segment_id, band_material_id or null, band_thickness_mm, band_width_mm, allowance_policy | Explicit null=no band; segment exists after contour generation |
| HardwareItem | id, occurrence_id, sku or null, quantity, placement, envelope_mm, source_refs[] | Visual/BOM only; no hole or machine fields |
| DrawerProfile | id, version, construction_kind:manufactured/system/purchased, required_inputs[], allowance_expressions, construction_rule_refs, source_refs[] | System dimensions require authoritative data; legacy generic_or_system is retired and requires explicit validated migration |
| SourceReference | id, kind:request/manual/repository/api/original, locator, page_pdf_index or null, printed_page or null, classification | VERIFIED manual rule must have available document and exact page |
| Snapshot | project_id, revision, rule_versions, articles[], zones[], assemblies[], parts[], hardware[], resolved_materials[], frozen_order_metadata, frozen_order_groups, frozen_article_part_metadata, accepted_template_versions, resolved_field_bindings, accepted_sheetset_revision, diagnostics[], content_hash | Immutable; all title/group/report sources are frozen at this revision; content hash excludes nonsemantic timestamps |
| HostMapping | schema_version, project_id, revision, logical_id_to_entity_refs, geometry_fingerprints | Derived; references may expire after undo/reopen |
| BOMDocument | source_revision, grouping_policy_version, rows[], diagnostics[] | Physical occurrences counted once; no virtual rows |
| DrawingDocument | source_revision, viewports[], primitives[], styles, annotations[], source_anchors[] | Pure vector scene; independent of host view pixels |
| SheetSet | id, version, sheets[], template_ref, title_values, source_revision | A sheet has paper_mm, margins_mm and viewport placements |
| Diagnostic | code, severity, entity_id or null, parameter_id or null, message_key, args, source_ref or null, span or null | Locale-independent code; no swallowing errors |
| EditCommand | protocol_version, request_id, project_id, expected_revision, command, payload | Allowlisted operations and schema; no eval/source execution |

## Concrete authoring example

The following partial record illustrates a valid input fragment, **not a complete ProjectDocument**. The proposal deliberately uses original internal names rather than assigning undocumented meanings to SL_* variables.

```json
{
  "schema": "jpimos.article-input/1",
  "id": "fe7c646e-f752-4f84-8de6-a535bc260d11",
  "definition_ref": {"id": "rectangular-carcass", "version": 1},
  "parameter_values": {
    "width_mm": 600,
    "height_mm": 720,
    "depth_mm": 560,
    "left_thickness_mm": 18,
    "right_thickness_mm": 18,
    "top_thickness_mm": 18,
    "bottom_thickness_mm": 18
  },
  "construction_principle": "top_bottom_between_sides",
  "locale": "sq",
  "units": "mm"
}
```

In this input fragment, each18mm thickness value means resolved finished-stack thickness, not nominal procurement thickness. Derived clear width is564mm; clear height is684mm. Depth remains unresolved until a back/front rule is selected. Never fill missing runner dimensions from guessed product defaults.

## Frames and geometry representation

RigidTransform stores origin_mm:[x, y, z] and basis:[[ux, uy, uz],[vx, vy, vz],[nx, ny, nz]], explicitly basis columns, with orthonormal vectors and positive determinant. Composition maps local point p to origin+u·p_u+v·p_v+n·p_n. Reject singular, sheared or nonuniformly scaled authoring placements. Optional mirror commands create normalized variants.

Contour coordinates are in a part's own u/v plane. Outer boundary and holes are closed implicit loops, without duplicate closing vertex; every contour segment gets a stable semantic segment key. Geometry generation resolves key-to-topology mapping, preventing banding from shifting to another edge when tessellation changes. Sweeps and profile caps need their own topology specification before implementation.

## BOM conventions

Group by versioned material ID, substrate contour/dimensions, thickness, grain, edge treatments, face finishes and selected reporting policy. Do not group merely by bounding box or material display name. Part placement/occurrence controls quantity, while definition identity can support optimization without suppressing duplicates. Hardware uses SKU+variant where available. Each row retains contributing part occurrence IDs.

Report substrate and finished sizes in separately labeled fields; board volume uses actual solid volume. Convert mm³ to m³ by dividing by 1,000,000,000; mass requires sourced density. Missing density yields no mass result, not zero. Edge length derives from selected contour segments once per physical occurrence.

## Revision and migration rules

Any semantic input/rule/library version change increments revision and invalidates affected projections. Stable IDs survive resize where identity survives; deleted IDs remain invalid and annotation anchors report conflict. Migrations are explicit schema-version-to-version transforms with validation before acceptance. Unknown newer schemas open read-only or fail clearly. Never drop unknown material/edge data silently.

## Localization

Persist locale-independent keys and numeric values. Labels and diagnostics resolve through sq/en catalogs; retain user-entered names verbatim. Albanian decimal entry can normalize in dedicated number widgets, while stored expressions retain canonical grammar. Font selection must preserve ë, Ë, ç and Ç in UI, SVG and PDF; Unicode glyph substitution needs validation.



## Phase1B schema changes — PROPOSED, page-grounded

These records refine the table above rather than introduce a parallel source of truth. Historical concepts are VERIFIED at the cited pages; exact JSON/property names and validation policies are JP proposals. Numeric unknowns carry explicit provenance/presence rather than fabricated defaults.

| Record/change | Exact proposed fields / invariant | Evidence |
|---|---|---|
| ArticleEnvelope | reference_carcass_envelope, physical_finished_envelope, front_envelope, long_piece_envelope; never substitute one for another | Manual Artikull Parametrik.pdf pp. 6,83–85 |
| ZoneSpec extension | division_mode=partition/independent_layers; layer_id; reference_side_id; axis_direction; start/end face selector(inner/outer/center); thickness_reservation; orientation_mode=plan/front/left_side | Manual Artikull Parametrik.pdf pp. 37–55; Manual Ndarja Lineare.pdf pp. 11–12 |
| ConstructionPointSetSpec | id, part_local_frame, two_axis_division_expressions, reference_measure_policy, point_ids, source_edge_ids, offset/extension recipes; no automatic compartment thickness deduction | Manual Menaxhimi i Elementeve.pdf pp. 30–35; Manual per krijimin e dyerve.pdf pp. 2–8 |
| MultiPartSpec | reservation_thickness_mm, physical_child_ids, support_panel_present, pointset_refs, child_contour_refs, display_proxy_ref; nonphysical reservation never removes physical children | Manual Menaxhimi i Elementeve.pdf pp. 29,36–42; Manual per krijimin e dyerve.pdf pp. 1,9–16 |
| Material / PartCharacteristic | nominal_purchase_thickness_mm, finished_substrate_thickness_mm, dimensional_surface_layers[], finished_stack_policy, grain_substrate, grain_by_surface, reporting_policy; resolve before geometry | Manual Menaxhimi i Elementeve.pdf pp. 7–24 |
| DimensionalSurfaceLayer | material_ref, side, nominal_mm, finished_mm, contributes_to_part_thickness, report_quantity_policy; decorative texture is separate | Manual Menaxhimi i Elementeve.pdf pp. 15,21 |
| EdgeTreatment extension | semantic_segment_id, finished_band_thickness_mm, nominal_band_thickness_mm, band_height_mm, compatible_panel_height_class, adjacent_segment_ids, join_policy, finish_stack_order, report_quantity_policy | Manual Menaxhimi i Elementeve.pdf pp. 17–18;00_Manager.pdf pp. 78–79 |
| PartSpec extension | substrate_geometry, finished_geometry, actual_volume, measurement_frame, reporting_dimensions, source_edge1_mapping; bounding-box reporting never changes solid volume | Manual Menaxhimi i Elementeve.pdf pp. 37–40;00_Manager.pdf pp. 47,65–66 |
| BackConstructionSpec | reference_member_policy, reference_face(inner/outer), setback_mm, per_edge_engagement_mm, fit_reference_thickness, fit_depth_allowance_mm, fit_width_allowance_mm, allowance_side | Manual Menaxhimi i Elementeve.pdf pp. 77–80 |
| RecessGeometrySpec | target_part_id, receiver_surface_ref, final_profile, extent, fit_relation_ref; purely final construction geometry; no tool/machine/process properties | Manual Menaxhimi i Elementeve.pdf pp. 79–80 |
| FrontLayoutPolicy | auto/manual, policy_scope, perimeter_gaps, central_gaps, divider_as_exterior, inset_overrides, manual_overlay_by_reference, source_sign_convention, frame_internal_opening_ref | Manual Menaxhimi i Elementeve.pdf pp. 121–128; Manual Artikull Parametrik.pdf pp. 62–74,78–83 |
| DrawerProfile extension | construction_kind(manufactured/system/purchased), raw_characteristics{presence, type, unit_provenance, value}, slide_reference, outside_safe_rules, inside_anchor_box, height/depth_selection_policy, role_offsets, bottom_reduction_case, shared_front_id | Manual Sirtaret.pdf pp. 7–16; Variablat e brendshme te Sirtareve ne Imos.pdf pp. 1–17 |
| Raw characteristic presence | present/absent/unknown independent from numeric0; absence-only fallbackSL_DR_Y=-SL_FR; source-unit UNKNOWN prevents unsafe automatic conversion | Variablat e brendshme te Sirtareve ne Imos.pdf pp. 1,7,13 |
| HardwareItem extension | visual_asset_ref, asset_local_transform, semantic_occurrence_id, optional_path_recipe, physical/purchased/reporting flags; one physical occurrence independent of proxies | Manual per futjen e dorezave.pdf pp. 2–6; Manual per futjen e kembeve.pdf pp. 2–4,7; drawer variables PDF18–19 |
| OrderGroup | id, name, description, parent_id, membership, placement; organizational grouping only; no implied physical solid or quantity | Manual Manager.pdf pp. 9–10,19–24;00_Manager.pdf same |
| RecordingIntent | scope=definition_global/project_local/occurrence_local; target_ref; keep_or_replace_prior; explicit publish creates new immutable definition version in JP | Manual Manager.pdf pp. 89–91;00_Manager.pdf pp. 89–91 |
| Article/part/order metadata | stable ID distinct from display position; descriptions/info1–10; optional barcode/price/reporting flags with provenance | Manual Manager.pdf pp. 19–28,44–47;00_Manager.pdf same |
| TitleFieldBinding | field_key, source_kind, source_id, format, fallback_policy, placement, font, justification; unknown proprietary tag cannot execute | Manual Skuadrim dhe Layout.pdf pp. 6–9 |
| ViewportSpec | view_basis, name, scale, crop, visibility, hidden_line_print_policy, paper_slot, source_binding, source_revision | Manual Skuadrim dhe Layout.pdf pp. 11–12 |
| TemplateDefinition | id, version, global_or_project_scope, base_ref, field_bindings, viewport_slots, paper_mm; local override cannot silently overwrite global | Manual Skuadrim dhe Layout.pdf pp. 4–6,9–13 |
| SourceReference extension | exact_filename, sha256, pdf_page_index(1-based), printed_folio, edition, classification, conflict_id or null, review_quality; supplied file hash identifies historical evidence | All source inventory01; Linear conflict03 |

Material.nominal_thickness_mm in the initial table is retained as a legacy procurement label only; it must not drive geometric Z. New authored documents use the explicit finished fields above. The migration must reject ambiguity, not copy nominal into finished silently. Finishes that are merely visual cannot resize; dimensional surface layers are resolved early and can resize.

Inside-box corner anchors are separate from usable_storage_volume; no automatic wall subtraction establishes the source inside box. A front part has one physical owner but can be referenced by multiple drawer assemblies via shared_front_id. Assembly membership, render proxies, organizational groups and report inclusion are four distinct relationships.

Migration rule:legacy generic_or_system cannot automatically identify purchased interiors. A known generic manufactured-box definition may migrate to manufactured after validation; known system definitions may migrate to system. Ambiguous/purchased cases require explicit selection and source provenance before write acceptance. Never default a missing kind silently.

ProjectDocument owns authored order/group/recording/template records. On acceptance, it freezes the metadata and organizational projections needed by MetadataResolver into Snapshot, including article/part descriptions, info fields, report flags and source IDs. Bindings resolve only against that frozen revision. SheetSet/template versions are pinned to the same accepted export context; later title/template changes create a new accepted context/revision before export. A source ID not present in frozen metadata yields a diagnostic rather than reading mutable UI/project state.

## Dimensional and provenance invariants

- A pointset may legally create external points and zero terminal intervals; a physical child contour/solid must remain valid.
- Independent zone layers may co-occupy parent space. Resulting physical-part intersections require explicit construction intent, not automatic suppression of all overlaps.
- Nominal material, finished substrate, face layers, edge allowance, MultiPart reservation and physical union must not be collapsed into one thickness field.
- Field-specific signed offsets normalize once at boundary; preserve source convention for traceability.
- A source-conflicted or unresolved numeric formula cannot be stamped VERIFIED solely because a proposed test computes a plausible answer.
- Generated BOM counts physical occurrences under explicit report policy; it does not equate group membership or repeated position strings with unique identity.
