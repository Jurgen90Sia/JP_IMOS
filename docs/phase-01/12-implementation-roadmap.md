# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## JP IMOS PRO Phase2 backlog — research deliverable only

**Goal:** plan a small original furniture-core slice and its later material, front, drawer, drawing outputs without starting implementation.

**Architecture:** pure Ruby domain contracts, typed/affine expression grammars, explicit construction references, immutable snapshot and thin host/output adapters. Exact contracts are in [08](08-system-architecture.md),[09](09-data-model.md),[10](10-module-dependencies.md).

**Tech stack:** Ruby2.7-compatible shared syntax; separately qualified Ruby3.2/current-host environments; HTML/JavaScript targeted to oldest retained CEF; no final third-party runtime dependency approved.

**Execution gate:** this is a proposed backlog, not an approved execution plan. No Phase2 task is started. At future approved execution, follow the applicable executing-plans or subagent-driven-development workflow. User-specified location `docs/phase-01/` replaces skill-default plan path.

## Global constraints and file structure

Repository is the exact user-supplied JP_IMOS checkout inC:\Users\arkitekt2\Documents\JPMOS. Current repository contains only documentation after this phase. Paths below are **proposed future files**, not existing code. Reconcile naming with subsequent approved repository conventions before writing them.

Keep pure domain files inlib/jp_imos_pro/{core, expression, division, zones, construction, geometry, materials, drawers, bom, library, project, drawing, layout, hardware}; host files in adapters/sketchup; separate test/core and test/host; UI inui. One responsibility per file. No runtime gem installation from user sessions, no eval/user-code callbacks, no machine-processing modules.

Internal unitsmm; UI sq/en; target desktop SketchUp2021–2026. Source numeric field units that remain UNKNOWN cannot be imported by guessing. Refer to13's exact-page evidence and source-conflict statuses before adopting historical syntax.

## Remaining Phase1B closure tasks

| Closure | Required evidence | Current state |
|---|---|---|
| Exact Linear p12 behavior | Authoritative correction or observed historical/source product behavior distinguishes487.3 versus474.7 | OPEN; both source values retained |
| Extended grammar policies | Exact-fit n*, off-grid quantization, descriptor overlaps, exponent/misspelled function token | OPEN; source-compatible demonstrated cases can be planned separately |
| Drawer numeric/profile contract | Unit/sign/origin/range and system selection/conditional-precedence data | PARTIAL; all 12 meanings now source-cited |
| Distribution/PDF/font/host decisions | License route, transitive pins, font manifest, exact host/OS matrix | OPEN future approval/data gates |

The intended repository and all 13 manual files are identified; they are no longer closure blockers.

## Task cycle and independent acceptance

Each row is one independently reviewable deliverable with a stated interface. At future execution:
- [ ] Write the listed focused failing test, with an independent expected result from cited evidence or explicit JP proposal.
- [ ] Run it and observe a relevant failure before implementation.
- [ ] Implement only that contract and minimal necessary setup.
- [ ] Run the focused test and affected checks; inspect actual results.
- [ ] Review and commit that small unit.

For pure Ruby paths, use `ruby -Itest test/<area>/<name>_test.rb` matching the concrete file below after harness setup. Passing means zero failures plus listed assertions, with Ruby version captured. Host launch/UI runner commands depend on installed validated tooling, not an invented command. T-B18/B19/B25/B32 require actual SketchUp/CEF runs. No planned test below has been executed as a plugin test.

