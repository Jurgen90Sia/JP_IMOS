# Phase 1C source-conflict register

Date:12 November 2026. Status:validation complete; unresolved evidence retained. This is an additive supplement to the 14 preserved Phase 1B reports. It does not replace or rewrite them. All locators are one-based PDF pages. Cached source hashes are in [01](01-source-inventory.md).

Severity describes consequence **in the affected feature**, not automatic blockage of every module:
- BLOCKER: cannot safely accept that feature's input contract without additional evidence.
- HIGH: materially changes dimensions, quantity or topology.
- MEDIUM: bounded syntax/behavior ambiguity with an explicit unsupported path.
- LOW: optional metadata/UI mapping issue.

VERIFIED refers to the actual historical document; INFERRED is derived reasoning; PROPOSED is a JP policy; UNKNOWN remains unsupported. Synthetic numbers below are reproducible counterexamples, not manufacturer specifications. Math examples can be reproduced with rational arithmetic; they are not executed plugin tests.

## Conflict and uncertainty register

| ID | Trace requirement(s) | Severity | Exact PDF | Page | Conflicting interpretations / missing contract | Reproducible example | Evidence disposition / containment | Evidence that would resolve it |
|---|---|---|---|---|---|---|---|---|
| SC01 | PB-LD07 | HIGH | Manual Ndarja Lineare.pdf | 12 | Prose gives487.3mm; figure gives474.7mm for displayed1500mm and 19mm panels. | (1500−2×19)/3=487.333…; (1500−4×19)/3=474.666…. Both explain a different thickness budget; neither proves a corrected source. | INFERRED explanations only. Core engine receives a caller-selected reference span; it does not choose panel deductions. | Corrected original manual or recorded imos run with the same four-panel reference setup and measured reference faces. |
| SC02 | PB-LD05 | MEDIUM | Manual Ndarja Lineare.pdf | 8 | Exponentiation is labeled but its operator glyph is absent in the rendered page. | 2^3 and 2**3 could each mean8 under different grammars; neither token is documented by the visible source. | UNKNOWN token; core-v1 rejects both. No Ruby exponent fallback. | Authoritative operator table or isolated live parser examples for the exact source edition. |
| SC03 | PB-LD05 | MEDIUM | Manual Ndarja Lineare.pdf | 8 | Printed athan may be intended arctangent, but spelling acceptance is not established. | atan(1)=pi/4 is mathematical convention; it does not prove athan(1) is accepted. | UNKNOWN alias; neither athan nor atan is in the initial allowlist. | Vendor correction or live evaluation of both spellings with version recorded. |
| SC04 | PB-LD02, PB-MP02 | HIGH | Manual Ndarja Lineare.pdf; Manual per krijimin e dyerve.pdf | 6;4–5 | n*fixed says as many steps as fit; terminal behavior at exact fit is unspecified; point-count changes affect dependents. | AtL212,20mm:n*96mm:1 permits2×96 with remainder0, or1×96 with remainder96 if the final interval must stay positive. Counts differ though sums match. | UNKNOWN source termination. Core-v1 rejects n*; fixed8{1} is separately supported. | Live results at L211,212,213 showing intervals, generated points and dependent-child update behavior. |
| SC05 | PB-LD02 | HIGH | Manual Ndarja Lineare.pdf | 7 | Quantized interval is a multiple of 32; off-grid rounding or span adjustment is unspecified. | 20+228+96=344; at L=600 residual256=8×32; at L601 residual257. Floor256 leaves1mm; ceil288 exceeds by31mm. | VERIFIED on-grid constraint; JP core accepts the restricted exact-grid case and rejects off-grid requests without rounding. | Recorded off-grid inputs and whether the product rejects, rounds reference span or redistributes other intervals. |
| SC06 | PB-LD06 | HIGH | Manual Ndarja Lineare.pdf | 9–10 | Translated prose overlaps at 300; screenshot conditions separate x<=300 and 300<x<=500. General overlap precedence is not specified. | x300 satisfies both inclusive prose ranges; screenshot assigns first only. Two arbitrary conditionsx<=500 andx>=300 overlap over[300,500]. | Screenshot example is VERIFIED; general first-match/last-match/error dispatch remains UNKNOWN. Descriptor files deferred. | Original descriptor grammar and ordered overlap/default tests at 299,300,301,500,501. |
| SC07 | PB-LD04 | HIGH | Manual Ndarja Lineare.pdf | 8–9 | Unit suffix grouping and mixed proportional/fixed arithmetic differ from generic dimensional arithmetic. | Source8/4mm is fixed 2mm; generic8/(4mm) has reciprocal-length dimension.1+100mm mixes a weight and length; at L=600 the three affine terms give250,150,200. | VERIFIED examples; two separate JP languages proposed. Parenthesized(8/4)mm is explicit JP form; unparenthesized legacy suffix division deferred. | Full operator/unit precedence grammar or live comparison of 8/4mm,8/(4mm),(8/4)mm and longer mixed expressions. |
| SC08 | PB-C02, PB-C03, PB-AD04 | HIGH | Manual Menaxhimi i Elementeve.pdf; Manual Artikull Parametrik.pdf | 67,77–80,88–89,96–97,105,113;43 | Back inner/outer face and source-field signs are contextual, not one universal offset rule. | JP frame D=560, setback10, t8:outer-ref back inner face542; inner-ref back inner face550 and outer558. A+10 shelf projection and+10 long-piece inset move differently. | VERIFIED choices; coordinate equations/sign normalization are INFERRED/PROPOSED. No competing source rule if context retained. | Explicit reference member/face and field identity in each approved construction fixture; angled cases need measured geometry. |
| SC09 | PB-DR02 | HIGH | Variablat e brendshme te Sirtareve ne Imos.pdf | 1–2 | Outside box is reduced by safe distances, but a universal per-face budget and world transform are not specified. Inside box is a construction anchor box. | Opening600 and a synthetic12 allowance could give588 if one-sided or576 if both sides. The source does not authorize choosing either from SL_EB alone. | VERIFIED boxes; numeric aggregation/transform UNKNOWN. Outside first-module scope. | A sourced drawer-system profile specifying each face, units, origin, orientation and containment exceptions. |
| SC10 | PB-V-SL_DR_X, PB-V-SL_DR_Y, PB-V-SL_DR_Z, PB-V-SL_BO, PB-V-SL_SE_BO, PB-V-SL_H, PB-V-SL_FR, PB-V-SL_SE_FR, PB-V-SL_L, PB-V-SL_EB, PB-V-DR_H | BLOCKER | Variablat e brendshme te Sirtareve ne Imos.pdf | 1–2,6–8,13–14 | Number(editable) fields do not state a universal unit/sign/origin contract; DR_TYP is an enum and has no numeric unit. | Numeric12 could be12mm or12cm=120mm absent unit evidence. Documented missing SL_DR_Y with SL_FR37 gives−37 in the same unit; explicit 0 remains0. | Meanings and absence fallback VERIFIED; automatic manufacturer/profile import BLOCKED. Typed caller-supplied symbols do not inherit guessed units. | Authoritative units/reference-frame/profile schema, allowed ranges and multi-connector precedence for the exact system/version. |
| SC11 | PB-DR04 | HIGH | Variablat e brendshme te Sirtareve ne Imos.pdf | 9 | SUB_1 and SUB_2 describe different purchase-part cases; precedence if competing fields coexist is not supplied. | Synthetic slide500, front16, back16:one-member case484; both-member case468; subtracting16 and 32 together would452. Accessory additions are documented for SUB_1 but do not resolve cross-field precedence. | VERIFIED conditional cases; unresolved combination must diagnose rather than double subtract. Outside first-module scope. | A valid system configuration and live/reference outcomes with each field separately and both present. |
| SC12 | PB-DR01, PB-DR06 | HIGH | Manual Sirtaret.pdf | 12–13,24–30 | Height/depth list chooses an appropriate value, without a complete selection algorithm; historical runner examples are not current profiles. | For synthetic candidates100,160 and space150:floor gives100, nearest160 does not fit, and a constrained system may reject. No universal nearest/floor rule is documented. | UNKNOWN selection contract; historical numerical rows remain source-scoped examples only. | System-specific selection policy and current manufacturer catalog with valid ranges and construction type. |
| SC13 | PB-C01, PB-C03 | MEDIUM | Manual Menaxhimi i Elementeve.pdf | 108,116 | Max-length field is described as upper limit, then prose says error when article width is below it; front/rear labels also show copy-edit inconsistencies. | For max1000, width900:ordinary maximum check passes but printed below-limit sentence predicts error; at 1100 outcomes reverse. | UNKNOWN source contradiction; no silent correction to comparison direction. Long-piece engine deferred. | Corrected original text or recorded900/1000/1100 inputs showing errors and generated geometry. |
| SC14 | PB-LAY02 | LOW | Manual Skuadrim dhe Layout.pdf | 7–9 | Some field tags are malformed or undescribed; two view meanings share a tag and some rows say NOT USED. | A selected material value Oak is valid only with a known binding; an undefined CALC tag could yield blank, error or another value. No arithmetic can derive a missing field definition. | UNKNOWN mappings; JP typed metadata errors explicitly. Layout is outside initial module. | Authoritative tag dictionary and a known template demonstrating the ambiguous fields. |
| SC15 | PB-MP01, PB-MP02 | MEDIUM | Manual Menaxhimi i Elementeve.pdf; Manual per krijimin e dyerve.pdf | 32;3–4 | 2009 example labels two axis rows X;2020 labels external points X and the 20mm construction row Y. | For W600, H400, external X points−20,620 and Y point20 differ from putting both recipes on X while leaving Y unresolved. | 2020 clarification is documented; cross-edition universal equivalence not proved. Typed axes required by caller. | Original source diagram or exact saved MultiPart definition for 2009; version-specific import mapping. |
| SC16 | PB-MAT01, PB-MAT02, PB-MGR02, PB-MP03 | HIGH | Manual Menaxhimi i Elementeve.pdf; 00_Manager.pdf | 11,15,18,21,37–40;47 | Finished stack, edge deductions and reporting frames are distinct; source examples do not establish one universal additive/deduction recipe. | Synthetic finished substrate18.5 plus 0.5mm each face gives19.5 only under an explicitly additive stack. The printed720/718.60 dimensions do not identify how1.40mm is allocated among edges. | VERIFIED distinctions; general stack/deduction and measurement-frame solver remain contextual JP proposals. | Approved characteristic/layer policy and per-edge source fixture; shaped pieces require selected report frame. |

