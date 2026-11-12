# Parametric Expression and Linear Division Engine: first-module specification

Date:12 November 2026. Version:proposal1. Status:ready for design review;**implementation not authorized**. This document is additive to preserved Phase 1B reports03/08/09/10 and narrows report12's broader backlog. It is an original JP specification, not a claim of complete imos parser compatibility.

## Goal and strict scope

Specify one host-independent Ruby 2.7-compatible module that evaluates typed arithmetic/Boolean expressions, orders declared variable dependencies, and allocates one-dimensional fixed/proportional/affine divisions with explicit reference-point semantics.

No SketchUp/UI calls, geometry generation, panel deduction, drawer profile selection, materials, BOM, drawing, layout or PDF implementation is included. No plugin loader, RBZ, drilling, CNC, CAM, nesting, toolpath or postprocessor is created. No runtime package installation or external expression engine is required.

Two grammar IDs are explicit:
- **jp-core-v1**: original typed engineering expression subset.
- **jp-division-v1**: original affine division grammar containing the demonstrated fixed/weighted families and bounded fixed repetition.
Neither is named imos-compatible. Unsupported historical syntax returns a typed diagnostic rather than an invented interpretation.

Sources:Manual Ndarja Lineare.pdf pp. 5–12; Manual Menaxhimi i Elementeve.pdf pp. 30–33; Manual per krijimin e dyerve.pdf pp. 2–5. Source conflicts SC01–SC07/SC15 are listed in [15](15-source-conflicts.md).

## Input and output contracts

Planned namespace:JPImosPro::Parametric. These are interface declarations, not implemented Ruby methods.

| Operation | Planned contract | Observable result |
|---|---|---|
| parse_expression |parse_expression(source:String, grammar_version:String, limits:Limits) → Result<ExpressionAST>| Syntactically validated immutable AST with node/source spans; no environment lookup or execution |
| evaluate_expression |evaluate_expression(ast:ExpressionAST, symbols:SymbolTable, numeric_policy:NumericPolicy, limits:Limits) → Result<TypedValue>| One typed value and dependencies used; lazy branches do not execute |
| evaluate_definitions |evaluate_definitions(definitions:DefinitionMap, inputs:SymbolTable, numeric_policy:NumericPolicy, limits:Limits) → Result<EvaluatedSymbols>| Deterministic topological results or diagnostics; no partial published environment |
| parse_division |parse_division(source:String, grammar_version:String, limits:Limits) → Result<DivisionAST>| Immutable bounded division AST; unsupported source families identified |
| allocate_division |allocate_division(ast:DivisionAST, reference:Reference1D, symbols:SymbolTable, context:Context, numeric_policy:NumericPolicy, limits:Limits) → Result<DivisionResult>| Exact interval/point result or error; no host side effect |

Result is either {ok:true, value, diagnostics:[], metadata: {policy_id, backend_id}} or{ok:false, value:null, diagnostics:[Diagnostic,...], metadata: {policy_id, backend_id}}. Pure parse operations usegrammar-version metadata and null numeric-policy fields. A failed operation produces no valid partial geometry/output. ASTs received externally are not trusted:only engine-produced/version-validated node kinds may be evaluated.

TypedValue:
- Scalar{numeric:NumericValue}
- Length{numeric:NumericValue, unit:const mm}
- Boolean{value:true/false}

NumericValue is serialized as{numerator:string, denominator:string, exact:boolean}. Malformed quantity objects, unknown type tags, noninteger ratio strings orzero denominator return E_INPUT_CONTRACT withinput_path and null source_span. Denominator is positive and ratio normalized; integers are strings to avoid JS integer precision loss. Finite decimal source literals convert exactly to rational values; never route decimal literals through Float. Numerator/denominator bit limits apply during every operation. An approximate transcendental result has exact:false and the same bounded rational representation of its finite decimal approximation.

SymbolTable maps case-sensitive ASCII names to typed values. DefinitionMap maps names to{source, expected_type}; names cannot also appear as input bindings or overwrite reserved constants. No mutable global environment.

