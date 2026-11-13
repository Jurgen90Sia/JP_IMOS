# Project Core Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Native inline execution is the recommended continuation of the existing workflow, with one fresh-context whole-branch review at the end.

**Goal:** Implement only the first independently acceptable unit of the approved Phase 2B design: lossless project-core JSON encoding/decoding and validated authored article/zone records.

**Architecture:** A pure Ruby boundary decodes duplicate-aware JSON into closed, validated records and deeply freezes successful documents. A validator checks pinned definitions, parameter bindings and zone-tree structure without allocating zone dimensions. Existing Phase 2A quantity semantics are reused through one internal adapter.

**Tech Stack:** Ruby 2.7-compatible syntax, Ruby stdlib JSON, existing JPImosPro::Parametric, Minitest for development tests; no runtime gems or SketchUp APIs.

**Spec:** [18-project-zones-spec.md](18-project-zones-spec.md), approved by the user on 13 November 2026. This plan implements its project-core subset, not the zone resolver or host integration.

## Global Constraints

- Preserve all 14 historical Phase 1 reports, the merged Phase 2A behavior, and unrelated work.
- Work in C:/Users/arkitekt2/Documents/JPMOS on a dedicated implementation branch based on the approved design commit. Do not implement on main.
- Serialized schema is jpimos.project-core/1, locale sq/en, canonical units mm.
- Numeric quantities use Phase 2A normalized ratio strings and exact flags; no Float conversion or 0.001mm rounding.
- JSON field keys are strings. Symbol-table/definition names are case-sensitive ASCII. Internal symbol-key Phase 2A DTOs cross one explicit adapter.
- Closed record fields: never drop or relabel unknown data. No automatic historical/full-project migration.
- JSON byte cap1,048,576; JSON nesting64; definitions100; articles100; zones per definition1000; resolved-occurrence upper bound10,000; zone depth32; parameters256; labels256 code points; request work100,000. Tighten only.
- Reserved parameter names include all Phase 2A reserved names plus ZONE_U, ZONE_V, ZONE_W. W/H/D are required positive exact Length inputs, not reserved aliases.
- No eval, source execution, host/file/network/environment access in the core; no production dependency installation, geometry, RBZ, materials, BOM, drawing or machining features.
- Entire affected suite must pass on real Ruby2.7 and3.2, capturing versions. A Python arithmetic check or host stub cannot satisfy this gate.
- No production code starts until the user has reviewed this execution plan, as required by the writing-plans workflow.

## Scope ruling and review focus

Spec section2 mentions prepared revisions within project-core, but section8 requires a matching resolved ZoneSnapshot and section11 schedules revision logic after the resolver. Implementing it before zones would publish an incomplete or fabricated snapshot. **Ruling:** this first unit exposes decode_document and encode_document only; prepare_revision and resolve_zones are deferred together to the second unit. No stub implementation, placeholder success, schema field or accepted revision is introduced. All authored fields needed by that second unit are validated and retained now.

Five easily missed input classes and owning tests:

1. Duplicate keys containing JSON escapes (revision versus revi\u0073ion): decoded key identity must detect the duplicate; Task1.
2. Imported Ruby Hash cycles/shared subobjects passed to encode: return a bounded contract error for cycles, preserve valid shared values without caller mutation; Task2.
3. Reused zone IDs in two instances of one definition: accept distinct occurrences; duplicate zone IDs inside one definition fail; Task4.
4. Optional absent value versus supplied zero/false: use a default only for absence and retain authoring shape; Task3.
5. A long acyclic tree and many reused definitions: enforce depth/product/request quotas before expansion and avoid native recursion; Task4.

## File responsibilities and interfaces

Create:

- lib/jp_imos_pro/project_core.rb — public decode_document/encode_document and Result boundary.
- lib/jp_imos_pro/project_core/diagnostics.rb — Fault carrying code/json_pointer/entity_ref and optional wrapped Phase 2A fields.
- lib/jp_imos_pro/project_core/budget.rb — trusted CoreBudget, tightening and work accounting.
- lib/jp_imos_pro/project_core/codec.rb — duplicate-aware bounded parse and deterministic JSON writer.
- lib/jp_imos_pro/project_core/document.rb — iterative validation/freezing/canonical field order.
- lib/jp_imos_pro/project_core/quantities.rb — explicit string-key DTO to Phase 2A adapter; no duplicate arithmetic implementation.
- lib/jp_imos_pro/project_core/parameters.rb — required declarations/defaults/bindings.
- lib/jp_imos_pro/project_core/references.rb — IDs/version pins/zone links and topology.
- test/project_core/fixtures.rb — one complete valid authored fixture and quantity factory; no mocks of validators/parser.
- test/project_core/{codec,document,parameters,references}_test.rb — behavioral tests.
- test/all_test.rb — deterministic discovery of existing engine test and project-core tests.
- docs/phase-02b/README.md and validation.md — implemented subset/API/qualification and deferred operations.