SC08/SC16 are chiefly **context-dependent design risks**, not proof the manual contradicts itself. SC09/SC10/SC11/SC12/SC14 are missing contracts. SC01/SC13 are actual textual/numerical conflicts; SC02/SC03/SC15 are missing/possibly corrupted syntax or editorial/edition differences. This distinction prevents turning every UNKNOWN into an alleged vendor defect.

## Disposition of all 49 traceability entries

Reviewed against the preserved [49-row matrix](13-requirements-traceability.md), the Phase 1B extraction records, and full cited pages where needed. This review validates locators, classification and unresolved implications; it does not repeat the entire555-page research.

| Trace ID | PDF page(s), as preserved | Review disposition | Register / narrow-module treatment |
|---|---|---|---|
| PB-AD01 | 4–6 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-AD02 | 37–50 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-AD03 | 51–52 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-AD04 | 25–26,43 | Open classified conflict/contract gap | SC08 |
| PB-AD05 | 12,18,71–74 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-LD01 | 5–6 | No conflicting formula found in the cited claim | Affine solver is INFERRED from documented spacing; declared JP semantics in 16 |
| PB-LD02 | 6–7 | Open classified conflict/contract gap | SC04, SC05 |
| PB-LD03 | 7–8 | No conflicting formula found in the cited claim | Documented external-point example; reference_points context only |
| PB-LD04 | 8–9 | Open classified conflict/contract gap | SC07 |
| PB-LD05 | 8 | Open classified conflict/contract gap | SC02, SC03 |
| PB-LD06 | 9–10 | Open classified conflict/contract gap | SC06 |
| PB-LD07 | 11–12 | Open classified conflict/contract gap | SC01 |
| PB-MP01 | 29–31 | Open classified conflict/contract gap | SC15 |
| PB-MP02 | 1–5 | Open classified conflict/contract gap | SC04, SC15 |
| PB-MP03 | 6–14 | Open classified conflict/contract gap | SC16 |
| PB-MAT01 | 11,15,18,21 | Open classified conflict/contract gap | SC16 |
| PB-MAT02 | 17–23 | Open classified conflict/contract gap | SC16 |
| PB-C01 | 65–75 | Open classified conflict/contract gap | SC13 |
| PB-C02 | 77–80 | Open classified conflict/contract gap | SC08 |
| PB-C03 | 88–89,96–97,105,113 | Open classified conflict/contract gap | SC08, SC13 |
| PB-C04 | 121–128 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-DR01 | 5–7,11–16 | Open classified conflict/contract gap | SC12 |
| PB-DR02 | 1 | Open classified conflict/contract gap | SC09 |
| PB-DR03 | 1,7,13 | Open classified conflict/contract gap | SC10; absence-only fallback verified, explicit 0 distinct |
| PB-DR04 | 8–9 | Open classified conflict/contract gap | SC11 |
| PB-DR05 | 18–22 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-DR06 | 24–30 | Open classified conflict/contract gap | SC12 |
| PB-TX01 | 1–3 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-MGR01 | 9–10,19–28 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-MGR02 | 47,65–66,78–79 | Open classified conflict/contract gap | SC16 |
| PB-MGR03 | 89–91 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-LAY01 | 4–6,9–13 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-LAY02 | 6–9 | Open classified conflict/contract gap | SC14 |
| PB-LAY03 | 1–13 | No conflicting formula found in the cited claim | JP enhancement rather than vendor behavior claim; outside initial module |
| PB-FREE01 | 4–27,28–37 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-HW01 | 2–6 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-HW02 | 2–4,7 | No conflicting formula found in the cited claim | Retain VERIFIED/INFERRED/PROPOSED boundary from original row; no extra formula invented |
| PB-V-SL_DR_X | 1,6,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_DR_Y | 1,7,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_DR_Z | 2,7,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_BO | 2,7,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_SE_BO | 2,7,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_H | 2,7 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_FR | 2,7,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_SE_FR | 2,7,13 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_L | 2,7 | Open classified conflict/contract gap | SC10 |
| PB-V-SL_EB | 2,7 | Open classified conflict/contract gap | SC10 |
| PB-V-DR_H | 2,8,14 | Open classified conflict/contract gap | SC10 |
| PB-V-DR_TYP | 3,9–10,14 | No conflicting formula found in the cited claim | Enum; numeric unit is not applicable. The generic status wording in preserved13 must not be read as a missing length unit for this enum. |

## Readiness decision

The first technical module may be specified and later approved as **jp-core-v1 / jp-division-v1**, with explicit input types and contexts, exact arithmetic and no inferred panel/drawer construction. Legacy source compatibility is a separate claim. No full historical parser compatibility is approved.

Core-v1 does not choose panel reference deductions(SC01), accept an invented exponent/atan alias(SC02/03), implement unknown n* termination(SC04), round off-grid quantization(SC05), execute descriptor files(SC06), or silently reinterpret ambiguous legacy unit grouping(SC07). All drawer, back, material, layout and long-piece choices stay out of this module; callers must eventually resolve their own source contracts.

No unresolved item is marked resolved simply because one mathematical interpretation is plausible. Source evidence correction requires a dated source/version and reproducible observed/reference result, not a change to these14 historical reports.

