# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Phase1B verified construction evidence

This section replaces blanket imos-UNKNOWN statements from the initial Phase1 draft. The coordinate table below remains an original JP example, not a universal historical dimension solver. All locators are exact one-based PDF pages.

| Rule ID | PDF | Page(s) | Classification | Documented behavior / constraint |
|---|---|---|---|---|
| C01 | Manual Menaxhimi i Elementeve.pdf |7–9,20–24| VERIFIED | Raw material, surfaces, edges form part characteristic; construction principle uses it. Geometry and metadata are layered. |
| C02 | Manual Menaxhimi i Elementeve.pdf |11,15,18,21| VERIFIED | Nominal purchase and finished thickness differ; example19→18.5 substrate,10→9 edge. Part Z depends on finished material AND surfaces. |
| C03 | Manual Menaxhimi i Elementeve.pdf |15,17–18,22–23| VERIFIED | Edge height/width differs from band thickness; panel-height compatibility classes; substrate/surface grain separately oriented; finishes may contribute material-list entries. |
| C04 | Manual Menaxhimi i Elementeve.pdf |65–69| VERIFIED | Top/bottom between/spanning/angular modes; unequal-thickness miter and nonparallel-side choices. Front/rear orthogonal/oblique and depth-reference policies are independent. |
| C05 | Manual Menaxhimi i Elementeve.pdf |67,71–75| VERIFIED | Shelf positive projection/negative retraction; intermediate vertical offset is insertion-reference based; rails replace solid shelf with separate front/rear characteristics and dimensions. |
| C06 | Manual Menaxhimi i Elementeve.pdf |77| VERIFIED | Back reference may be sides, top/bottom or a perpendicular member. Engagement is positive into perimeter/negative smaller. Rear setback references INNER or OUTER back face. |
| C07 | Manual Menaxhimi i Elementeve.pdf |78–80| VERIFIED | Back size, engagement and groove fit are distinct. Fit-depthX/fit-widthY allow positive enlargement/negative reduction; width allowance has inside/outside side. Keep final fit geometry only; no process/tool representation. |
| C08 | Manual Menaxhimi i Elementeve.pdf |85–92| VERIFIED | Hinged/flap, single/double, inset/overlay fronts; inner-face insertion and optional add-thickness; hardware/stop members carry separate positions. Manual overlays use positive projection/negative inset convention. |
| C09 | Manual Menaxhimi i Elementeve.pdf |93–97| VERIFIED | Sliding/folding leaf division; track insertions separate; meeting alignment versus equal physical widths differs with asymmetric overlays. Reveal values positive even for inset. |
| C10 | Manual Menaxhimi i Elementeve.pdf |103–119| VERIFIED | Long pieces can span articles. Worktop/plinth NEGATIVE projection/POSITIVE insertion differs from shelf signs; do not normalize by field name alone. Some max-length prose is internally suspect. |
| C11 | Manual Menaxhimi i Elementeve.pdf |121–128| VERIFIED | Reveal modes distinguish perimeter/central/oblique directions, inset overrides and divider-as-exterior.3mm central gap gives1.5mm each side centerline. Article policy overrides order; auto-off uses manual values. |
| C12 | Manual Menaxhimi i Elementeve.pdf |29–35| VERIFIED | MultiPart virtual thickness reserves a construction envelope independently from physical children. Part-local pointsets use boundary/fixed/repeated/offset/intersection recipes. |
| C13 | Manual per krijimin e dyerve.pdf |1–8| VERIFIED |2020 MultiPart tutorial corroborates reservation/point semantics; point update with changed count requires reconstruction; dependent children prevent point deletion. |
| C14 | Manual Menaxhimi i Elementeve.pdf |36–42| VERIFIED | Child horizontal polygons/vertical two-point members have own dimensions/characteristics;90-degree rotation/Y flip changes edge mapping; report frame can use bounding-box or actual edge-oriented extents; proxy display is separate from physical children. |
| C15 | Manual per krijimin e dyerve.pdf |9–16| VERIFIED | MultiPart children, Z offset, edging and measurement-axis choices; title is broader than doors. More than four contour points supported. |
| C16 | Manual Ndertim i Lire.pdf |4–27| VERIFIED | Linked2D plan/section builds3D; segments carry characteristics and reference marker; guide-line thickness does not replace finished material thickness. Extrusion has insertion point. |
| C17 | Manual Ndertim i Lire.pdf |28–40| VERIFIED | Profile/path prefabricated pieces, embedded article front marker and end-to-face fitting; no general solver formula given. |
| C18 | Manual per futjen e dorezave.pdf |2–6| VERIFIED | Catalog/set and underlying asset are different; copied set can initially alias same underlying entry. Visual origin can require translation/rotation. No general handle setback formula documented. |
| C19 | Manual per futjen e kembeve.pdf |2–4,7| VERIFIED | Visual leg reference below panel is distinct from excluded payload references. Geometry/catalog dimensions not established. Drilling procedures excluded. |
| C20 | Manual Sirtaret.pdf |5–7,11–22| VERIFIED | Manufactured, purchased, system drawers; slide references top/center/bottom; shared front can serve two interiors; bottom/perimeter joints selectable. Drawer-side upper edge is edge3. |
| C21 | Variablat e brendshme te Sirtareve ne Imos.pdf |1–2,7–9,13–14| VERIFIED | Outside box reduces carcass interior by configured safe distances, excludes drawer front from containment; inside box supplies construction corner anchors, not storage volume. |
| C22 | Manual per krijimin e texturave.pdf |1–3| VERIFIED | Render principle applies to material/surface/edge; image, wrapper, reflectivity, scale independent. Scale unit UNKNOWN; texture does not establish physical thickness. |
| C23 |00_Manager.pdf; Manual Manager.pdf|47| VERIFIED | Finished720×570×18 and raw718.60×568.30×18 coexist in illustrated part. Which individual edge owns each deduction is not specified. |
| C24 |00_Manager.pdf; Manual Manager.pdf|65–66,78–79,82–84| VERIFIED | Edge1/reorientation, split/merge/adjacency, profile assignment and visible/covered finish stacking are explicit. Do not restrict model to four numbered edges. |

