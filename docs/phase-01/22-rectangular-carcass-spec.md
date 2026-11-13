# Rectangular carcass preview: construction and finished stack

Date:13 November2026. Original JP design selected under the user's instruction to continue without approval questions. It refines reports04/09 and backlog B11/B12/B13; rectangular extrusion is a restricted first portion of B14, not the general contour/holes solver.

## Approach / evidence

Use a pure construction dispatcher and explicit material-context resolver to emit four rectangular panel recipes; a separate geometric converter derives their exact finished envelopes. Defer the alternatives of host-measured geometry and a general angled-junction/material-inheritance solver: their interfaces and source cases are broader than the next independently testable slice.

Historical concepts are inherited from the completed audit: Manual Menaxhimi i Elementeve.pdf pp.11,15,18,21 distinguishes nominal/finished and dimensional surface layers; pp.65–69 documents construction-mode families. Exact additive stack, coordinates, JSON records and this selected butt-joint rule are **PROPOSED JP policies**, not universal imos formulas. Reports04 and12 give the original W600/H720/D560,18mm fixture with clear564/684. No PDF is newly re-extracted here. SC01/SC08/SC16 remain unresolved outside explicitly selected policies.

## Scope and public boundary

`JPImosPro::Construction.build_carcass(document:,request:,numeric_policy:,limits:{}) -> Result<CarcassPreview>`.

Validate the full authored project, a closed request, and policy under one CoreBudget; run the existing full zone resolver; select the requested article's reference extents(W,D,H in article X/Y/Z), not its oriented root view dimensions. A sibling article's invalid zone math fails the whole request. No global settings, callbacks, implicit fallback or live host measurement.

Request string-key fields: schema=`jpimos.carcass-request/1`; article_instance_id (canonical UUID); principle=`top_bottom_between_sides-v1`; panels map with exactly left/right/top/bottom. Each panel supplies one Characteristic:

- policy=`additive_finished_stack-v1`;
- material_ref={id:UUID,version:positive safe integer};
- nominal_purchase_thickness:exact positive Length;
- finished_substrate_thickness:exact positive Length;
- dimensional_surfaces:ordered array(max16) of{side:near/far,material_ref,finished_thickness:exact positive Length}.

All required fields are explicit. Thickness inputs use existing normalized ratio DTOs. No total-thickness override, edge deductions, decorative texture layer or other policy is accepted in this version. Unknown fields fail; no nominal->finished fallback. Caller material references are shape/pin validated, **not verified against a catalog**. Context reports that limitation explicitly.

Finished stack T=finished_substrate+sum(all dimensional surface thicknesses). Nominal purchase thickness does not enter this equation. Surface order is retained; near/far sums are separate, but individual layer placement/finish/BOM is not generated. Zero/negative/inexact thickness fails. Each rational intermediate remains <=4096 numerator/denominator bits; all work/text/field quotas share the request budget.

## Rule and coordinates

L/R/T/B are the four finished stack thicknesses. Cw=W-L-R; Ch=H-T-B, both strictly positive. The reference opening has origin(L,0,B), extents(Cw,D,Ch). D is unreduced reference depth, not a claim of usable storage depth: backs/fronts are absent.

| Role | Origin in article | Basis columns(u,v,n) | Face size / finished thickness |
|---|---|---|---|
| left | (0,0,0) | (+Y,+Z,+X) | D,H / L |
| right | (W,D,0) | (-Y,+Z,-X) | D,H / R |
| top | (L,D,H) | (+X,-Y,-Z) | Cw,D / T |
| bottom | (L,0,0) | (+X,+Y,+Z) | Cw,D / B |

All bases have determinant+1, dimensions are positive, and the construction occupies the reference carcass envelope exactly. Root plan/front/left_side is a view convention and does not rotate these physical article axes. Article project translation is stored separately; no double transform. Six pairwise part-envelope interior intersections must be zero; touching interfaces are allowed. No back, shelf, front, corner/miter rule or machinery field is created.

