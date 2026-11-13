# Phase 2B, unit 1: project-core contract

Implements the approved [project/zone design](../phase-01/18-project-zones-spec.md) and [first-unit plan](../phase-01/19-project-core-implementation-plan.md). Only authored document encoding, validation, parameter presence and structural zone relationships are implemented here. Successful validation is **not geometric validity**.

From repository root:

```sh
ruby test/all_test.rb
```

Production dependencies are Ruby stdlib JSON and the existing Phase 2A quantity validator. Minitest is development-only. The module targets Ruby 2.7 and 3.2 without a SketchUp runtime. No external evaluator or native gem is required.

## API

```ruby
require_relative 'lib/jp_imos_pro/project_core'
core = JPImosPro::ProjectCore
decoded = core.decode_document(source: json_text, limits: {})
if decoded[:ok]
  canonical_json = core.encode_document(document: decoded[:value])
end
```

Both operations return `{ok:, value:, diagnostics:, metadata:}`. Failed operations have value=nil. Decode success is a deeply frozen string-key Hash, including nested arrays, keys and strings. Encode success is canonical UTF-8 JSON. Caller-owned objects are copied and are not frozen or modified. Ruby missing keywords are API misuse and raise normal ArgumentError; malformed supplied data yields structured diagnostics.

Schema is `jpimos.project-core/1`; locale sq/en, units mm, schema/profile metadata explicit. The component belongs to the future full project model, not a second live project store. Historical `jpimos.project/1` and unknown newer schemas fail explicitly; unknown fields are never discarded.

Numbers used for dimensions are normalized ratio strings in Phase 2A DTOs. A Length contains type=Length, unit=mm and numeric={numerator,denominator,exact}; Scalar omits unit; Boolean contains value. Host Floats, NaN/Infinity, malformed ratios and unsupported encodings are rejected. Numeric JSON fields (revision/version/page) are bounded safe integers; quoted ratios are never routed through Float. Before JSON parsing, unquoted runs over16 decimal digits are rejected because no valid unquoted integer field can contain them; quoted ratio strings are unaffected.

Duplicate JSON keys are detected after escape decoding using retained key/value pairs. A duplicate cannot silently replace a prior value. Diagnostics use escaped RFC6901 pointers. Field errors are selected by lexical pointer, with staged identity/link/topology/parameter checks. Within topology, all multiple-parent checks precede all cycle checks, which precede rooted reachability/depth checks. Resource exhaustion takes priority when continuing validation would exceed its quota.

Definition references pin id+version. Zone IDs are scoped to a definition version; instance IDs distinguish occurrences of reused definitions. Rooted zone trees require unique IDs, one parent, valid own slots/roles, no cycles or orphans, and depth at most32 (root=1). Independent layers may be empty containers. Structural validation preserves their authored bounds without evaluating them.

W/H/D must be required exact positive Length parameters with null defaults. Other parameters declare Length/Scalar/Boolean. Angle is unsupported. Unknown overrides and reserved names fail. Optional typed defaults apply only when input is absent; explicit0/false remains present. Effective binding does not inject a new authored override. For this first unit, all numeric input/default/origin values must be exact: approximate optional values are conservatively rejected before usage analysis is available.

## Limits and ownership

Defaults, tighten only: json_bytes1,048,576; json_depth64; definitions100; articles100; zones1000 per definition; occurrences10,000; zone_depth32; parameters256; label_chars256; work100,000. Limits are Ruby symbol-key Hash entries. Invalid/unknown/enlarged limits return E_INPUT_CONTRACT. Byte size, cumulative copied text, parser nesting, child scheduling and traversal budgets are checked; no expanded zone occurrence array is created by validation.

The occurrence upper bound sums zone counts only for each article's pinned definition. An unused definition does not multiply all other instance counts. Quotas apply to metadata too; no field creates a way to import unbounded source bytes.

Quantity conversion reuses `Parametric::Value.deserialize` behind one adapter; this internal dependency is pinned to current Phase2A behavior and covered by the full engine suite. No engine arithmetic/grammar behavior was changed.

## Deferred

The subsequent [exact zone resolver](zones.md) now exposes `resolve_zones`, with named frames, partitions, layers, containment and shared work accounting. This first-unit codec still validates authored structure only; expressions/bounds can fail resolution. The [prepared-revision API](revisions.md) now pairs a validated next document with its matching zone snapshot atomically. No accepted host state is implied.

There are no physical panels, thickness deductions, materials/BOM/drawings, SketchUp integration, persistence hooks, UI or RBZ. Source conflicts remain unchanged. No proprietary source manuals, figures, runtime binaries or credentials are included. Distribution licensing remains undecided.

A later [rectangular carcass preview](../phase-02c/README.md) adds finished-envelope panel recipes outside this authored project-core schema. It does not turn structural document validity into accepted construction or a verified catalog/BOM model.
