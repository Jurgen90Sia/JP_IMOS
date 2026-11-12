# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Documented linear grammar — evidence supersedes the Phase1 draft

All page numbers refer to **Manual Ndarja Lineare.pdf**, unless another exact filename is stated. Syntax families below are VERIFIED; equations/coordinates explicitly labeled INFERRED are derived from examples. Some examples originally distribute connectors: only their abstract spacing grammar is analyzed. No drilling pattern, tool or machine capability is proposed.

| ID | PDF page | Classification | Documented syntax / meaning | Required input / limitation |
|---|---:|---|---|---|
| LD01 |5–6| VERIFIED | Colon intervals combine explicit mm lengths and proportional bare numbers.1:2:1 weights middle twice its neighbors. | Total reference length; not automatically clear cabinet span |
| LD02 |6| VERIFIED |8{1} abbreviates eight repeated1 intervals. | Fixed repeat count; nesting grammar not established |
| LD03 |6| VERIFIED |20mm:n*96mm:1 uses as many96mm steps as fit after fixed start, with variable remainder. | Exact-fit terminal duplication UNKNOWN |
| LD04 |7| VERIFIED |20mm:1[32mm]:228mm:96mm constrains variable interval to multiples of 32mm. | Quantization supported; arbitrary off-grid rounding rule UNKNOWN |
| LD05 |7–8| VERIFIED |AtL1000, -200mm:1 gives point-200; -200mm:1:-200mm gives points-200 and 1200. | Valid external construction points, not negative physical zones |
| LD06 |8| VERIFIED |1+100mm:1:1+50mm mixes proportional and fixed additions; first/last exceed middle by100/50mm. | Requires affine division terms, not ordinary Length+Scalar error |
| LD07 |8| VERIFIED |X is total division length; Y is other-axis total when two-axis divisions exist.1:X-100mm equals100mm:1. | Scope variables distinctly from article world coordinates |
| LD08 |8| VERIFIED |Operators +,-,*,/,% shown; functions pi, sin, cos, tan, asin, acos, athan, abs; angles in radians. | Exponentiation label has no visible token; athan spelling is printed, runtime acceptance UNKNOWN |
| LD09 |8–9| VERIFIED |$ prefixes named variables;1:2*($a+$b)mm witha2, b3 equals1:10mm.8/4 means proportional2;8/4mm means fixed2mm. | Unit-suffix grouping differs from generic dimensional arithmetic |
| LD10 |9–10| VERIFIED |Descriptor file uses if conditions plus default; selected descriptor referenced by#name. Screenshot: if x<=300mm; next if300mm<x<=500mm; then default. | Screenshot clarifies300 boundary despite overlapping translated prose; general dispatch/overlap precedence UNKNOWN |
| LD11 |11| VERIFIED |1:1:1 with reference length1500 and 19mm dividers uses outer bottom/top faces and intermediate centerlines to show500 intervals. | These are reference distances, not necessarily equal clear compartments |
| LD12 |12| UNKNOWN conflict |Prose says clear compartments487.3, screenshot says474.7 for displayed1500 and 19mm. | Retain both; do not use inconsistent source as one passing test |

### Mathematical formalization — INFERRED

Let selected reference span beL, terms be a_i*r+f_i wherea_i are proportional weights andf_i fixed lengths. Then r=(L−Σf_i)/Σa_i whenΣa_i>0; interval_i=a_i*r+f_i. Internal cumulative boundaries position objects. Context determines whether those boundaries are part-local construction points, front segments or physical divider references. Apply reference-face/thickness transforms separately.

AtL600:1+100mm:1:1+50mm givesr150 and intervals250,150,200; points250,400. This is INFERRED arithmetic fromLD06, not a printed source coordinate set. Reject nonlinear unresolved weight equations and nonfinite values in the proposed parser.

