# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Feature evidence after Phase1B

The former blanket UNKNOWN/MISSING matrix is superseded. VERIFIED here means actual historical PDF evidence, not verified compatibility with a current imos build or SketchUp. JP schema/API/implementation remains PROPOSED unless an official-platform finding says otherwise.

| Feature | Evidence / exact PDF pages | Finding |
|---|---|---|
| Article envelopes, shaped geometry, three construction planes | Manual Artikull Parametrik.pdf pp. 4–6,18–20 | VERIFIED; LEFT-side elevation; excludes fronts/protruding shelves |
| Hierarchical child zones and nested reusable articles | Manual Artikull Parametrik.pdf pp. 37–50 | VERIFIED; zones can host articles with another construction orientation |
| Independent overlapping construction layers | Manual Artikull Parametrik.pdf pp. 51–52 | VERIFIED; a strict disjoint partition tree is insufficient |
| Physical/virtual divisions and two-side/angle/perpendicular orientation | Manual Artikull Parametrik.pdf pp. 37–43,53–61 | VERIFIED; context-specific division basis |
| Linear grammar, repeats, quantized intervals, negative endpoints and descriptors | Manual Ndarja Lineare.pdf pp. 5–12 | VERIFIED syntax families; precise unresolved boundaries listed in 03 |
| Part-local point lattice and MultiPart | Manual Menaxhimi i Elementeve.pdf pp. 29–42; Manual per krijimin e dyerve.pdf pp. 1–16 | VERIFIED; point sets are not cabinet compartments |
| Raw material + surfaces + edge → characteristic → construction principle | Manual Menaxhimi i Elementeve.pdf pp. 7–24 | VERIFIED layering, with nominal vs finished thickness |
| Shelves, sides, backs, hinged/sliding fronts and long pieces | Manual Menaxhimi i Elementeve.pdf pp. 65–119 | VERIFIED contextual rules; no universal sign/rectangle formula |
| Automatic/manual reveal and override precedence | Manual Menaxhimi i Elementeve.pdf pp. 121–128; Manual Artikull Parametrik.pdf pp. 12,31,62–74 | VERIFIED; field/mode/neighbor-specific |
| Drawer types, references, joined front and component rules | Manual Sirtaret.pdf pp. 5–22 | VERIFIED; system/purchased/manufactured branches |
| Drawer boxes and variable meanings | Variablat e brendshme te Sirtareve ne Imos.pdf pp. 1–20 | VERIFIED semantics; units/sign/default gaps remain UNKNOWN |
| Material/edge/finish dimensions and reporting | Manual Menaxhimi i Elementeve.pdf pp. 11–23;00_Manager.pdf pp. 47,79 | VERIFIED physical stack and finished/raw split |
| Texture/render principle | Manual per krijimin e texturave.pdf pp. 1–3 | VERIFIED; does not establish mm texture-scale units |
| Editable bill-of-elements hierarchy and source-scoped edits | Manual Manager.pdf pp. 9–10,19–28,89–91;00_Manager.pdf same pages | VERIFIED; not just derived BOM |
| Handles/legs display asset/reference | Manual per futjen e dorezave.pdf pp. 2–6; Manual per futjen e kembeve.pdf pp. 2–4,7 | VERIFIED limited scope; no general dimension catalog |
| Free construction from linked plan and section | Manual Ndertim i Lire.pdf pp. 4–37 | VERIFIED; selected guide geometry does not override finished thickness |
| Templates, source-bound attributes, multiple viewports, per-view print visibility | Manual Skuadrim dhe Layout.pdf pp. 4–13 | VERIFIED |
| Standalone six-view vector scene, section/detail algorithms, hatching, multi-sheet A4–A0 PDF | U1§9; no such algorithm specification in M13 | PROPOSED JP design; not promoted to imos evidence |
| sq/en interface, SketchUp2021–2026, canonical snapshots | U1§§1,11–12; official API audit07 | VERIFIED requested scope / PROPOSED implementation |
| Drilling/CNC/CAM/nesting/toolpaths/postprocessors | U1/U2 exclusions; manuals contain excluded chapters | EXCLUDED regardless of manual support |

## Detailed Article Designer evidence