Reference1D={length:Length>0, origin:Length, direction:+1/-1}. Length is an explicitly caller-selected reference span, not assumed clear article space. direction changes mapped coordinates, not local interval signs. This module never deducts panel/edge thickness or discovers a world origin.

Context is mandatory:
- **positive_intervals**: all solved intervals must be strictly positive.
- **reference_points**: first/last fixed-only intervals may be negative or zero to position external/boundary points; all internal intervals must be positive. The literal zero endpoint is allowed as a zero-weight terminal marker. Positive total reference length is still required.
A caller that needs other degeneracy behavior must use a future explicit policy, not an implicit fallback.

DivisionResult={grammar_version, context, reference, expanded_terms, local_boundaries, mapped_boundaries, internal_points, ratio_or_null, dependencies, exact}. Each term has an index-based semantic slot ID; boundary IDs b0..bn and internal b1..b(n-1) are deterministic for one unchanged expanded topology. No persistent UUID/point-remapping promise is made. Coincident outer/internal markers retain their distinct IDs; the engine creates no physical part from a marker.

## Lexical grammar and precedence

ASCII identifiers:[A-Za-z_][A-Za-z0-9_]*. Numeric literal:one or more digits, optionally followed by dot and one or more digits. Examples0,1,12.5 valid;.5,1.,1e6, NaN, Infinity invalid in version 1. Signs are unary operators, not part of numeric tokens. Whitespace is space, tab, CR or LF. No comments, string literals, property access, assignments, imports, hashes, arrays or method dispatch.

The following EBNF is specification text only:

~~~ebnf
expression       = comparison ;
comparison       = sum , [ compare_op , sum ] ;
sum              = product , { ("+" | "-") , product } ;
product          = unary , { ("*" | "/" | "%") , unary } ;
unary            = ("+" | "-") , unary | primary ;
primary          = number , [ unit ]
                 | "(" , expression , ")" , [ unit ]
                 | identifier
                 | "$" , identifier
                 | boolean
                 | function_name , "(" , arguments , ")" ;
arguments        = expression , { "," , expression } ;
compare_op       = "==" | "!=" | "<" | "<=" | ">" | ">=" ;
unit             = "mm" | "cm" | "m" ;
boolean          = "true" | "false" ;

division         = segment , { ":" , segment } ;
segment          = count , "{" , gap_expression , "}"
                 | gap_expression , [ "[" , positive_length_literal , "]" ] ;
gap_expression   = sum ;
count            = positive_integer_literal ;
function_name    = identifier ;
positive_length_literal = number , unit ;
~~~

The shared sum/product/unary syntax is interpreted in the selected language's type algebra. Comparison/functions within a division may be used only when fully evaluable from typed symbols before any unknown allocation ratio is introduced. A bare comparison is not a gap. A generic function returning/consuming an unresolved affine gap is unsupported.

Precedence from high to low:parentheses/function or literal unit suffix, unary, multiplicative operators, additive operators, then one comparison. Multiplication/division/remainder and addition/subtraction are left-associative. A single unary sign is allowed per level; repeated signs may recurse within depth limit. No chained comparison in core-v1:1<2<3 fails. Descriptor-range syntax is a different deferred language.

Fixed repetition permits 1..1000 copies of one gap expression;8{1} expands eight gap terms. Nested repetition and colon-containing repeat bodies are rejected in version 1. Result expansion must not exceed 1000 segments. This is sufficient for the documented 8{1} family, not a claim of a complete brace grammar.

Quantization is restricted to **one** segment with scalar weight exactly 1 plus no fixed offset and a strictly positive fixed quantum; every other segment must be a fixed length. For example 20mm:1[32mm]:228mm:96mm. The free remainder must be an exact positive integer multiple of the quantum; otherwise return E_QUANTIZATION_INFEASIBLE. Version1 never rounds span, rounds quantum count or changes other segments. Arbitrary multi-quantum/mixed-weight allocation is deferred.