AtL1500 with four19mm horizontal panels included in outer extent, equal clear openings would be(1500−4×19)/3=474.666…mm, matching screenshot474.7. The printed487.3 corresponds to(1500−2×19)/3. Both calculations are INFERRED explanations ofLD12; they do not repair the manual or certify live imos behavior. Physical reference choices must be explicit before any deduction.

### Four requested expressions — correct construction context

VERIFIED source: **Manual Menaxhimi i Elementeve.pdf pp. 30** and **Manual per krijimin e dyerve.pdf pp. 2**. These expressions create part-local X/Y construction-point sets. They do not by themselves subdivide cabinet volume or reserve panel thickness.

| Expression | Documented behavior | INFERRED coordinates for one axisL600, origin0 | Edge/validation policy |
|---|---|---|---|
|0:1:0| Boundary construction points, both axes define outer vertices | Internal cumulative point positions0,600; their Cartesian product yields four corners | Zero offsets are legitimate; no zero-volume physical panels generated |
|1:1| Two equal intervals; source equal-leaf usage also in Manual Menaxhimi i Elementeve.pdf pp. 94 | One internal point300; if used as zone split, two intervals300 each before reference/thickness adjustments | Context and chosen reference distinguish leaf/point/zone outcomes |
|77mm:1:77mm| Fixed perimeter distances; middle changes with part size | Points77,523; middle extent446 | L<154 infeasible for positive middle; L154 degenerate physical center |
|88mm:1:88mm| Second fixed perimeter point set for frame | Points88,512; middle extent424 | Corresponding threshold176; do not merge77/88 point-set identities |

The complete interval boundary arrays could be0,0,600,600 for 0:1:0; the generated construction points are the INTERNAL boundaries0,600. Phase1's interpretation as three physical “zones” was misleading and is replaced.

### Negative, repeated and reference examples

External X endpoints-20/+20 beyond reference are documented in Manual per krijimin e dyerve.pdf pp. 3–4. The2009 Manual Menaxhimi i Elementeve.pdf pp. 32 labels both axis linesX, while2020 p4 distinguishesX andY; preserve this editorial discrepancy rather than guessing. n*110mm:1 repeats fixed110 steps; exact-multiple behavior remains UNKNOWN.

Article horizontal420mm:1 has Zona outer-side reference versus Pezzo inner-side reference (**Manual Artikull Parametrik.pdf pp. 43**). Thus a side thickness changes world-coordinate placement even with identical text. Double division can connect two perimeter-reference sides rather than an axis-aligned compartment split (same PDF39–42).

Manual front layout with auto clearance off uses explicit clearances, e.g.2mm:400mm:4mm:600mm:4mm:1:2mm (**Manual Artikull Parametrik.pdf pp. 71–72**). At total spanH, remaining front height isH−1012mm (INFERRED); minimum valid physical height must be enforced separately.

## Safe expression/parser design — PROPOSED revision

Retain a lexer, immutable AST, allowlisted functions, no eval/arbitrary Ruby/JavaScript execution, explicit budgets and dependency cycle detection. Use TWO related languages:
1. Typed engineering expressions: Length, Scalar, Boolean, Angle; no implicit Length+Scalar.
2. Division expressions: affine weight+fixed-length terms, repeat/quantization constructs, explicit source-compatible unit suffix rules, reference anchors and descriptor AST.

Parse colon/repetition/quantization in the division grammar; no Ruby method dispatch, property access, reflection, filesystem, network, imports, assignments or executable user callbacks. Generic function names such as if/clamp/min/max are JP proposals; source sin/pi/abs can be allowlisted with typed angle contracts. Do not invent an exponent token, silently fix athan→atan, or treat whole-source syntax as verified beyond documented examples. Compatibility mappings require explicit versioned rules.

Proposed limits remain4096 characters,1024 tokens/nodes, depth32,1000 expanded instances and 10000 evaluation steps per expression. Use exact decimal/rational allocation until final conversion. Imported absent values remain absent; zero is not a missing-value sentinel.

## Drawer variable dictionary — actual PDF evidence

