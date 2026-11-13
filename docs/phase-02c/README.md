# Phase 2C: rectangular carcass construction preview

Implements a narrow B11/B12/B13 construction slice and the rectangular finished-envelope subset of B14. See [design22](../phase-01/22-rectangular-carcass-spec.md), [plan23](../phase-01/23-rectangular-carcass-implementation-plan.md) and [qualification](validation.md). It is pure Ruby; no host/SketchUp dependency or new gem.

```ruby
require_relative 'lib/jp_imos_pro/construction'
result = JPImosPro::Construction.build_carcass(
  document: project_document, request: carcass_request,
  numeric_policy: {
    policy_id: 'jp-rational-binary64-15-v1',
    backend_id: "#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"
  }, limits: {})
```

Input project remains closed jpimos.project-core/1. The separate request is jpimos.carcass-request/1, selects an article_instance_id and the single principle top_bottom_between_sides-v1, and has exactly four panel characteristics under panels.left/right/top/bottom. The full project is validated/resolved: a bad sibling article cannot be hidden by choosing another article.

Each characteristic explicitly supplies additive_finished_stack-v1, substrate material_ref{id,version}, nominal_purchase_thickness, finished_substrate_thickness and ordered dimensional_surfaces. Each surface supplies side near/far, pinned material_ref and finished_thickness. All thicknesses are exact positive Length DTOs; maximum16 surfaces. Nominal purchase thickness does not drive finished geometry. There is no finished-total override, texture-as-thickness inference, nominal fallback, material inheritance, grain or edge deduction in this version.

Material UUID/version shape is checked; catalog existence/compatibility is **not** verified. Contexts explicitly report caller_declared_unverified_catalog. This is meaningful geometry under declared inputs, not a sourced manufacturer/material-profile claim.

## Geometry and evidence

For W600/H720/D560 and18mm finished stacks: reference opening564x560x684; left/right finished envelopes560x720x18; top/bottom564x560x18. Finished-envelope volume totals25885440mm3. The reference depth is unreduced; no usable-depth claim or hidden back/front deduction.

Rules emit recipes. A separate converter builds versioned rectangular extruded SolidSpecs,8 article-local vertices,6 outward quad loops, bounds and exact finished-envelope volume. Recipe/part refs are stable article+role pairs. Root front/left view orientation does not rotate physical article axes; project translation is retained separately. Contact is allowed, pairwise interior overlap is rejected.

Nominal19, finished substrate18.5, near0.5 and far0.5 produces19.5mm finished stack under this explicit additive policy. The historical manuals support distinctions and construction families; exact policy/formulas/frames are original JP choices. Source conflicts remain open. No raw board volume, density/mass or cut dimensions are fabricated.

## Preview authority and resources

Success is a deeply frozen jpimos.carcass-preview/1 with construction_request, source_context, article_origin, reference_envelope/opening, panels and diagnostics[]. Source context binds project ID/revision, **canonical project document SHA256**, canonical request SHA256, selected article and rule version. Hash property order is irrelevant; authored changes alter the appropriate digest even if someone edits a document without preparing a new revision.

The preview is not an accepted furniture Snapshot or another live project store. Construction intent is not silently inserted into the current core schema. Future project/host integration must persist it and publish one accepted revision before BOM/export/persistence can rely on it. Review OBJ/JSON artifacts may be generated externally from a complete bound preview, but no production export API is added.

One CoreBudget covers document/request copies, material contexts, policy, full zone resolution, recipes, geometry/audit, hashing and freezing. Rational intermediates remain4096-bit bounded. Limits may tighten only. Any failure returns value=nil with no partial panels. Input/policy objects are not mutated/frozen. Context numerical errors carry a characteristic pointer; project errors are scoped /document and construction errors /request.

Run `ruby test/all_test.rb` on Ruby2.7/3.2. Existing core tests remain included. No backing/front/shelves, general contour holes, angled junctions, substrate/edge manufacturing geometry, catalog import, BOM, drawings, UI, native apply/undo, RBZ or machining module is implemented.

The later [revision-bound design state](../phase-02d/README.md) now owns construction intent alongside the core component. The standalone preview remains a component; accepted host/material/PartSpec readiness is still [blocked explicitly](../phase-02d/host-readiness.md).