Historical n* auto-repeat,#descriptor, exponentiation,^/** and athan/atan compatibility are explicitly unsupported. The parser must distinguish unsupported families from an unknown ordinary variable where possible. Division user variables require $prefix; bare X, Y and pi are reserved. This makes bare n* unambiguously a deferred historical construct; ordinary multiplication by a bound count can be written $n*96mm if n is a supplied Scalar.

## Unit and numeric semantics

jp-core-v1:

- Length±Length→Length; Scalar±Scalar→Scalar.
- Scalar×Length and Length×Scalar→Length; Scalar×Scalar→Scalar.
- Length/Scalar→Length; Length/Length→Scalar; Scalar/Scalar→Scalar.
- Scalar/Length and Length×Length are outside version 1 and return E_UNIT_MISMATCH.
- Length+Scalar fails; Boolean arithmetic fails.
- Comparisons require equal numeric kinds; Boolean supports only ==/!=.
- mm is canonical; cm multiplies by 10, m by 1000. These conversions are JP proposals, not cited imos unit grammar.
- A unit suffix may convert a numeric literal or **parenthesized Scalar expression** to Length. Applying a unit to an already dimensional value fails. Thus (8/4)mm is explicitly 2mm.
- Binary% is permitted only for nonnegative integer Scalars with positive integer divisor. Negative/noninteger operands fail E_DOMAIN. No percent-unit suffix is defined. This restricted remainder is an original policy; the source merely lists the operator.

A required compatibility boundary:the documented unparenthesized 8/4mm denotes fixed 2mm in Manual Ndarja Lineare.pdf pp. 8. Core dimensional algebra would not derive that from 8/(4mm). In jp-division-v1, the unparenthesized scalar-division-by-unit pattern is rejected as E_UNSUPPORTED_LEGACY_UNIT with guidance to use (8/4)mm. No automatic rewrite is performed. In jp-core-v1 it is a unit mismatch. This is an explicit supported-subset limitation.

jp-division-v1 adds AffineGap{weight:Scalar, fixed:Length}:

- A top-level Scalar becomes proportional weight; Length becomes fixed length.
- Addition/subtraction of Scalar and Length in a gap produces an affine weight/fixed pair. Hence 1+100mm has weight 1, fixed 100mm.
- Affine gaps add/subtract componentwise. Multiply/divide an affine gap by a known Scalar only. Products of two unresolved affine gaps or functions whose result depends nonlinearly on the unknown ratio return E_NONLINEAR_DIVISION.
- X is the supplied reference length; Y is an optional separately typed reference length supplied by caller. Missing Y is an unknown-symbol error; it is never silently equal to X.
- Variable expressions evaluate first; gap coefficients and fixed terms must then be finite and fully resolved.
- Negative proportional coefficients are rejected. An affine gap may have a negative fixed coefficient when its solved interval remains positive, in either context. For 1-100mm:1 at L=600, the first gap has weight 1/fixed-100mm, ratio 350mm, and solved intervals 250/350; positive_intervals accepts it. Only a fixed-only negative/zero interval needs the terminal reference_points exception. A negative fixed-only internal interval or nonpositive solved internal interval is rejected in both contexts.
- No unit suffix implicitly attaches to an entire unparenthesized arithmetic segment except the explicitly supported literal/parenthesized rules.

Lifting rule:retain Scalar and Length values during constant subexpression evaluation. Create AffineGap only when addition/subtraction mixes Scalar with Length/another gap, then convert a remaining top-level Scalar to weight or Length to fixed. Scalar multiplication is never automatically multiplication of two unknown weights. Thus 2*3 is Scalar 6 until top-level conversion to weight 6;2*(1+100mm) is gap(weight 2, fixed 200mm);(1+100mm)*(1+50mm) returns E_NONLINEAR_DIVISION. This is a declared JP algebra rather than an undocumented historical precedence claim.