Modify README.md to link the implemented subset. Do not modify historical reports01–14. Make any necessary specification clarification additive in the new validation document.

Public signatures:

```ruby
JPImosPro::ProjectCore.decode_document(source:, limits: {}) # Result<Hash>
JPImosPro::ProjectCore.encode_document(document:, limits: {}) # Result<String>
```

Successful decode value is an immutable string-key Hash matching the authored schema. Successful encode returns canonical UTF-8 JSON. Result={ok,value,diagnostics,metadata}; metadata contains schema and profile_version, not invented numeric-policy/backend qualification. On failure value=nil. Pure codec validation does not evaluate expressions or need a transcendental backend.

Diagnostic={code,severity:'error',json_pointer,entity_ref,message_key,details}; wrapped quantity failure additionally preserves its numeric diagnostic code/input path without a fabricated expression span. Json_pointer uses RFC6901 escaping (~ -> ~0, / -> ~1). No stack trace/source dump in responses.

Internal interfaces (all use the same trusted budget): Codec.parse(source,budget)->raw JSON records; Document.validate(raw,budget)->validated immutable copy; Codec.encode(validated,budget)->UTF-8 String. Parameters.validate_definition(definition,pointer,budget) and Parameters.bind(instance,definition,pointer,budget)->validated effective bindings. References.validate(document,budget)->pinned definition index and validated topology metadata. These are internal, not serialized schema fields or public APIs.

Codec duplicate-aware object nodes retain decoded key/value pairs until duplicate validation completes; they must not overwrite duplicates in a Hash. Use stdlib JSON's object_class hook only after a real Ruby2.7/3.2 characterization proves escaped-key behavior and max_nesting. JSON standard grammar rejects nonfinite tokens. If the hook cannot supply pair retention, stop with a documented blocker rather than using a plain overwriting parse. Build JSON Pointers from the retained object/array tree. Pre-limit bytes and parser nesting before untrusted recursive materialization.

Canonical encoding follows the field order in spec section4; typed quantities order type/unit(if Length)/numeric, numeric order numerator/denominator/exact, definition_ref order id/version, core expression order grammar_version/source/expected_type, division expression order grammar_version/source, layer axes u/v/w. Parameter-value map keys sort ASCII, authored arrays retain order. JSON strings retain Unicode; JSON escaping may be normalized but semantic text must survive. Do not use source-string comparison for equality of documents.

### Task 1: Duplicate-aware JSON boundary

**Files:** project_core.rb (namespace/loads only), diagnostics.rb, budget.rb, codec.rb; test/project_core/codec_test.rb and fixtures.rb.

**Consumes:** spec sections3/5/9, Ruby stdlib JSON; no zone engine.
**Produces:** bounded internal raw parser and structured Fault values. Public decode/encode operations are added in Task2 only when they can return fully validated records; no partial-success public stub.

- [ ] Write focused tests for duplicate root keys, nested keys, escaped duplicate names, malformed JSON, NaN/Infinity, invalid UTF-8 and over1MiB source. Use raw literal JSON for duplicate cases, not JSON.generate on a Hash.

```ruby
fault = assert_raises(JPImosPro::ProjectCore::Fault) do
  JPImosPro::ProjectCore::Codec.parse(
    '{"revision":1,"revi\\u0073ion":2}', JPImosPro::ProjectCore::CoreBudget.new({}))
end
assert_equal 'E_DUPLICATE_JSON_KEY', fault.code
assert_equal '/revision', fault.json_pointer
```