| Task | Independently testable deliverable | Proposed files | Interface | Depends on | Test ID / concrete expected behavior | Gate/status |
|---|---|---|---|---|---|---|
| B01 | Document schema round trip | schema/project.schema.json; test/core/project_schema_test.rb | ProjectDocument → validated document | none | T-B01: round-trip finite mm values; reject duplicate IDs, NaN/nonfinite inputs and newer schema without losing old data | Proposed core; approval and repo gate |
| B02 | Typed quantity operations | lib/jp_imos_pro/core/quantity.rb; test/core/quantity_test.rb | Length/Scalar/Boolean values → typed result | B01 | T-B02: 600mm−2×18mm=564mm; Length+Scalar rejected; divide-by-zero diagnostic | Proposed core |
| B03 | Expression lexer | lib/jp_imos_pro/expression/lexer.rb; test/expression/lexer_test.rb | source:string → bounded token stream with spans | B02 | T-B03: mm literals and operators tokenize; 4097-character expression fails before evaluation; Ruby interpolation/method syntax rejected | Proposed grammar only |
| B04 | Typed expression AST | lib/jp_imos_pro/expression/parser.rb; test/expression/parser_test.rb | tokens → immutable typed AST | B03 | T-B04: arithmetic precedence, parentheses and unary minus; malformed token sequence reports exact span | Proposed grammar only |
| B05 | Restricted evaluator | lib/jp_imos_pro/expression/evaluator.rb; test/expression/evaluator_test.rb | AST + symbol table + budget → TypedValue/diagnostic | B04 | T-B05: lazy if does not evaluate unused divide-by-zero branch; unknown symbols fail; node/depth/step caps enforced; no code-execution path | Proposed grammar only |
| B06 | Global dependency scheduler | lib/jp_imos_pro/core/dependency_graph.rb; test/core/dependency_graph_test.rb | typed parameter/anchor graph → ordered values | B05 | T-B06: self and two-node cycles report IDs; shelf uses analytic drawer-envelope anchor; generated-face feedback rejected | Proposed original scheduler |
| B07 | Fixed/weighted interval allocation | lib/jp_imos_pro/division/allocator.rb; test/division/allocator_test.rb | typed tokens + span_mm → intervals/boundary IDs | B02 | T-B07: span600 with [77mm, weight1,77mm] gives 77/446/77; 153 span rejected; zero-marker identities retained | Proposed semantics; imos compatibility blocked on M05 |
| B08 | Documented division grammar adapter | lib/jp_imos_pro/division/imos_grammar_adapter.rb; test/division/manual_vectors_test.rb | verified manual syntax → typed DivisionSpec | B07; documented LD01–LD12 | T-B08: each cited fixed/proportional/mixed/repeated/negative/conditional example agrees with exact page-derived expectation | PARTIAL source contract: exact-fit/exponent/conflict cases must diagnose |
| B09 | Orientation and rigid frames | lib/jp_imos_pro/core/frame.rb; test/core/frame_test.rb | origin/basis + local point → world point | B02 | T-B09: parent-child composition; valid right-handed frames; singular/sheared placement rejected | Proposed conventions; manual orientation mapping blocked |
| B10 | Zone tree and reservations | lib/jp_imos_pro/zones/resolver.rb; test/zones/resolver_test.rb | ZoneSpec + parent span + reservations → ZoneSnapshot | B06, B07, B09 | T-B10: 600 span−18−18=564 clear; nested child contained; center/near/far reservation consumed exactly once | Proposed rule policy; documented mapping pending |
| B11 | Construction rule boundary | lib/jp_imos_pro/construction/dispatcher.rb; test/construction/dispatcher_test.rb | ConstructionRequest → recipes/diagnostics | B10 | T-B11: no host entities or ready-made PartSpecs emitted; unsupported principle fails without fallback | Proposed core |
| B12 | Finished material/surface/edge context | lib/jp_imos_pro/materials/context_resolver.rb; test/materials/context_test.rb | characteristic + finished stack policy → dimensional material/face/edge inputs | B01, B02 | T-B12/T-P09: nominal19 vs finished18.5 retained; dimensional face layers affect geometry once; texture-only changes do not; ambiguous total/substrate override fails | Evidence available; JP stack formalization PROPOSED |
| B13 | Rectangular carcass principle | lib/jp_imos_pro/construction/carcass_rule.rb; test/construction/carcass_rule_test.rb | resolved envelope/thickness → panel recipes | B11, B12 | T-B13: W600, H720, D560 with 18mm sides/top/bottom gives top/bottom width564 and inner height684; all corners in envelope | Proposed selected butt-joint principle |
| B14 | Canonical extrusion geometry | lib/jp_imos_pro/geometry/extrusion.rb; test/geometry/extrusion_test.rb | contour/holes + thickness + frame → PartSpec | B09, B11 | T-B14: outer600×300, inner100×100, t18 volume=(180000−10000)×18=3060000mm³; winding/hole mapping stable | Proposed solid core |
| B15 | Back-panel fit and groove geometry | lib/jp_imos_pro/construction/back_rule.rb; test/construction/back_rule_test.rb | BackConstructionSpec → part/reservation/recess geometry | B11, B14; Elements77–80 evidence | T-B15: cited inset/rebate/groove examples reproduce back size, seating and clear depth; no tool/drilling output generated | Documented reference/fit choices available; arbitrary angled solver UNKNOWN |
| B16 | Virtual elements and MultiPart | lib/jp_imos_pro/construction/assembly_rule.rb; test/construction/assembly_test.rb | assembly/virtual reservations → occurrences/recipes | B10, B11 | T-B16/T-P07: reservation affects neighbors once; omitted support contributes0 while real rail survives; recursive membership rejected | Proposed behavior; manual equivalence pending |
| B17 | Semantic edges and allowances | lib/jp_imos_pro/materials/edge_allowance.rb; test/materials/edge_allowance_test.rb | declared segment keys + band policy → substrate contour | B12, B14 | T-B17: finished600×300, 1mm band on opposing X ends gives substrate598×300 under subtract policy; decorative-only policy retains600; missing segment fails | Proposed explicit allowance policy |
| B18 | Atomic SketchUp apply | lib/jp_imos_pro/adapters/sketchup/apply.rb; test/host/TC_Apply.rb | CandidateRevision + mapping → ApplyResult | B13, B14, B17 | T-B18: one resize is one undo; injected geometry failure restores prior geometry and stored canonical revision in actual SketchUp2021 | Host required; NOT RUN |
| B19 | Undo/redo and reopen sync | lib/jp_imos_pro/adapters/sketchup/sync.rb; test/host/TC_Sync.rb | host events → restored document/mapping/cache invalidation | B18 | T-B19: undo/redo/save/reopen preserve matching visible/export revision; initial creation undo removes managed-project state; exports suspended during sync | Host required; NOT RUN |
| B20 | BOM physical occurrence aggregation | lib/jp_imos_pro/bom/aggregator.rb; test/bom/aggregator_test.rb | Snapshot + grouping policy → BOMDocument | B16, B17 | T-B20: two article occurrences double quantities; virtual items absent; different grain/band treatments do not merge; missing density gives unknown mass | Proposed BOM policy |
| B21 | Doors and fronts | lib/jp_imos_pro/construction/front_rule.rb; test/construction/front_rule_test.rb | opening/overlays/reveals → front recipes | B11, B16 | T-B21: explicitly chosen opening600, two leaves, 2mm gaps at each outside and center gives leaf297; impossible reveal budget fails | Proposed rule; M09 required for documented behavior |
| B22 | Drawer variable source mapping | data/drawer_profiles/schema.json; test/drawers/profile_contract_test.rb | cited external variable definitions → typed profile | B01; variables PDF1–17 | T-B22: all 12 meanings/page refs; preserve absent vs0; do not import unproven numeric units; typed mapping required before system-profile use | Meanings available; numeric unit/sign/profile contract PARTIAL |
| B23 | Generic drawer assembly | lib/jp_imos_pro/drawers/box_rule.rb; test/drawers/box_rule_test.rb | opening + explicit sourced inputs → box/front recipes | B11, B14, B22 | T-B23: independent supplied allowances produce expected box envelope; negative clear space and incompatible bottom seating rejected; no manufacturer fallback | System-profile numeric mapping gate; no manufacturer defaults |
| B24 | Library definition versions | lib/jp_imos_pro/library/resolver.rb; test/library/resolver_test.rb | definition ref + occurrence inputs → immutable definition | B01, B16 | T-B24: recursive subarticle reference rejected; old saved project retains old library version; new occurrence gets new ID | Proposed core |
| B25 | Bilingual bridge and UI validation | ui/bridge.js; ui/locales/sq.json; ui/locales/en.json; test/ui/bridge.test.js | EditCommand ↔ explicit revisioned response | B01, B18 | T-B25: stale revision rejected; reopened dialog rebinds; serialized labels preserve ë/ç; locale numeric widget normalizes before expression parsing | Oldest/newest CEF host check required |
| B26 | Six orthographic vector views | lib/jp_imos_pro/drawing/projector.rb; test/drawing/projection_test.rb | Snapshot + explicit view basis → vector primitives | B14 | T-B26: known box projects to600×720 front and 560×720 side in model mm; axes/labels agree with frame convention | Proposed standalone drawing |
| B27 | Hidden edge classification | lib/jp_imos_pro/drawing/occlusion.rb; test/drawing/occlusion_test.rb | projected faces + edges → visible/hidden intervals | B26 | T-B27: foreground face hides only covered edge interval; coplanar duplicates resolve deterministically; silhouette retained | Proposed algorithm |
| B28 | Section loops and hatching | lib/jp_imos_pro/drawing/section.rb; test/drawing/section_test.rb | canonical solids + plane → loops/holes/hatch primitives | B14, B26 | T-B28: section through through-hole retains inner loop; hatch clipped outside hole; seating recess appears in section without machining records | Proposed drawing; depends on B15 for groove fixture |
| B29 | Associative dimensions and details | lib/jp_imos_pro/drawing/annotations.rb; test/drawing/annotations_test.rb | semantic anchors + view/detail spec → annotation primitives | B26 | T-B29: 600mm dimension displays600 at 1:10 and 1:20; deleted anchor reports dangling reference; detail uses own scale | Proposed drawing |
| B30 | Paper layout and title fields | lib/jp_imos_pro/layout/composer.rb; test/layout/composer_test.rb | DrawingDocument + SheetSet → paper-mm scene | B26, B29 | T-B30: A4 portrait210×297; A0 landscape1189×841; 600mm at 1:10 occupies60mm; missing title value flagged; viewport overflow diagnosed | Proposed templates; M13 behavior unverified |
| B31 | Vector PDF backend intake and serialization | lib/jp_imos_pro/export/pdf_serializer.rb; test/export/pdf_test.rb; docs/dependencies/pdf-intake.md | paper scene + vetted font manifest → PDF bytes | B30; approved G07 alternative/closure | T-B31: inspect PDF line/text operators and page boxes; Unicode searchable text; no full-page raster substitution; missing font fails clearly | HOLD: dependency/font license and Ruby2.7 execution |
| B32 | Cross-output consistency qualification | test/integration/cabinet_revision_test.rb; test/host/TC_Qualification.rb | accepted snapshot → geometry/BOM/drawing/PDF comparisons | B19, B20, B25, B27, B28, B31 | T-B32: same revision in every output; independent dimensional reconciliation; logs show exact SketchUp/Ruby/CEF builds for each target host | Future release gate; NOT RUN |
| B33 | Reference envelopes and independent zone layers | lib/jp_imos_pro/zones/layer_resolver.rb; test/zones/layer_test.rb | reference carcass + partition/layer specs → ZoneSnapshot | B10, B13 | T-B33/T-A01/T-A11: adding exterior front leaves carcassD unchanged; two coextensive layers allowed while unintended physical intersections diagnose | VERIFIED source concepts; JP implementation PLANNED |
| B34 | MultiPart pointset dependencies | lib/jp_imos_pro/geometry/pointset_resolver.rb; test/geometry/pointset_test.rb | axis division specs + contour references → stable pointset/recipes | B07, B09, B16 | T-B34/T-P06–P08:77/88 fixed bands remain; zero endpoint points valid; dependent point deletion blocks; changed count diagnosed | Exact-fit repetition UNKNOWN case stays gated |
| B35 | Authored grouping and scoped recording | lib/jp_imos_pro/project/recording.rb; test/project/recording_test.rb | OrderGroup + RecordingIntent → new scoped candidate | B01, B24 | T-B35/T-P22/T-P24: four groups reorganize without quantity change; occurrence/project/global targets distinct; keep/replace explicit | No historical storage implementation assumed |
| B36 | Scoped template/field resolution | lib/jp_imos_pro/layout/field_resolver.rb; test/layout/field_resolver_test.rb | TitleFieldBinding + snapshot + template scope → typed values | B01, B30 | T-B36/T-P25/T-P26: part material binding resolves exactsource; bad tag errors; project edit leaves global template; viewport policies independent | Malformed proprietary tags are not executable |
| B37 | Visual hardware asset transforms | lib/jp_imos_pro/hardware/asset_placement.rb; test/hardware/asset_placement_test.rb | visual_asset_ref + local correction + anchor → occurrence | B09, B16, B24 | T-B37/T-P28/T-P29: origin correction composed once; leg below finishedpanel; one physical quantity despite proxies/catalogaliases | Visual/BOM only; no machining payload |
| B38 | Measurement frame and report geometry | lib/jp_imos_pro/geometry/measurement_frame.rb; test/geometry/measurement_frame_test.rb | PartSpec + selected report frame → reporting dimensions | B14, B17, B20, B26 | T-B38/T-P08/T-P23: rotated/shape measurement frame changes reported bbox/edge extents and drawingorientation, not actualvolume; finished/raw labels retained | Original frame representation; source concepts verified |