### Back, fit and frame equations — INFERRED within an explicit JP frame

For compatible rectangular clear openingCw×Ch and signed per-edge engagementeL/eR/eTop/eBottom: back width=Cw+eL+eR; height=Ch+eTop+eBottom. With chosen JP +Y toward rear, carcass rear datumD, setbacks and finished back thicknesst: outer-face setback gives y_outer=D−s, y_inner=D−s−t; inner-face setback gives y_inner=D−s, y_outer=D−s+t. EvidenceC06 establishes reference choices; these equations are original formalization, not quoted universal imos formulas. Nonrectangular/angled cases require their own solved boundary geometry.

Recess/groove records describe final receiving shape and fit allowance only. Back engagement does not equal groove allowance. No cutter, pass, drill, toolpath or machine-code entity exists. Exact arbitrary corner treatment remains UNKNOWN.

### Sign and policy normalization

Persist source field identity and sign semantics at import/review boundary. Shelf positive projection (C05), hinged manual overlay(C08), sliding positive reveal(C09), long-piece negative projection(C10), and Manager positive local shortening(00_Manager.pdf pp. 75–77) are different. Normalize into explicit physical direction vectors and semantic reference faces; never infer direction from one global “offset_mm” sign rule.

Article-specific reveal and local production metadata override project/principle values (**Manual Artikull Parametrik.pdf pp. 12,18; Manual Menaxhimi i Elementeve.pdf pp. 125**). This does not establish a universal inheritance order for all material fields; JP's general inheritance chain below remains PROPOSED.


## Coordinate and rule conventions — PROPOSED

All dimensions are mm. Article origin is front-left-bottom; +X right, +Y toward the back, +Z upward, a right-handed frame. An element frame uses local u/v in its broad face and local n through thickness. Store orthonormal basis columns and translation; require determinant +1 for ordinary parts. Explicit mirrored variants must normalize face winding and grain; do not hide them in negative scale. Store nominal geometry at actual dimensions; instance transform is placement, not dimension scaling.

Plan construction uses screen axes (X, Y), normal +Z. Front elevation uses (X, Z), normal −Y. The documented construction mode is LEFT-side elevation; JP local side basis uses (Y, Z), normal +X as an explicit chosen mapping and is not asserted to be the proprietary frame. The viewing direction is opposite the outward normal. Zone dimensions and near/far reference faces are named, not inferred from a viewport. Historical orientation choices are verified in Manual Artikull Parametrik.pdf pp. 4–5; the exact JP matrix/origin convention remains PROPOSED.

ConstructionRule takes a resolved zone, parameters, anchor references, rule version and pre-resolved material/thickness context; it emits ElementRequests, PartRecipes, HardwareRecipes and diagnostics. Only Geometry converts recipes into validated PartSpecs; rules cannot bypass that conversion or write SketchUp entities. A physical part belongs to one element; a MultiPart assembly owns multiple elements or parts. Reused definitions require per-instance identity for BOM quantity.