Rules emit recipes only. Geometry converts each recipe to a finished-envelope SolidSpec of kind extruded_contour, CCW rectangle(0,0),(U,0),(U,V),(0,V), holes=[], positive thickness, and the declared right-handed frame. Derived vertices are the8 combinations of u/v/n bounds; outward face loops are n_min[0,3,2,1],n_max[4,5,6,7],v_min[0,1,5,4],u_max[1,2,6,5],v_max[2,3,7,6],u_min[3,0,4,7]. They are derived data, not another mutable geometry authority. Volume=U*V*T in exact mm3, explicitly labeled finished-envelope volume, not raw board volume or mass.

## Preview/identity contract

Success is a deeply frozen string-key `jpimos.carcass-preview/1`: source_context{project_id,project_revision,project_document_sha256,article_instance_id,request_sha256,rule_version}, construction_request, article_origin, reference_envelope, reference_opening, panels, diagnostics[]. Each panel has occurrence_ref{article_instance_id,role}, owner_zone_ref(the article root), role, characteristic context, face_size, finished_thickness, frame and derived geometry. Order left/right/top/bottom is fixed. IDs survive dimension changes for the same role/occurrence; source context changes with the inputs.

The construction request is a separate versioned command payload until the full project model owns construction definitions. It is **not** silently inserted into closed project-core/1 or accepted as another live project store. Canonical normalized project and request SHA256 plus project revision bind this preview completely; a request change at the same project revision cannot masquerade as the same preview context. This is not a full accepted furniture Snapshot and is not eligible for BOM/export/host persistence on project revision alone. Later model/acceptance integration must persist construction intent and publish it in one project revision.

Geometry fields: solid_spec, article_vertices, face_loops(with semantic keys above), bbox_min, bbox_max, finished_envelope_volume={unit:mm3,numeric:{numerator,denominator,exact:true}}. Volume does not reuse Scalar as a disguised dimensional type. Characteristic context retains explicit inputs, near/far sums and finished_stack_thickness, with material_reference_status=caller_declared_unverified_catalog. No substrate cutting geometry is fabricated from finished envelopes.

Failure Result.value=nil, structured Core Fault codes/pointers. New codes E_CONSTRUCTION_UNSUPPORTED and E_INFEASIBLE_CONSTRUCTION; geometry defects use E_INVALID_GEOMETRY. Existing type/unit/inexact/resource/unknown-reference errors stay unchanged. Pointers /document or /request identify authored data; selected project-zone errors preserve spans/context under /document. No partial panels are returned.

## Independent acceptance / limits

CC01:600/720/560 and four18mm stacks -> top/bottom564x560x18, opening564x560x684,4 panels, aggregate finished-envelope volume25885440mm3, all8 vertices of every panel inside envelope, no interior intersection.
CC02:L18,R20,T16,B22 -> Cw562,Ch682; right xmin580,top zmin704,bottom zmax22.
CC03:nominal19,finished substrate18.5,near0.5,far0.5 -> stack19.5; nominal does not replace finished. No layers ->18.5. Duplicate total override or unsupported policy fails.
CC04:zero/negative/inexact thickness, W<=L+R,H<=T+B, unknown article/principle/material shape, unknown fields ->atomic errors.
CC05:article translation and root front view preserve article-local panel geometry; reused definitions have distinct occurrence refs.
CC06:request property order changes hash unchanged; thickness/material/context change hash changes. Inputs unmodified, nested outputs frozen, fresh recovery after a failure.
CC07:asymmetric/fractional dimensions, orientation winding and numeric overflow verified independently. The general B14 hole fixture remains unsupported, not falsely marked passed.

Use existing CoreBudget text1MiB/work100000, record limits, exact4096-bit rationals and engine per-call caps. Layer16 is a new hard characteristic quota; callers cannot override it. No new runtime gem: stdlib Digest/JSON only. Production remains Ruby2.7-compatible; qualify with real Ruby2.7/3.2 and rerun all58 baseline tests. Preserve historical14, no proprietary source assets, no SketchUp/RBZ or downstream features.