## Manual-derived fixture catalogue

These detailed scenarios supplement the task tests; they do not duplicate implementation or constitute passed checks. Every fixture retains the source locators in 13 and must state when its numerical result is derived rather than printed.

| Test ID | Scenario | Independent expected contract |
|---|---|---|
| T-P01 | External points | L1000,-200mm:1:-200mm gives−200/1200; physical interval validator remains separate |
| T-P02 | Affine division and units | L600 terms1+100mm:1:1+50mm→250/150/200;8/4→weight2 vs8/4mm→length2; not arbitrary Ruby |
| T-P03 | Function token provenance | Radian trig allowed; missing exponent token and unverified athan spelling produce compatibility diagnostics |
| T-P04 | Descriptor boundaries | Printed example at 300 selects first condition, at 500 second; ambiguous new overlaps rejected by JP policy |
| T-P05 | Reference and source-conflict fixture | Keep500 center-reference fixture; flag474.7/487.3 conflict as unresolved rather than making both pass |
| T-P06 | MultiPart point lattice | AtL600,77 frame points77/523;88 frame88/512;0:1:0 makes boundary points; no zone-thickness deduction |
| T-P07 | Virtual support / child identity | Reservation changes neighboring fit; support hidden/absent does not remove rail/physical children; point-count change diagnostic |
| T-P08 | Measurement frame | Rotate/Y-flip pointset child edge mapping; bounding-box report dimensions do not change actual solid volume |
| T-P09 | Finished dimensional stack | Nominal19/finished18.5 remains distinct; add explicit face layers early; texture-only change does not resize |
| T-P10 | Physical finish compatibility | Band height/thickness, finished-layer material-list inclusion and per-surface grain remain independent |
| T-P11 | Shelf/context variants | Between/spanning/angular and rail alternatives; unsupported nonparallel case fails explicitly; field-specific signs |
| T-P12 | Back faces and geometric fit | Setback inner/outer differs by finished back thickness; engagement differs from receiving recess fit allowance |
| T-P13 | Sign normalization | Shelf/hinged/sliding/long-piece source fields map intended direction once, not by common label |
| T-P14 | Reveal precedence | 3 central gives1.5/1.5; article policy beats order; auto-off preserves manual; divider-as-exterior changes only selected neighbor policy |
| T-P15 | Drawer branches/shared front | Two interiors share one counted physical front; system/purchased/manufactured recipes remain separate |
| T-P16 | Boxes | Outside safe envelope contains interior/connectors except front; inside anchor-box not automatic storage volume |
| T-P17 | Absence fallback | SL_FR37 with missingSL_DR_Y→−37; explicit0 stays0; unknown units produce unresolved import diagnostic |
| T-P18 | Bottom reductions | Single/both-purchased-member cases each deduct once; unsupported competing fields fail; no generic opening−2*SL_EB shortcut |
| T-P19 | Drawer edging | Source drawer-side upper edge3 maps to named semantic edge; bottom joint selection changes geometry |
| T-P20 | Historical profiles | Runnerexample remains scoped to identified historicalsystem; changing system cannot reuse those allowances silently |
| T-P21 | Texture | Image/reflectivity/render scale cannot supply missing geometric thickness; unknown imported scale units preserved |
| T-P22 | Order grouping | Four groups organized into article without new physical quantity; hide/show independent from BOM inclusion |
| T-P23 | Raw/finished/edge sequence | 720×570×18 and 718.60×568.30×18 remain separately labeled; split edge preserves intended band assignment |
| T-P24 | Scoped edits | Occurrence/project/global changes have separate targets and keep/replace intent; global publish makes new JP version |
| T-P25 | Template/view scopes | Project-only title change does not mutate global template; four viewports keep independent scale/print visibility |
| T-P26 | Bound title metadata | Selected part supplies material/edge data; unknown tag and missing source ID diagnose; no executable expression |
| T-P27 | Linked free construction | Plan/section profiles retain insertion point and finished stack; guide lines cannot override material |
| T-P28 | Handle alias/asset | Cloned catalog variant does not mutate shared asset unexpectedly; nonzero visual origin correction composed once |
| T-P29 | Leg visual reference | Visual placement remains below selected finished panel face for two thicknesses; one physical BOM quantity; no drilling assertions |

