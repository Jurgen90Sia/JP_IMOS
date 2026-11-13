# Prepared project revisions

Implements `prepare_revision` from approved design18 section8 and [execution plan21](../phase-01/21-prepared-revisions-implementation-plan.md), after project-core contracts and exact zone resolution.

```ruby
require_relative 'lib/jp_imos_pro/project_core'
result = JPImosPro::ProjectCore.prepare_revision(
  current: current_document,
  replacement: edited_authored_document,
  expected_revision: current_document.fetch('revision'),
  numeric_policy: {
    policy_id: 'jp-rational-binary64-15-v1',
    backend_id: "#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"
  },
  limits: {})
```

Result keys remain Ruby symbols. On success value is a frozen string-key PreparedProjectRevision with project_id, base_revision, next_revision, document and zone_snapshot. At current revision7, a valid change yields next_revision8, document.revision8 and zone_snapshot.source_revision8, with matching project IDs. All nested document/snapshot arrays, keys and values are immutable. Caller inputs and policy are copied, not mutated or newly frozen.

## Guards and ordering

1. Validate/copy current, validate expected_revision as exact Integer0..9007199254740991, compare it with current.revision, reject exhausted maximum.
2. Validate/copy replacement; require unchanged project_id and current revision. Callers cannot supply their own revision jump.
3. Enforce immutable definition content for overlapping(id,version) pairs. A changed definition must use a new version and valid instance pin. This is pair-local checking, not a global definition registry.
4. Compare normalized authored records under the same budget. Hash key order is insignificant; authored array order, explicit input presence, labels/locale/origin and definition pins are semantic. No change returns E_NO_CHANGE.
5. Validate the existing numeric policy, create an owned candidate root at revision+1, resolve its zones under the same request counter, and return the complete frozen pair only after success.

Current is structurally validated rather than re-resolved: this operation may prepare a repair of unresolved authored input. Replacement must resolve completely. A stale/max/no-op decision is made before zone arithmetic or policy-dependent work. A locale-only edit is meaningful; supplying a previously absent optional input, even equal to its default, preserves authored intent and is meaningful.

Failure returns value=nil with no partial candidate/snapshot. Pointers from document validation are scoped /current or /replacement; candidate-expression failures retain their source span, grammar, symbol IDs and occurrence context under /replacement. Numeric-policy diagnostics remain /numeric_policy. Failed calls leave both source revisions unchanged and do not affect a fresh request.

## Resources and acceptance boundary

One CoreBudget covers both input copies/validations, version checks, iterative semantic comparison, metadata and zone resolution. Existing work/text/numeric/depth/occurrence limits remain active. Two documents that fit individually may exceed a combined request quota. Comparison charges nodes and scheduled pairs rather than hiding an entire document comparison behind one counter tick.

**Prepared is not Accepted.** No host/file/network write, transaction lock or global revision sequence exists in this pure API. Repeating the same preparation against current7 returns the same next8; it does not silently publish8 or make a second call9. A future host/session acceptance layer must atomically compare the base revision and publish canonical data plus host geometry together.

There is no SketchUp geometry, persistence/undo observer, UI, materials/BOM/drawings or RBZ. No source conflict is resolved by this state contract. Original source manuals/figures/runtime binaries remain outside the repository.

Run `ruby test/all_test.rb`. See [qualification](revisions-validation.md). Production adds no new dependency; it reuses the validated project records, policy guards and exact resolver.
