# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Phase1B requirement-to-page traceability

This table replaces the earlier missing-manual matrix. Page is a one-based PDF index. Test IDs are proposed future tests, not executed software tests. VERIFIED applies to documented behavior, not JP's still-unwritten implementation. Formula cells explicitly distinguish printed relationships from INFERRED formalization. One row may cite a complete section only when its behavior spans it; focused numerical rules have focused page locators.

| Requirement ID | PDF | Page | Documented behavior | Formula | Proposed module | Test ID | Status |
|---|---|---|---|---|---|---|---|
| PB-AD01 | Manual Artikull Parametrik.pdf | 4–6 | Carcass/reference dimensions exclude fronts and protruding shelves | Not overall union bounds | Article Designer | T-A01 | VERIFIED |
| PB-AD02 | Manual Artikull Parametrik.pdf | 37–50 | Nested zones and subarticles | Parent/child references | Zone Hierarchy | T-A02 | VERIFIED |
| PB-AD03 | Manual Artikull Parametrik.pdf | 51–52 | Independent overlapping zone layers | Partition mode differs from independent_layers | Zone Hierarchy | T-A11 | VERIFIED |
| PB-AD04 | Manual Artikull Parametrik.pdf | 25–26,43 | Edge1, drawing X, division reference are separate; Zona/Pezzo differ | 420mm measured from selected outer/inner face | Reference Resolver | T-A07, T-A10 | VERIFIED |
| PB-AD05 | Manual Artikull Parametrik.pdf | 12,18,71–74 | Article clearance/local production overrides; front layout independent of shelves | Hremaining=H−1012 for cited example (INFERRED) | FrontLayout/metadata | T-A03, T-A16 | VERIFIED behavior; INFERRED arithmetic |
| PB-LD01 | Manual Ndarja Lineare.pdf | 5–6 | Fixed/proportional mixed intervals | r=(L−Σfixed)/Σweight (INFERRED) | Linear Division | T-B07 | VERIFIED syntax / INFERRED solver |
| PB-LD02 | Manual Ndarja Lineare.pdf | 6–7 | 8{1}, n*96mm,1[32mm] repetition/quantization | Exact-fit and off-grid policy UNKNOWN | Linear Division | T-B08 | VERIFIED family; UNKNOWN edge cases |
| PB-LD03 | Manual Ndarja Lineare.pdf | 7–8 | Negative endpoints place external points | L1000,-200mm:1:-200mm→−200,1200 | PointSet | T-P01 | VERIFIED source example |
| PB-LD04 | Manual Ndarja Lineare.pdf | 8–9 | Affine terms, unit suffix,$ variables, X/Y total | 1+100mm:1:1+50mm;1:2*($a+$b)mm | Expression/Division | T-P02 | VERIFIED; proposed safe parser |
| PB-LD05 | Manual Ndarja Lineare.pdf | 8 | Trigonometric functions use radians; exponent token absent | sin(pi/2); athan printed | Expression | T-P03 | VERIFIED list; UNKNOWN exponent/token acceptance |
| PB-LD06 | Manual Ndarja Lineare.pdf | 9–10 | Descriptor if/default with bounded intervals | x<=300;300<x<=500; default | Descriptor parser | T-P04 | VERIFIED example; UNKNOWN arbitrary overlap precedence |
| PB-LD07 | Manual Ndarja Lineare.pdf | 11–12 | Panel face references change measured division | 500 center references; prose487.3 vs figure474.7 | Reference Resolver | T-P05 | UNKNOWN conflict on p12; no single expected imos answer |
| PB-MP01 | Manual Menaxhimi i Elementeve.pdf | 29–31 | Virtual reservation and part-local pointsets | 0:1:0;77mm:1:77mm;88mm:1:88mm | MultiPart/PointSet | T-P06 | VERIFIED; derived coordinates INFERRED |
| PB-MP02 | Manual per krijimin e dyerve.pdf | 1–5 | Physical children survive virtual support; band reference; point-count edits | ($A)mm:1:($A)mm; count changes require reconstruction | MultiPart | T-P07 | VERIFIED |
| PB-MP03 | Manual per krijimin e dyerve.pdf | 6–14 | Offset intersections, child contours, edge/report frames | positive inward offset; measurement frame separate | Geometry/BOM/Drawing | T-P08 | VERIFIED; matrix convention PROPOSED |
| PB-MAT01 | Manual Menaxhimi i Elementeve.pdf | 11,15,18,21 | Nominal vs finished substrate/surface/edge thickness | nominal19→finished18.5 example; finished stack equation INFERRED | Material | T-P09 | VERIFIED distinction |
| PB-MAT02 | Manual Menaxhimi i Elementeve.pdf | 17–23 | Band height vs thickness; component-local edges and grain | No universal four-edge/global-axis mapping | Material/Geometry | T-P10 | VERIFIED |
| PB-C01 | Manual Menaxhimi i Elementeve.pdf | 65–75 | Between/spanning/miter, shelf rails and contextual offsets | Cw=W−L−R only for selected between case | Construction Rules | T-B13, T-P11 | VERIFIED concepts; JP equations PROPOSED |
| PB-C02 | Manual Menaxhimi i Elementeve.pdf | 77–80 | Back setback inner/outer face; engagement and fit independent | back width=Cw+eL+eR (INFERRED rectangular case) | Back/Geometry | T-B15, T-P12 | VERIFIED choices; general angled algorithm UNKNOWN |
| PB-C03 | Manual Menaxhimi i Elementeve.pdf | 88–89,96–97,105,113 | Hinged/sliding/long-piece signs differ | Source-specific sign normalization | Construction/fronts | T-P13 | VERIFIED; original normalization |
| PB-C04 | Manual Menaxhimi i Elementeve.pdf | 121–128 | Automatic/manual reveal and article/order precedence | 3mm central gap→1.5mm each side | FrontLayout | T-P14 | VERIFIED |
| PB-DR01 | Manual Sirtaret.pdf | 5–7,11–16 | Manufactured/system/purchased, slide references, shared front | One real front may serve two interiors | Drawer/BOM | T-P15 | VERIFIED |
| PB-DR02 | Variablat e brendshme te Sirtareve ne Imos.pdf | 1 | Outside box containment except front; inside corner-anchor box | Safe-distance reduction; not usable-volume subtraction | Drawer | T-P16 | VERIFIED concept; full numeric transform UNKNOWN |
| PB-DR03 | Variablat e brendshme te Sirtareve ne Imos.pdf | 1,7,13 | Absent SL_DR_Y fallback | SL_DR_Y=-SL_FR only when absent | Drawer/Expression | T-P17 | VERIFIED; explicit0 distinct |
| PB-DR04 | Variablat e brendshme te Sirtareve ne Imos.pdf | 8–9 | System bottom/back roles and conditional depth reductions | bottom_depth=slide_length−resolved_reduction (INFERRED) | Drawer | T-P18 | VERIFIED cases; cross-field precedence UNKNOWN |
| PB-DR05 | Manual Sirtaret.pdf | 18–22 | Drawer-local perimeter, bottom joints, edge3=upper edge | Different finished-part relationships per joint | Drawer/Material | T-P19 | VERIFIED |
| PB-DR06 | Manual Sirtaret.pdf | 24–30 | Historical runner examples | Context-only source fixture; no global defaults | Drawer profiles | T-P20 | VERIFIED printed examples; current product data UNKNOWN |
| PB-TX01 | Manual per krijimin e texturave.pdf | 1–3 | Render principle applies to material/surface/edge; scale and image separate | Physical-mm scale mapping UNKNOWN | Material/UI | T-P21 | VERIFIED workflow |
| PB-MGR01 | Manual Manager.pdf | 9–10,19–28 | Editable bill-of-elements hierarchy differs from generated BOM | Authored OrderGroup vs BOMDocument | Project Manager/BOM | T-P22 | VERIFIED |
| PB-MGR02 | 00_Manager.pdf | 47,65–66,78–79 | Finished/raw sizes; measurement and edge1 frames; finish composition | 720×570×18 versus718.60×568.30×18 | Material/BOM/Drawing | T-P23 | VERIFIED example; per-edge deductions UNKNOWN |
| PB-MGR03 | Manual Manager.pdf | 89–91 | Global/project/occurrence edit scopes | Scoped recording with keep/replace intent | Project Manager/Library | T-P24 | VERIFIED; immutable versions PROPOSED |
| PB-LAY01 | Manual Skuadrim dhe Layout.pdf | 4–6,9–13 | Global/project templates and per-view settings | view-scale1:xx; hidden-line print per viewport | Layout | T-P25 | VERIFIED |
| PB-LAY02 | Manual Skuadrim dhe Layout.pdf | 6–9 | Fields bind selected piece data; some tags corrupt/undefined | Typed binding; no guessed tag evaluation | Metadata/Layout | T-P26 | VERIFIED concept; bad tags UNKNOWN |
| PB-LAY03 | Manual Skuadrim dhe Layout.pdf | 1–13 | No standalone vector/section/detail algorithm specification | JP projection/section/PDF design is original | Drawing/PDF | T-B26–T-B31 | PROPOSED JP enhancement, not absence claim about product |
| PB-FREE01 | Manual Ndertim i Lire.pdf | 4–27,28–37 | Linked plan/section, extrusion point and embedded article | Guide geometry ≠ finished material thickness | Geometry/Article | T-P27 | VERIFIED |
| PB-HW01 | Manual per futjen e dorezave.pdf | 2–6 | Visual asset transform independent from catalog alias | asset_local_transform composed once | Library/Hardware | T-P28 | VERIFIED concept; placement formulas UNKNOWN |
| PB-HW02 | Manual per futjen e kembeve.pdf | 2–4,7 | Below-panel display reference; no generic leg dimensions | Single semantic occurrence for display/BOM (PROPOSED) | Hardware | T-P29 | VERIFIED limited evidence; procedures excluded |
| PB-V-SL_DR_X | Variablat e brendshme te Sirtareve ne Imos.pdf | 1,6,13 | Distance from slide insertion to virtual inside-box insertion in X | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_DR_Y | Variablat e brendshme te Sirtareve ne Imos.pdf | 1,7,13 | Distance from slide insertion to virtual inside-box insertion in Y | absent→-SL_FR | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_DR_Z | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7,13 | Distance from slide insertion to virtual inside-box insertion in Z | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_BO | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7,13 | Distance from slide insertion to slide bottom edge | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_SE_BO | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7,13 | Safe distance from slide bottom to virtual outside-box bottom | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_H | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7 | Slide height | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_FR | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7,13 | Distance from slide insertion to slide front edge | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_SE_FR | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7,13 | Safe distance slide to virtual outside-box front edge | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_L | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7 | Drawer depth; Quadro adjusted example equals slide length | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-SL_EB | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,7 | Slide installation width; explanation slide width | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-DR_H | Variablat e brendshme te Sirtareve ne Imos.pdf | 2,8,14 | Frame height, formerly Drawer height; explanation Drawer height | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |
| PB-V-DR_TYP | Variablat e brendshme te Sirtareve ne Imos.pdf | 3,9–10,14 | Role enum SL, FP, BP, ZARGE, BS, SL+Zarge, BP_FITTING | No universal formula documented | Drawer/typed profile | T-B22 | VERIFIED meaning; numeric units/ranges UNKNOWN except enum |