## Element rule catalog — all original proposals

Notation: W, H, D are reference_carcass_envelope dimensions, not overall visible bounds; L/R/T/B are resolved finished-stack panel thicknesses, including dimension-affecting face layers under the selected characteristic. Cw=W−L−R; Ch=H−T−B. Clear depth Cd is explicitly resolved after back positioning and front reservation. Material policy M: inherited physical characteristic, explicit dimensional layers, optional visual face overrides, grain vector in u/v and per-contour-segment edge records. Physical parts require positive extents, valid material and non-self-intersecting contour.

| Element | Local face axes u/v; n | Reference and position | Dimension rule / parameters | Relationships and validation |
|---|---|---|---|---|
| Left side | +Y/+Z; +X | x=0, near/front/bottom | D×H×L | Article carcass; M; L>0 |
| Right side | −Y/+Z; −X | x=W, far/back/bottom face origin | D×H×R | Same carcass; account for inward thickness |
| Top | +X/−Y; −Z | z=H, y=D, inner left x=L | Cw×D×T | Between sides selected; alternative spanning rule is separate |
| Bottom | +X/+Y; +Z | z=0, x=L | Cw×D×B | Between sides; H≥T+B |
| Fixed shelf | +X/+Y; +Z | inner opening at lower face z_s | (Cw−side_clearances)×Cd×t_s | Parent zone; bounded z and no unintended collision |
| Adjustable shelf | +X/+Y; +Z | shelf lower-face anchor | Explicit side/front/back clearances | Position only; no drilling model or hole pattern |
| Partition | +Y/+Z; +X | split boundary x_p | Cd×Ch×t_p | Explicit reservation side/center; no double thickness deduction |
| Back | +X/+Z; −Y | Outer-reference example:y_outer=D−setback; inner-reference selector uses different face | Width/height from selected reference/engagement rule | Thickness into cabinet from outer face; see C06 equations for inner reference |
| Door | +X/+Z; −Y | Inner door face y=−front_gap; finished thickness extends outward along−Y | Opening + overlays − explicit reveals | Parent front zone; swing metadata optional; clearance check |
| Drawer front | +X/+Z; −Y | front opening reference | Width/height from front layout | Links drawer assembly; reveal separate from runner allowance |
| Drawer side | +Y/+Z; ±X via valid basis | Box envelope side anchors | Sourced depth and generic height; side thickness | Left/right instances; no manufacturer dimensions invented |
| Drawer back/internal front | +X/+Z; −Y | Inside box ends | Box width−side thickness sum under selected butt rule | Join style and bottom rule explicit |
| Drawer bottom | +X/+Y; +Z | Lower box reference plus offset | Overlay/inset/support rule, not universal formula | Must fit selected rule; thickness independent |
| Plinth | +X/+Z; −Y | setback and elevation anchors | Span, height, thickness | Article child assembly; no support claim from visuals alone |
| Leg | Profile-defined rigid frame | Corner/edge offsets and height | Height, visual envelope, SKU | Hardware item; positive support elevation |
| Handle | Profile-defined rigid frame | Front-local anchor, rotation, offset | SKU and display envelope | Purchased hardware; no hole spacing or machining output |
| Profile | Tangent/cross-section basis | Valid path and start reference | Section polygon and sweep path | Reject degenerate sweep/self-intersection |
| MultiPart | Assembly frame | Parent anchor and ordered children | Rule-controlled child dimensions | Acyclic membership; BOM physical leaves only |
| Virtual element | Named frame | Zone boundary or reserved space | Envelope/reservation only | No material mass, no geometry/BOM unless explicit debug display |
| Construction point | Point + basis | Boundary identity plus signed offset | Reference expression | Zero volume; no BOM; reject dangling references |

Where a table dimension is a face dimension, the stated basis determines world placement. Validate transformed corner extents, not only the dimension tuple. For example the top's −Y/−Z basis and y=D, z=H origin place it inside the envelope. Right-side basis starts at y=D to span back toward the front. These bases avoid inconsistent mirrored normals.

## Configurable connection situations