- [ ] Run `ruby -Itest test/project_core/codec_test.rb`; observe relevant failing behavior before implementation.
- [ ] Characterize stdlib pair-retaining object_class and max_nesting on both runtimes in test code. Implement Codec.parse and CoreBudget defaults/tightening. Invalid JSON uses E_INPUT_CONTRACT; duplicate keys use E_DUPLICATE_JSON_KEY. Faults are converted to public Result diagnostics by Task2.
- [ ] Add boundary tests: exactly1MiB validly padded minimal JSON parses internally; one byte beyond fails E_RESOURCE_LIMIT; depth64 accepted by parser,65 fails; tightened cap enforced and enlarged/unknown caps rejected. At this step raw parser success makes no schema-validity claim.
- [ ] Run focused tests on both runtimes; commit `feat: add bounded duplicate-aware project JSON parsing` only after green.

### Task 2: Closed records, exact quantities and immutable codec

**Files:** document.rb, quantities.rb, codec.rb; test/project_core/document_test.rb and fixtures.rb.

**Consumes:** Codec.parse and CoreBudget from Task1; Phase 2A DTO validation.
**Produces:** validated/deeply frozen ProjectCoreDocument and both public decode_document/encode_document operations.

- [ ] Build a complete valid fixture: project UUID00000000-0000-0000-0000-000000000001; definition ...0002 version1; root-zone ...0003 leaf/plan; article ...0004; locale sq, units mm, revision7. Declare W/H/D required Length/null defaults; supply W=600,H=720,D=560 exact mm; origin three exact zeros; source_refs empty. No test is allowed to pass merely because the fixture lacks a required field.
- [ ] Write PC01–PC03 tests: unknown property pointer, unsupported schema, all field types/required fields, malformed/unnormalized ratios, denominator0, Float dimensions, revision range, preserved ë/ç label, and width3/10 round-trip. Verify encoded output decodes to the same semantic document and canonical bytes are independent of Hash insertion order.

```ruby
document = valid_document
document['articles'][0]['parameter_values']['W'] = length(3, 10)
encoded = core.encode_document(document: document)
assert encoded[:ok], encoded[:diagnostics].inspect
decoded = core.decode_document(source: encoded[:value])
assert_equal '3', decoded[:value]['articles'][0]['parameter_values']['W']['numeric']['numerator']
assert_equal '10', decoded[:value]['articles'][0]['parameter_values']['W']['numeric']['denominator']
assert decoded[:value]['articles'][0]['parameter_values'].frozen?
```

- [ ] Observe failures, then implement closed field/type validation for every section4 record, using an explicit field-order registry. A SourceRef with VERIFIED classification requires PDF and positive page; PROPOSED/UNKNOWN null/null is valid. Labels valid UTF-8/max256 code points. UUID syntax canonical lowercase.
- [ ] Quantities adapter constructs fresh Phase 2A symbol-key DTOs and a trusted Parametric::Budget with tightened numeric cap; reuse Value.deserialize, wrap its Fault, debit core work for each quantity. This is a documented internal coupling pinned to the merged Phase2A API, not a new external evaluator. No geometry arithmetic occurs.
- [ ] Add encoder cycle/shared-object tests, unknown symbolic/string mixed keys, malformed encoding in numeric strings, rejection of executable/unknown fields, and unchanged caller object assertions. Deep-freeze the validated copy; never freeze the caller's original input.
- [ ] Run Task1/2 tests and engine suite on both runtimes; commit `feat: validate and round-trip immutable project core records`.

### Task 3: Required parameters, defaults and pinned inputs

**Files:** parameters.rb; test/project_core/parameters_test.rb.

**Consumes:** closed ArticleDefinition/ArticleInstance records and quantity adapter.
**Produces:** deterministic typed parameter bindings for reference validation and future zone resolver.

- [ ] Write PC06/PC07 tests for W/H/D declarations and positive exact inputs; missing required input; undeclared override; duplicate/reserved parameter names; Angle rejection; supplied false and zero versus missing optional value; default type mismatch; required with nonnull default invalid.

```ruby
doc = valid_document
doc['definitions'][0]['parameters'] << {
  'name'=>'a', 'expected_type'=>'Scalar', 'default_value'=>scalar(0), 'required'=>false
}
assert core.encode_document(document: doc)[:ok]
doc['articles'][0]['parameter_values']['a'] = scalar(0)
assert core.encode_document(document: doc)[:ok]
doc['articles'][0]['parameter_values'].delete('W')
assert_equal 'E_PARAMETER_REQUIRED', core.encode_document(document: doc)[:diagnostics].first[:code]
```