## Non-PDF and project requirements

| ID | Requirement | Evidence / deliverable | Status |
|---|---|---|---|
| PB-R01 | Intended repository identified and preserved | User supplied Jurgen90Sia/JP_IMOS; GitHub empty-tree409; clone at C:\Users\arkitekt2\Documents\JPMOS; main/origin verified;01 | VERIFIED; no prior source to overwrite |
| PB-R02 | Retain prior GitHub/source/license audit |05 exact pinned commits retained;06 candidate permission/Ruby/dependency/integration table | VERIFIED audit scope; no production intake |
| PB-R03 | Safe parser and SketchUp2021 baseline |03 two-language AST proposal;06 rejects eval and current Dentaku;07 platform matrix retained | PROPOSED implementation; no tests falsely passed |
| PB-R04 | All 17 modules and one canonical model |08–10 revised contracts, submodels and data flow | PROPOSED architecture; source conflicts explicit |
| PB-R05 | No excluded manufacturing functionality |02,04,08–12; documentation-only source tree | Scope retained; no plugin or RBZ |
| PB-R06 | All 13 manuals actually inspected |01 inventory, hashes,555 pages and stated visual coverage | VERIFIED coverage; not all screenshots enlarged |
| PB-R07 | Small testable Phase2 backlog |12 tasksB01–B38 plus manual-derived test catalogue | PLANNED; not authorization to execute |
| PB-R08 | sq/en and millimeters | U1;07–09 | Requested scope / PROPOSED handling; source numeric units not silently guessed |
| PB-R09 | No Phase2 without approval | U1/U2;12/14 | Phase2 NOT STARTED |
| PB-R10 | Final PASS/PARTIAL/BLOCKED based on evidence |14 acceptance assessment | PARTIAL because unresolved formula/source/data contracts remain |

## Trace record maintenance

A future verified rule record must retain exact_filename, sha256, pdf_page_index, printed_folio, edition, classification, source conflict ID where applicable, and independent expected fixture. Source edition date does not establish current product compatibility. M03/M04 are translation/original of one manual and do not count as independent corroborating vendors.

The old blanket findings“all manuals unavailable” and“all requested drawer meanings unknown” are retired. Remaining UNKNOWN values are item-specific: Linear p12 conflict; exponent glyph; exact-fit repeat; arbitrary descriptor/rounding precedence; numeric unit/sign/frame contracts; conditional bottom-reduction precedence; source table defects; current manufacturer data. Source/code/host execution gaps are not silently promoted to VERIFIED.