Arithmetic uses exact bounded rational operations for decimal/+/-/*// and allocation. No display rounding is fed back into results. Division allocation accepts only exact:true numeric values in its reference, quantum and evaluated coefficients. Any participating exact:false value returns E_INEXACT_DIVISION_INPUT before span/grid comparisons, even if its numeric ratio equals an integer. Unused approximate bindings do not fail a request. This prevents approximate trigonometry from changing topology at a grid/span boundary.

NumericPolicy is data {policy_id:"jp-rational-binary64-15-v1", backend_id:nonempty caller-supplied qualified Ruby/platform/Math-build identifier}; it cannot supply code or replace operators. pi is exactly the decimal approximation 3.141592653589793 stored as ratio 3141592653589793/1000000000000000 with exact:false. For trigonometric evaluation, convert the bounded Scalar to IEEE binary64, call the allowlisted standard Math function, require a finite result, convert that binary64 result to its exact rational value, and round that value to 15 significant decimal digits with round-half-even. Re-encode the finite decimal as normalized ratio with exact:false. Trig inputs are limited to abs(radians)<=1000000; inverse trig uses[-1,1]. Numeric policies other than this version are unsupported.

Approximation flags propagate conservatively through numeric operations; comparison returns Boolean from stored canonical numeric ratios, with no fuzzy-equality tolerance. Output metadata includes policy_id/backend_id. Repeated calculations with the same qualified backend are deterministic; different Ruby/Math builds are compared by declared tolerances, not promised byte-identical transcendental outputs. Cache keys include backend_id; an exported accepted value is not silently recalculated on another backend. Near-unit numerical fixtures use absolute tolerance 1e-12. Exact division outputs remain backend-independent because inexact inputs are rejected.

## Function allowlist

| Function | Signature | Rule |
|---|---|---|
|abs|Scalar→Scalar or Length→Length| Type preserved; no unresolved affine argument |
|min, max|2..16 same-kind numeric arguments→same kind| Original JP functions; not assumed historical grammar |
|if|Boolean, T, T→T| Both branches must type-check to same kind; only selected branch evaluated |
|sin, cos, tan|Scalar radians→Scalar| Radians only; no degree conversion. tan rejects abs(cos(x))<1e-12 |
|asin, acos|Scalar→Scalar radians| Input within[-1,1], otherwise E_FUNCTION_DOMAIN |
|pi|Reserved approximate Scalar constant| Caller cannot shadow |

No arctangent alias, rounding function, exponent, user function registration or arbitrary Ruby block is accepted in version 1. Unsupported names fail E_UNKNOWN_FUNCTION. Boolean branch type validation may inspect AST types but must not evaluate the unselected branch's divide-by-zero or unknown runtime arithmetic; unknown symbol references still require declarations.

## Variable dependency and presence rules

Extract all symbol references syntactically, including lazy branches, then validate declarations. Topologically order declared definitions using a deterministic lexical tie-break. Definition cycles/self-loops produce E_DEPENDENCY_CYCLE with involved IDs and path; no definition is published on failure. Evaluation may lazily skip a branch's arithmetic but cannot hide a missing declaration/cycle.

Symbols are case-sensitive; optional $prefix refers to the same declared name in core expressions. Division requires $for user names as stated above. Reserved X, Y/pi, true/false/function names cannot be rebound in that grammar. Names have explicit expected types; no automatic Scalar→Length based on a name ending_mm.

Absence, explicit 0 and unknown unit are different states. Missing symbol returns E_UNKNOWN_SYMBOL. This module does not inject any drawer fallback or manufacturer values. A later caller can explicitly define a typed fallback relationship such as SL_DR_Y=-SL_FR after resolving source units; the engine itself contains no drawer-specific logic.

No dependency on SketchUp, UI, Layout, filesystem, network, environment variables or wall-clock time. A cached result key includes grammar version, normalized AST, typed symbol values, context, reference span/origin/direction and numeric policy. Cache eviction cannot alter results.

## Allocation mathematics and output semantics

After expansion and symbol evaluation, each gap has known coefficients a_i, f_i. Let W=sum(a_i), F=sum(f_i), L=reference length.

- If W>0, ratio r=(L−F)/W; require r>=0. Then length_i=a_i*r+f_i.
- If W=0, require F=L exactly; ratio is null. Otherwise E_SPAN_MISMATCH.
- Validate all lengths against context before returning boundaries; do not silently clamp a negative result.
- Localb0=0; b(i+1)=b(i)+length_i. Finalbn must equal L exactly for exact inputs.
- Mapped coordinatec_i=origin+direction*b_i.
- Internal points areb1..b(n-1), not all outer endpoints. For0:1:0, theinternal points are0 and L; their marker identities are retained.
- In reference_points, negative fixed-only terminal intervals may make the internal point set extend outside[0, L]. This is legitimate for the documented external-point family. It is not permission for a negative physical compartment.

This module cannot turn the conflicting1500/19 example into one verified cabinet-opening result:it accepts1500 or another explicitly selected span and reference annotations supplied by the future construction caller. It never chooses whether 2 or 4 panels should be deducted.

## Diagnostics and limits

Diagnostic={code, severity:error, grammar_version, source_span:{start, end} or null, input_path:null or string, symbol_ids:[], message_key, details}. Offsets are zero-based Unicode code-point positions, end exclusive; identifiers remain ASCII. A future JS bridge must convert offsets explicitly if its editor uses UTF-16. No stack trace, object inspection or executable source is inserted into a response.

Codes:E_INPUT_CONTRACT, E_SYNTAX, E_FORBIDDEN_TOKEN, E_UNKNOWN_UNIT, E_UNIT_MISMATCH, E_UNKNOWN_SYMBOL, E_DUPLICATE_SYMBOL, E_RESERVED_SYMBOL, E_DEPENDENCY_CYCLE, E_DIV_ZERO, E_DOMAIN, E_UNKNOWN_FUNCTION, E_FUNCTION_DOMAIN, E_UNSUPPORTED_GRAMMAR, E_UNSUPPORTED_LEGACY_UNIT, E_NONLINEAR_DIVISION, E_INEXACT_DIVISION_INPUT, E_NEGATIVE_WEIGHT, E_REFERENCE_SPAN, E_SPAN_MISMATCH, E_DEGENERATE_INTERVAL, E_QUANTIZATION_INFEASIBLE, E_RESOURCE_LIMIT.

| Limit | Initial proposed value / enforcement |
|---|---|
| Source size |4096 characters before lexing |
| Tokens/AST nodes |1024 before recursive evaluation |
| Nesting |32; check before descent |
| Decimal literal |256 digits; no scientific exponent |
| Rational numerator/denominator |4096 bits after each arithmetic operation |
| Expanded division terms |1000; check multiplication before allocating |
| Definitions |1000 nodes with bounded dependency edges within step budget |
| Evaluation budget |10000 counted AST/dependency/expansion steps per request |
| Function arguments |16 maximum |

Limits are fixed defaults in version 1. Callers may tighten them, not enlarge them through untrusted input. Cancellation/timeout in a future adapter cannot publish a partial result. Exhaustion must be deterministic E_RESOURCE_LIMIT, not native recursion/memory failure.

## Source-derived and explicit JP fixtures

All tests below are specifications, not implemented or executed engine tests. Unless explicitly stated, reference origin is0, direction+1 and context positive_intervals; reference_points cases are labeled. Source pages identify documented behavior; exact rational outputs labeled INFERRED are independent arithmetic expectations.

| Fixture | Input/context | Expected outcome | Evidence/classification |
|---|---|---|---|
|E01|1:1, L600, positive_intervals|lengths300,300; internal point 300|Manual Ndarja Lineare.pdf pp. 5–6; INFERRED arithmetic |
|E02|0:1:0, L600, reference_points|lengths0,600,0; internal points 0,600|Manual Menaxhimi i Elementeve.pdf pp. 30; Manual per krijimin e dyerve.pdf pp. 2; VERIFIED boundary behavior |
|E03|77mm:1:77mm, L600, reference_points|77,446,77; points 77,523|Same sources; INFERRED coordinates |
|E04|88mm:1:88mm, L600, reference_points|88,424,88; points 88,512|Same sources; INFERRED coordinates |
|E05|20mm:64mm:1:1:1:64mm:35mm, L1000|r=817/3;6 internal points20,84,1069/3,1886/3,901,965|Manual Ndarja Lineare.pdf pp. 5; INFERRED positions, abstract spacing only |
|E06|20mm:64mm:1:2:1:64mm:35mm, L1000|r=817/4; middle variable interval twice its neighbors|Manual Ndarja Lineare.pdf pp. 6; INFERRED arithmetic |
|E07|8{1}, L800|8 intervals 100;7 internal points100..700|Manual Ndarja Lineare.pdf pp. 6; INFERRED coordinates |
|E08|-200mm:1:-200mm, L1000, reference_points|internal points−200,1200; final boundary 1000|Manual Ndarja Lineare.pdf pp. 7–8; VERIFIED printed positions |
|E09|1+100mm:1:1+50mm, L600|250,150,200; internal 250,400|Manual Ndarja Lineare.pdf pp. 8; INFERRED arithmetic |
|E10|1:X-100mm, L600|100,500; point 100|Manual Ndarja Lineare.pdf pp. 8; documented equivalent100mm:1 |
|E11|1:2*($a+$b)mm, L600, a=Scalar 2, b=Scalar 3|590,10; point 590|Manual Ndarja Lineare.pdf pp. 8–9; source fixed10, INFERRED remainder |
|E12|20mm:1[32mm]:228mm:96mm, L600|20,256,228,96; quantum count8|Manual Ndarja Lineare.pdf pp. 7; INFERRED exact-grid result under restricted JP policy |
|E13|1:1, L600, origin20, direction−1|mapped boundaries 20,−280,−580|PROPOSED explicit frame mapping |
|E14|W−2*T, WLength600, TLength18|Length 564|PROPOSED typed engineering fixture; no constructionrule inferred |
|E15|0.1+0.2|Scalar 3/10 exact|PROPOSED rational policy |
|E16|sin(pi/2)|Scalar near 1 within1e-12; exact:false|Manual Ndarja Lineare.pdf pp. 8 radians; numeric policy PROPOSED |
|E17|if(true,10mm,1mm/0)|Length 10; unselected branch not evaluated; both branches length-typed|PROPOSED lazy conditional |
|E18|1-100mm:1, L600, positive_intervals|250,350; negative affine fixed coefficient is not a negative solved interval|PROPOSED explicitJP policy |
|E19|2*3:1, L700|600,100; known Scalar multiplication becomesweight 6 only at term boundary|PROPOSED explicit lifting rule |
|E20|2*(1+100mm):1, L800|600,200; gap weight 2/fixed 200mm plusweight 1|PROPOSED explicit lifting rule |

## Negative and boundary fixtures

| Fixture | Input | Expected version 1 behavior |
|---|---|---|
|N01|77mm:1:77mm at L153|Negative weighted remainder→E_SPAN_MISMATCH |
|N02|Same at L154|Zero middle physical/reference interval→E_DEGENERATE_INTERVAL |
|N03|0:1:0 inpositive_intervals|E_DEGENERATE_INTERVAL; not a valid3-compartment construction |
|N04|-200mm:1:-200mm inpositive_intervals|E_DEGENERATE_INTERVAL; external-point policy not enabled |
|N05|1:-1 ornegative proportional coefficient|E_NEGATIVE_WEIGHT |
|N06|All fixed 100mm:200mm, L300|Success, ratio null; at L301→E_SPAN_MISMATCH |
|N07|L0 ornegative reference span|E_REFERENCE_SPAN |
|N08|20mm:1[32mm]:228mm:96mm, L601|E_QUANTIZATION_INFEASIBLE; do not round |
|N09|n*110mm:1|E_UNSUPPORTED_GRAMMAR; SC04 still open |
|N10|#descriptor orif-range descriptor file|E_UNSUPPORTED_GRAMMAR; no file access |
|N11|2^3,2**3, athan(1), atan(1)|Explicit unsupported grammar or unknown-function diagnostic as appropriate |
|N12|8/4mm in division|E_UNSUPPORTED_LEGACY_UNIT; explicit(8/4)mm yieldsfixed 2 |
|N13|1mm+1 incore expression|E_UNIT_MISMATCH; thedivision-affine form is a differentlanguage |
|N14|1/0; asin(2); tan(pi/2)|E_DIV_ZERO; E_FUNCTION_DOMAIN; E_FUNCTION_DOMAIN |
|N15|Unknown symbol; duplicate binding; attempt to rebindpi|E_UNKNOWN_SYMBOL; E_DUPLICATE_SYMBOL; E_RESERVED_SYMBOL |
|N16|a depends onb, b depends ona; self-loopa|E_DEPENDENCY_CYCLE; full environment unpublished |
|N17|File.read(...), Kernel.system(...), backticks, quotes, semicolon, assignment|E_FORBIDDEN_TOKEN/E_SYNTAX; no external action |
|N18|4097 characters,33-deep expression,1001 repeated intervals, oversized ratio|E_RESOURCE_LIMIT before unbounded recursion/allocation |
|N19|Explicit0 binding versus absent value|0 evaluates normally; absenceE_UNKNOWN_SYMBOL; no default-to-zero |
|N20|1<2<3 orcm suffix on Length variable|E_SYNTAX or E_UNIT_MISMATCH; no chained-range inference |
|N21|Two affine factors multiplied; abs(1+100mm)|E_NONLINEAR_DIVISION; no hidden root solver |
|N22|Repeated body8{1:1} ornested8{2{1}}|E_UNSUPPORTED_GRAMMAR; version 1 repeat body is one gap |
|N23|Numeric NaN/Infinity/1e999 andhost Float bindings|LexicalE_SYNTAX or E_INPUT_CONTRACT; only bounded validated serialized quantities accepted |
|N24|Any exact:false reference span, quantum or coefficient, including sin(pi/2) asweight|E_INEXACT_DIVISION_INPUT before grid/span/allocation decisions; unused approximate symbols harmless |

## Ruby 2.7 and implementation boundaries

Use Ruby 2.7-compatible syntax and standard Rational/Integer/Math facilities; no current Dentaku or other third-party evaluator. Preserve explicit positional/keyword separation for Ruby 2.7/3.2 caller compatibility. Avoid pattern-matching syntax, numbered block parameters in shared code, newer endless method definitions, newer collection conveniences and any host API dependency. Source strings are data, never Ruby code. Do not use eval, instance_eval, class_eval, send/public_send onuser names, ERB or RubyVM compilation.

No implementation files are created in Phase 1C. Proposed future files:expression/lexer.rb, parser.rb, type_checker.rb, evaluator.rb, dependency_graph.rb; division/parser.rb, allocator.rb; shared quantities/diagnostics; focused test/expression andtest/division files. These filenames are planning references, not scaffolding.

Before actual module acceptance, run focused tests with real Ruby 2.7 and 3.2 executables and capture versions/results. A systemPython arithmetic check, an API stub or SketchUp 2026 alone cannot pass that gate. No realSketchUp runtime is needed to prove pure arithmetic, butlater host integration must be tested separately.

## Proposed execution slices after explicit approval

1. Typed quantities/diagnostics, exact literals andbounded lexing; E14/E15, N13/N17/N18/N23.
2. Parser/typechecker/function allowlist; E16/E17, N11/N14/N20.
3. Dependency resolver andpresence rules; N15/N16/N19.
4. Fixed/weighted/affine allocation andreference mapping; E01–E06/E08–E11/E13, N01–N07/N21.
5. Boundedfixedrepeat andsingle-quantumsubset; E07/E12, N08–N10/N22.
6. Cross-version core qualification andresource/error audit; allfixtures plus strict absence of host/network/filesystem imports.

Each slice needs a failing focused test, observed relevant failure, minimal implementation, passing check andsmall reviewable commit at that future time. This is not an instruction to start Phase 2. Outstanding source cases remainunsupporteduntil separately evidenced and approved.