- [ ] Observe failures. Implement Parameters.validate_definition and bind, with the same reserved name policy plus ZONE_U/V/W. Match exact types with no name-based conversion. All supplied numeric geometry candidates are exact for this first unit; approximate optional inputs are rejected until the resolver can prove they do not participate, an explicit conservative subset limitation documented in validation.md.
- [ ] Preserve authored absence: an optional default is used in effective internal bindings but encode/decode must not inject an instance override. Add assertion that the parameter_values map stays unchanged by binding.
- [ ] Run focused and affected full suites on2.7/3.2; commit `feat: validate article parameter declarations and bindings`.

### Task 4: Definition links and bounded rooted zone trees

**Files:** references.rb, document.rb; test/project_core/references_test.rb.

**Consumes:** validated records, Parameters.bind, trusted request budget.
**Produces:** structural integrity and pinned definition lookup; no dimensional ZoneSnapshot.

- [ ] Write PC04/PC05/Z11/Q01 structural tests: two instances share a definition, missing version, duplicate definition pair, different versions coexist, duplicate instance/zone/slot IDs, missing root, missing child/slot, shared child, self-cycle/cycle, orphan, slot role/link mismatch, leaf with children, wrong-parent slot, empty layer placements allowed only with no children.
- [ ] Add long-chain depth32/33, definition/article/zone/parameter caps, 10,000 occurrence boundary and over-limit product tests. Count actual occurrences using each instance's pinned definition; do not multiply all unused definitions by all instances. Check quota before creating a resolved occurrence list; no list is needed in this unit.
- [ ] Observe failing tests. Implement staged iterative validation with deterministic first error by stage then lexical JSON Pointer. Tree depth is root=1; 32 levels valid,33 fails. Report cycle before unreachable within the topology stage; missing links and multiple parents precede cycle analysis.
- [ ] Validate layout structure only: expression grammar ID/source/expected type fields, u/v/w axes, six layer endpoints as ExpressionSpec, slot counts bounded. Do not evaluate endpoint containment or compare expanded grammar term count yet; those need the next unit. This limitation must be visible in public docs: structural validity is not geometric validity.
- [ ] Run all suites on both runtimes; commit `feat: validate pinned definitions and zone topology`.

### Task 5: Public qualification and reviewable delivery

**Files:** test/all_test.rb, docs/phase-02b/README.md, validation.md, README.md; minimal fixes in affected code only.

**Consumes:** completed codec/document/parameters/references APIs.
**Produces:** independently acceptable project-core contract module and exact evidence report.

- [ ] Add deterministic test runner requiring sorted `*_test.rb` files plus existing test/test_engine.rb; avoid double-loading. Run `ruby test/all_test.rb` on real Ruby2.7.8 and3.2.9; capture versions, actual test/assertion counts and zero failures/errors/skips.
- [ ] Verify full PC01–PC07 and structural Z11/Q01 cases; explicitly list PC08, Q02 and numeric Z01–Z15 as deferred to resolver/prepared-revision unit. No placeholder passing test may claim these are implemented.
- [ ] Fresh-context whole-branch reviewer checks contracts, encoded duplicate keys, hostile Ruby objects, resource limits, immutability, parameter presence, topology and dependency boundaries. Fix critical/important findings with observed red/green regressions, then rerun both suites.
- [ ] Verify git diff/check, unchanged historical14 and existing engine behavior, and no proprietary manuals/generated runtime assets/credentials/RBZ. Record exact scope and any remaining limits honestly.
- [ ] Commit `test: qualify lossless project core contracts on supported Ruby versions`; prepare a PR under the established integration workflow. Do not merge without integration authorization.

## Self-review and handoff

Coverage: design sections3–5 and authored-record portions of4/9 are implemented by Tasks1–4; section8 encode/decode by1–2; PC01–PC07 by1–4. Zone arithmetic, frame transforms, prepared revisions, engine shared-step adapter and complete ZoneSnapshot remain a separate unit as required by the approved staged design. No operation in this unit can claim geometry/host acceptance.

Plan clarifications needing review: root depth starts at1; empty independent layers permitted as an empty authored container; approximate optional numeric values conservatively rejected before usage analysis exists; revision preparation deferred until it can attach a real matching ZoneSnapshot. These avoid guessed behavior or a fake partial success.

The user has approved the design. This execution plan is now ready for review. Recommended method: native inline execution with TDD and one final fresh-context review, matching Phase2A's workflow. After plan confirmation, execute continuously through Task5; do not ask for approval between reversible implementation slices.