| Finding | Exact source PDF | PDF page(s) | Classification | Behavior / architecture implication | Proposed module | Planned Test ID |
|---|---|---|---|---|---|---|
| AD01 | Manual Artikull Parametrik.pdf | 4–6 | VERIFIED | Article Designer supports regular/shaped plan, front-elevation and LEFT-side-elevation geometry; article envelope is side-panel extent, excluding doors, drawer fronts and protruding shelves. | Article Designer / Geometry | T-A01 |
| AD02 | Manual Artikull Parametrik.pdf | 6–9,44–50 | VERIFIED | Tree selection exposes article/zone/element settings; adding dividers creates child zones; zones accept nested saved articles or prefinished objects. | Zone Hierarchy / Library | T-A02 |
| AD03 | Manual Artikull Parametrik.pdf | 12,18 | VERIFIED | Article-stored front clearance overrides current project construction-mode clearance. Active zone production-information override takes priority over the selected construction principle. | Construction Rules / BOM metadata | T-A03 |
| AD04 | Manual Artikull Parametrik.pdf | 13–14 | VERIFIED | C-shaped constructions use a shared side; intermediate/terminal classification affects adjoining fronts. Machining transfer is excluded. | Assembly / adjacency resolver | T-A04 |
| AD05 | Manual Artikull Parametrik.pdf | 14 | VERIFIED | Dimension formula 1[300]mm constrains dimension changes to multiples of 300mm; that dimension's direct input is disabled. | Expression / dimension constraints | T-A05 |
| AD06 | Manual Artikull Parametrik.pdf | 18–20 | VERIFIED | Piece-characteristic outline applies to shelves in plan, doors/backs in front elevation and sides in left-side elevation. | Geometry / orientation mapping | T-A06 |
| AD07 | Manual Artikull Parametrik.pdf | 21–26 | VERIFIED | Copy-with-alignment reorients copied zones to target division-reference side. Division1 reference also determines a nested article's front orientation. Edge1 determines counterclockwise edge sequence; drawing X reference is separately selected. | Zone frames / semantic edges / Drawing | T-A07 |
| AD08 | Manual Artikull Parametrik.pdf | 27–36 | VERIFIED | Junction roles include long/short butt, angular and perpendicular; unequal thickness can produce non45-degree angular joints. Positive/negative projections are field-specific; local-zone versus descendant-zone insertions have different scope. | Construction Rules | T-A08 |
| AD09 | Manual Artikull Parametrik.pdf | 37–43 | VERIFIED | Vertical division creates horizontal shelves; horizontal division creates side panels. Virtual dividers support other elements without creating a real part. Division orientation can use two perimeter-side distributions, angle, or perpendicular reference. | Zone / analytic geometry | T-A09 |
| AD10 | Manual Artikull Parametrik.pdf | 43 | VERIFIED | For 420mm:1, Zona measures from outer geometry extent; Pezzo starts inside the side-panel thickness. | Division reference policy | T-A10 |
| AD11 | Manual Artikull Parametrik.pdf | 44–52 | VERIFIED | Child zones can be independently equipped/copied. Independent division creates multiple overlapping construction layers in one parent to combine shelves and sides. | Zone layers / collision policies | T-A11 |
| AD12 | Manual Artikull Parametrik.pdf | 53–55 | VERIFIED | Front-elevation internal backs can be physical or virtual; depth division is ordered BACK TO FRONT. With1:2, rear zone is the shallower zone. | Zone axis direction / back rules | T-A12 |
| AD13 | Manual Artikull Parametrik.pdf | 57–61 | VERIFIED | Front frame members can attach to physical or virtual dividers; changing the divider moves its associated frame member. Left-side elevation includes side and shelf subdivisions. | Construction dependency anchors | T-A13 |
| AD14 | Manual Artikull Parametrik.pdf | 62–66 | VERIFIED | Automatic drawer-front clearance mode treats division as front heights; manual mode includes clearance intervals explicitly. The manual example fixes first front250mm and keeps three remaining front heights equal. | Front layout / Division | T-A14 |
| AD15 | Manual Artikull Parametrik.pdf | 67–70 | VERIFIED | Lateral clearance references can be outer/inner/center; front/back/left/right drawer setbacks are separate. Interchangeable drawers retain one front-bottom to box-bottom distance. Example runner lengths are source examples, not universal profiles. | Drawer / anchors | T-A15 |
| AD16 | Manual Artikull Parametrik.pdf | 71–74 | VERIFIED | Front layout can be independent of internal shelves. Example manual sequence is2mm,400mm,4mm,600mm,4mm,1,2mm. Double-door auto/manual clearance selects different source settings. | Door / FrontLayout | T-A16 |
| AD17 | Manual Artikull Parametrik.pdf | 78–83 | VERIFIED | Frame members occupy opening space; doors and optionally drawers adapt to the frame's internal zone. | FrameEnvelope / opening resolver | T-A17 |
| AD18 | Manual Artikull Parametrik.pdf | 83–85 | VERIFIED | Plinth placement distinguishes inside sides versus below them; article-height policy can include or add external plinth height; height source is rule/project/fixed. | Assembly / plinth rule | T-A18 |
| AD19 | Manual Artikull Parametrik.pdf | 85–90 | VERIFIED | Remaining chapter concerns drilling-row behavior; reviewed for scope only and excluded entirely from JP implementation. | Exclusion boundary | T-A19 |

## Article → Zone → SubZone → ConstructionElement → PhysicalPart

VERIFIED conceptual hierarchy: article/zone/component settings and nested zone creation are shown in Manual Artikull Parametrik.pdf pp. 6,37–50. PROPOSED canonical representation: SubZone is a Zone with a parent; a construction element generates zero or many physical parts. Independent-layer zones may occupy the same parent volume (same PDF51–52). A MultiPart reservation may have a virtual support and real physical children (Manual Menaxhimi i Elementeve.pdf pp. 29; Manual per krijimin e dyerve.pdf pp. 1). Therefore zero support geometry must not suppress descendants.

Proposed UUIDs, immutable revisions, regeneration rollback and cross-output snapshots are JP design choices. The Manager manual actually limits historical undo (Manual Manager.pdf pp. 6;00_Manager.pdf pp. 6); JP atomic undo is an enhancement, not a copied behavior.

## Remaining evidence questions

No precise current product build is established; the 2009 and 2020/2025 documents are separate historical contexts. Repeat exact-fit behavior, contradictory Linear p12 output, malformed/missing exponent token, some descriptor evaluation rules, screenshot-only numeric presets and manufacturer-profile compatibility remain unresolved. See03,04,11 and 13 for classified records; no blanket missing-manual statements remain.