Article fixturesT-A01–T-A19 are defined in 02's evidence table and map to tasksB09–B13, B21, B23, B24, B33–B34. They include left-side orientation, carcass versus overall envelope, copy-with-alignment, outer/inner reference, independent layers, back-to-front zone ordering, manual front-clearance sequences and plinth-height inclusion. T-A19 is a scope-only exclusion check, not a drilling test.

## Review focus

Highest-risk cross-task failures: source-conflicted reference math(B08/B10), finished layer/band double deduction(B12/B17), stale snapshot after undo(B19/B32), shared front or proxy double quantity(B16/B20/B37), and PDF glyph/scale loss(B29–B31). The table assigns observable acceptance to each. Unit test doubles cannot certify native geometry, CEF callbacks or vectorPDF quality.

## Suggested approval slices

Initial core/host slice: B01–B07, B09–B14, B17–B19, plus B33's envelope/layer contract when needed for the selected example. Establish one original rectangular carcass and reliable resize/undo before broader libraries. Documented grammar importB08 and system-profileB22–B23 remain limited by explicit source contracts, not guessed defaults.

Materials/BOM/front/library slice follows stable physical identities. Drawing tasksB26–B31 can be scheduled separately after model/anchor contracts are accepted. B32 is cross-output qualification after those outputs exist. No calendar/effort promise or automatic Phase2 start is made.
