# Phase 2A: host-independent parametric engine

Authorized implementation of the first module specified in [Phase 1C](../phase-01/16-expression-division-spec.md). The 14 Phase 1B reports remain historical, unchanged records. This module does not resolve the construction conflicts in [the source register](../phase-01/15-source-conflicts.md).

## Run

From the repository root, with Ruby 2.7 or 3.2:

```sh
ruby test/test_engine.rb
```

Production code requires only Ruby's Rational/Integer/Math facilities and relative module files. Tests require Minitest (development only). No external evaluator, SketchUp API, loader, geometry, UI, RBZ, file access or network access is included in the engine. No cache is implemented.

## API

```ruby
require_relative 'lib/jp_imos_pro/parametric'
p = JPImosPro::Parametric
policy = {
  policy_id: 'jp-rational-binary64-15-v1',
  backend_id: "#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"
}
ast = p.parse_expression(source: '0.1+0.2', grammar_version: 'jp-core-v1')
result = p.evaluate_expression(ast: ast.fetch(:value), symbols: {},
  numeric_policy: policy)
# result[:value] => {type: 'Scalar', numeric: {
#   numerator: '3', denominator: '10', exact: true}}
```

All five public operations use keyword arguments; `limits: {}` is optional and may only tighten named defaults. Hash field names are Ruby symbols; symbol-table and definition names are case-sensitive ASCII strings. The caller must provide all other contract keywords. API misuse such as an omitted Ruby keyword is a Ruby argument error; malformed values supplied to contract fields return structured diagnostics.

Quantities use `type: 'Scalar'`, `type: 'Length'` (plus `unit: 'mm'`) or `type: 'Boolean'`. Ratios must already be normalized integer strings with positive denominator. Host Floats are rejected. Input strings must be valid UTF-8 or US-ASCII; other encodings return E_INPUT_CONTRACT. Diagnostic spans count Unicode code points, not UTF-16 editor offsets.

Expression success additionally returns `dependencies` (symbols actually read in selected branches) and `declared_dependencies` (all syntactic references, including branches not executed). All declarations are validated before arithmetic. Constant pi is excluded from symbol dependencies. Definition success returns `symbols`, lexical topological `order`, and a definition-to-definition static dependency graph. Failure returns no partial values.

AST envelopes and all child arrays/hashes/strings are frozen. Evaluation reparses the bounded source and compares the supplied tree; fabricated/version-mismatched ASTs are rejected. ASTs are Ruby data structures, not a JSON transport format; a future bridge must explicitly encode node-kind symbols.

For division, pass `grammar_version: 'jp-division-v1'`, a positive Length `reference[:length]`, Length `reference[:origin]`, integer direction 1 or -1 and explicit `context`. User variables use `$name`; X is injected from reference length, Y is an optional caller-supplied Length. Rebinding other reserved names, including built-in functions, fails. Each expanded term has t0..t(n-1), boundaries b0..bn. Internal points contain local positions; their corresponding mapped positions use the same IDs in `mapped_boundaries`.

Quantization supports only one weight-one/no-offset term, a positive literal quantum, and other fixed Length terms. It never rounds. Repetition expands one gap 1..1000 times; a repeated segment cannot also have a quantum suffix. Approximate values, including approximation carried through a conditional's condition, cannot participate in allocation. Unused approximate bindings are harmless.

## Qualification and limits

See [validation](validation.md) and [implementation ledger](implementation-ledger.md). Arithmetic acceptance is separate from future SketchUp host integration. These grammars are original JP subsets; historical n* auto-repeat, descriptors, powers, atan/athan, nested repeats and ambiguous 8/4mm remain unsupported. Use explicit (8/4)mm for a fixed 2mm value.

No source conflict is silently resolved: SC01–SC07/SC15 remain evidence limitations; caller-selected reference spans keep construction panel deductions outside the module. No later construction/drawing module is authorized by this implementation.