| Rule | Proposed calculation / choice | imos evidence |
|---|---|---|
| Top/bottom between sides | x=L, width=Cw under selected rectangular JP rule | VERIFIED conceptual mode:Manual Menaxhimi i Elementeve.pdf pp. 65–67; JP coordinates PROPOSED |
| Top/bottom span sides | width=W under selected rectangular JP rule | VERIFIED mode:Manual Menaxhimi i Elementeve.pdf pp. 65–67; exact corner formula contextual |
| Overlay back | Explicit reference-face and engagement policy; separate reference/physical envelope | VERIFIED choices:Manual Menaxhimi i Elementeve.pdf pp. 77; JP solver context-specific |
| Inset back | Outer-reference inner face y=D−setback−t_back; inner-reference case differs | VERIFIED inner/outer selector:Manual Menaxhimi i Elementeve.pdf pp. 77; equation INFERRED in JP frame |
| Overlap | Named owner/overlap/context; intentional intersections tagged | VERIFIED examples:Manual Menaxhimi i Elementeve.pdf pp. 88–97; formal collision policy PROPOSED |
| Virtual thickness | Separate reservation; physical descendants may remain | VERIFIED:Manual Menaxhimi i Elementeve.pdf pp. 29; Manual per krijimin e dyerve.pdf pp. 1 |
| Material inheritance | Part override > element > zone > article > project is JP proposal | General chain UNKNOWN; article/order reveal priority VERIFIED inManual Menaxhimi i Elementeve.pdf pp. 125 |
| Edge treatment | Per-segment finished/raw policy; component-local sequence | VERIFIED concepts:Manual Menaxhimi i Elementeve.pdf pp. 17–23;00_Manager.pdf pp. 47,78–79; exact deduction policy contextual |

A connection situation is a rule input describing neighboring faces and which member spans. No fastening, connector machining, drilling or tool geometry is generated. Furniture fit validation is geometric; structural load certification is outside supplied evidence.

## Drawer assemblies

VERIFIED outside box is an admissible envelope after configured safe-distance reductions; drawer front is exempt from its containment. VERIFIED inside box is a nested construction-reference box whose corners anchor parts/connectors, not usable storage after wall subtraction (Variablat e brendshme te Sirtareve ne Imos.pdf pp. 1). Store optional usable-storage calculations separately. Drawer parts derive only after a selected profile supplies required dimensions, unit mapping and provenance.

Generic independent inputs:opening envelope; box depth/height; resolved finished-stack side/front/back/bottom thickness; sourced system allowances; bottom support/offset rule; front reveal/overlay; front-to-box offset. Reject unresolved profile variables, negative internal dimensions, depth overflow, incompatible bottom placement and conflicting/duplicate physical fronts. Intentional shared_front_id references from multiple interiors are allowed and do not create another physical front. Insufficient runner data produces a diagnostic and blocks that drawer, not a guessed default.

## Materials and dimensional layers — corrected Phase1B design

VERIFIED C01–C03 contradict using purchased nominal thickness as geometric thickness. PROPOSED input contract: material.nominal_purchase_thickness_mm is procurement metadata; finished_substrate_thickness_mm controls substrate geometry; dimensional face layers have separate nominal/finished thickness and inclusion policy. Finished part thickness resolves before division reservations, fit, Geometry and drawings. An additive stack t_finished=t_substrate_finished+Σt_face_layer_finished is an INFERRED formalization where applicable, not a universal printed formula for every surface treatment.

Use thickness_policy=finished_stack or explicit_finished_override. Explicit override must state whether it replaces substrate thickness or total finished stack and be permitted by the characteristic; conflicting/ambiguous values fail validation. Decorative color/texture/reflectivity remain nongeometric. Distinguish physical surface layers from late visual face bindings; a physical finish-thickness change DOES invalidate geometry.

Early Material context resolves all dimension-affecting substrate/surface/band values and allowance policies against declared semantic segments. Geometry constructs substrate and finished envelopes; late Material binds visual finishes without resizing. The late stage cannot silently supply missing dimensional layers. Persist raw/substrate and finished extents separately and label BOM conventions (C23).

Per-contour band thickness and width/height differ. Finished/raw conversion and physical-layer BOM contributions are explicit policies; no blanket rule that every finish is nonphysical. Upper/lower face grain can differ from substrate. Visible/covered edge composition and semantic edge adjacency are recorded. Drawer edge3 mapping is component-specific. Texture image/scale/render wrapper remains separate; imported tutorial Scale has UNKNOWN units until mapped.


## Regeneration and error behavior

Build a candidate immutable snapshot; evaluate all constraints before host mutation. On error retain the last accepted snapshot and geometry. Perform accepted host changes as one operation. Stable semantic IDs map parts to entities; copied articles get new occurrence IDs. Manual edits inside managed geometry trigger an explicit conflict state; they never silently rewrite formulas. Part cancellation, undo, save/reopen and schema migration require dedicated runtime validation.