Source for every row: **Variablat e brendshme te Sirtareve ne Imos.pdf**. Meanings are VERIFIED. Numeric table fields say Number(editable), without explicit units, so “mm” as the source contract is UNKNOWN; JP's internal mm convention remains a separate design decision. DR_TYP is an enumeration.

| Variable | VERIFIED meaning | PDF page(s) | Dependency / construction effect |
|---|---|---|---|
| SL_DR_X | Distance from slide insertion to virtual inside-box insertion in X | 1,6,13 | Inside-box anchor position; not universal side clearance |
| SL_DR_Y | Distance from slide insertion to virtual inside-box insertion in Y | 1,7,13 | When absent/not displayed, -SL_FR; explicit zero differs from absent |
| SL_DR_Z | Distance from slide insertion to virtual inside-box insertion in Z | 2,7,13 | Inside-box vertical anchor position |
| SL_BO | Distance from slide insertion to slide bottom edge | 2,7,13 | Slide reference distance; not bottom thickness |
| SL_SE_BO | Safe distance from slide bottom to virtual outside-box bottom | 2,7,13 | Admissible placement; separate from SL_BO |
| SL_H | Slide height | 2,7 | Slide envelope dimension; repeated source row |
| SL_FR | Distance from slide insertion to slide front edge | 2,7,13 | Controls absent SL_DR_Y fallback |
| SL_SE_FR | Safe distance slide to virtual outside-box front edge | 2,7,13 | Separate clearance from SL_FR |
| SL_L | Drawer depth; Quadro adjusted example equals slide length | 2,7 | Not a universal product-depth formula |
| SL_EB | Slide installation width; explanation slide width | 2,7 | Does not establish opening−2*SL_EB as a box formula |
| DR_H | Frame height, formerly Drawer height; explanation Drawer height | 2,8,14 | Not established as front/storage height |
| DR_TYP | Role enum SL, FP, BP, ZARGE, BS, SL+Zarge, BP_FITTING | 3,9–10,14 | Component role; preserve case and German labels in source mapping |

DR_TYP labels identify slide, front piece, back piece, frame, bottom (“Soil” in English source), slide+frame and back-panel fitting. Source spelling preserved; do not translate enum values into different persisted tokens without a mapping.

VERIFIED fallback: **SL_DR_Y=-SL_FR only when SL_DR_Y is absent/not displayed** (same PDF1,7,13). Proposed test: SL_FR37 with absentSL_DR_Y gives-37; explicitSL_DR_Y0 stays0. This is a sourced relationship, not a manufacturer clearance default.

Additional relevant fields: SL_DR_REF top/center/bottom (same PDF2,7,13–14); conditional lower-shelf clearanceSL_SE_BO_BS (p4); DR_INSET moves inside box and slides backward (p9); DR_BP_* back offsets/height/thickness andDR_BS_* bottom offsets/thickness (p8); purchased-member bottom-depth reductionsDR_BS_D_SUB_1/2 (p9); accessory targetingDR_MOVES_COMPONENT plus dependent offsets (pp4–5,11–12,15–17); stretchable inside-box paths (pp18–19).

INFERRED bottom-depth form: slide_length−resolved_reduction. Source p9 distinguishes one-purchased-member from both-purchased-member cases, with accessory additions in theSUB_1 case. Cross-field precedence if both are specified is UNKNOWN: proposed validator rejects competing unresolved cases rather than double-subtracting.

## Constraints and evidence gaps

UNKNOWN: exact-fit terminal handling for n*, arbitrary quantization rounding, complete grammar/operator precedence, descriptor overlap/error semantics beyond printed examples, all numeric field units/ranges, global distance signs/origins, and precedence when multiple connectors supply a characteristic. No live imos test was run. Negative geometric intervals are allowed for construction points but negative physical dimensions remain invalid. Historical runner examples in Manual Sirtaret.pdf pp. 24–29 are scoped examples only; they are not JP defaults.
