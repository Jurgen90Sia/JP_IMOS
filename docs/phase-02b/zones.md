# Exact rectangular zone resolver

The second arithmetic unit implements `JPImosPro::ProjectCore.resolve_zones` from the approved [design18](../phase-01/18-project-zones-spec.md) and [execution plan20](../phase-01/20-zone-resolver-implementation-plan.md). The existing codec continues to validate authored structure; the resolver additionally evaluates dimensions, partitions and layer containment.

```ruby
require_relative 'lib/jp_imos_pro/project_core'
policy = {
  policy_id: 'jp-rational-binary64-15-v1',
  backend_id: "#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"
}
result = JPImosPro::ProjectCore.resolve_zones(
  document: project_document, numeric_policy: policy, limits: {})
```

Input remains a string-key `jpimos.project-core/1` authored record. It is validated/copied once under the request budget; caller data and policy strings are not frozen or mutated. Result keys are Ruby symbols, while the frozen snapshot and quantities have string keys. Failure has value=nil and structured diagnostics; no successful sibling or incomplete tree is published.

## Exact arithmetic and frames

Snapshot schema is `jpimos.zone-snapshot/1`, algorithm `jp-rectangular-zones-v1`, with project/revision and numeric policy/backend IDs. It is a derived **zone** snapshot, not a complete physical-furniture snapshot. It cannot be passed to encode_document as authored data.

The reference article box is W/D/H along X/Y/Z. Root plan basis is identity; front basis is (+X,+Z,-Y), origin(0,D,0); left_side basis is (+Y,+Z,+X). Named orientations are original JP signed-permutation conventions carried by the approved design, not verified vendor transforms. Child offsets/orientations compose exactly once. No arbitrary rotation, mirror, shear or Float transform is accepted.

Each zone records its structured occurrence ref, parent ref, pinned definition, local frame/extents, article frame, occupied slots and child refs. Article records retain project translation separately. Thus an article at(10,20,30) with a zone origin(300,0,0) has project origin(310,20,30); article_origin stays(300,0,0). Every numeric dimension/position is an exact normalized Length ratio in mm. All computed rational numerators/denominators remain bounded to4096 bits.

Article and child-link order is preserved for traversal; physical positions follow slot/placement IDs rather than child array indexes. Resize preserves unchanged authored identities. Instances sharing a definition have distinct occurrence refs.

## Partitions and layers

Partitions use the existing jp-division-v1 language with positive_intervals and explicit span/origin0/direction+1. In600mm, `1:18mm:1` with zone/reservation/zone roles creates291mm zones at0 and309, and an18mm spacing reservation. It does not create a panel, material or BOM item. `1:1` remains300/300. No hidden panel/back/groove/front deduction is added.

Actual expanded term count must equal authored slots; otherwise E_ZONE_TOPOLOGY_CHANGED prevents implicit remapping. Zero/negative physical intervals fail even though Phase2A still supports them in its separate reference_points context. Historical unsupported grammar remains unsupported.

Independent layers evaluate six endpoint expressions against the same unchanged parent. Require exact Lengths and 0<=start<end<=parent_extent, without epsilon/clipping. Coextensive layers are valid abstract spaces. Partitioning one layer never reduces the dimensions of another. The resolver does not validate physical-part collisions.

Bindings contain article parameters plus current oriented ZONE_U/ZONE_V/ZONE_W. Division X is selected-axis length; Y is not injected. Division user variables require `$`; layer expressions retain core-v1 rules. No descendant/sibling/host geometry lookup exists. Unknown references in unselected branches still fail; inexact results cannot become exact zone bounds.

## Limits, diagnostics and dependencies

One trusted request counter covers document validation, core traversal, exact frame operations and all engine parsing/type/evaluation/dependency/expansion work. Local engine caps remain active. No thread-local/global request state or user-supplied callback meter is used. Private Internal adapter misuse with a noncounter is rejected; it is not a UI/public expression extension point.

Core limits and numeric grammar are unchanged. Backend IDs must be nonempty valid UTF-8/US-ASCII strings and are charged to the request text-byte quota. Engine errors preserve code/grammar/span/symbol IDs, with an expression-field JSON Pointer and occurrence context. Spans index only the expression string. Independent failures are selected by lexical pointer, then article/zone IDs; failed-parent descendants are skipped. Exhaustion stops immediately with an atomic error.

Run the complete suite using `ruby test/all_test.rb`. Production uses Ruby stdlib and existing JP core only. See [qualification](zones-validation.md).

## Deferred scope

`prepare_revision`, accepted host transactions, persistence/undo, physical construction, materials, BOM, drawings, UI and RBZ remain unimplemented. Source conflicts SC01/SC04/SC08/SC15 remain unresolved; explicit authored spans keep them outside automatic construction decisions. No source PDF, figure, extracted manual, runtime binary or external expression implementation is vendored.
