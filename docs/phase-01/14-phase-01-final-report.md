# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Executive summary and decision

**Phase1B: PARTIAL.** The original missing-file and repository-identification blockers are removed. All 13 requested manuals were actually read, totalling555 PDF pages, with relevant tables/formulas/diagrams and sparse pages reviewed. Historical behavior now has exact filename/page traceability. Item-specific source contradictions and incomplete formula/unit/selection contracts remain explicitly UNKNOWN.

The intended repository is [Jurgen90Sia/JP_IMOS](https://github.com/Jurgen90Sia/JP_IMOS), supplied directly by the user. It was empty, no license/source/tests/dependencies; cloned to `C:\Users\arkitekt2\Documents\JPMOS` with active/default main and exact origin URL. Documentation is prepared under its `docs/phase-01/`. No unrelated repository was created and no existing source was overwritten.

No production plugin code, RBZ, runtime dependency install or excluded manufacturing feature was written. Phase2 has not started.

## Source coverage

| Source | Phase1B result | Limits |
|---|---|---|
| Requested13 PDFs |13/13 available;555/555 indexed pages read | Relevant/sample visual checks as recorded in 01; not every screenshot individually enlarged |
| Manager editions |94-page Italian original and 94-page English translation | Same underlying manual, not independent vendor confirmation |
| Other source-folder PDFs |20 additional names observed | Not part of requested13-file audit; not counted as reviewed |
| Existing GitHub audit |Six requested plus four additional candidates retained | Targeted source audit, not a transitive security/license certification |
| Reuse candidates |Pinned G03–G07 license/manifests andG10 gemspec rechecked | No candidate installed/tested or final runtime dependency approved |
| Intended repository |Identified, empty repository state checked, local clone connected | No implementation or host tests exist |

Inventory01 records exact filenames, page counts, languages, chapter ranges, quality/sparse-page notes and SHA-256. The filenames' Albanian labels do not describe actual prose language: sources are Italian and English, multiple historical editions from 2009 to2025. None proves a current installed imos build.

## Research findings and corrections

- Article dimensions are carcass/reference dimensions, excluding fronts and protruding shelves. Construction reference is plan/front/LEFT-side elevation; nested articles can use a different reference. Independent zones can be overlapping construction layers.
- Division grammar supports fixed/weighted/affine terms, repetition, quantization, negative external points and descriptor conditions. A part-local point lattice is distinct from cabinet compartment division.0:1:0 and 77/88mm examples now have actual MultiPart evidence.
- Panel references matter: outer/inner/center faces change physical coordinates. Nominal purchased material thickness differs from finished substrate/surface/edge thickness; dimensional layers resolve before geometry.
- Back setback may reference inner or outer face; engagement, receiving-fit allowances and back size are distinct. Offset signs differ by component/field family.
- Virtual MultiPart reservation does not mean no physical descendants. Drawer inside box is a construction-anchor box, not usable storage; outside-box containment exempts the front.
- All 12 requested drawer variables now have source-cited meanings; absentSL_DR_Y=-SL_FR is documented. Numeric table units/global sign/frame contracts are not fully documented and are not guessed. Shared fronts and manufactured/system/purchased drawers need separate representation.
- Editable organizational bill-of-elements differs from generated BOM. Definition/project/occurrence edit scopes, source-bound title fields and per-viewport print settings are explicit.
- Standalone vector PDF, sections/details/hatching algorithms, canonical JSON, UUIDs and atomic rollback remain original JP proposals. Manuals establish workflows, not those implementation algorithms.

These findings are integrated into02–04 and 08–10. No contradictory parallel architecture document is introduced.

## Unresolved evidence

1. **Manual Ndarja Lineare.pdf pp. 12:** prose487.3mm versus screenshot474.7mm. Derivations explaining each are labeled INFERRED; no single historical expected result is asserted.
2. **Same PDF8:** exponent operator token is missing in rendered source; athan is printed but its runtime acceptance is unknown.
3. Repeat exact-fit termination, arbitrary quantization rounding and descriptor overlap/error precedence are incompletely specified (same PDF6–10).
4. Drawer numeric units/origins/signs, ranges, discrete height/depth selection and conflicting bottom-reduction precedence need authoritative profile/runtime evidence (Manual Sirtaret.pdf pp. 11–14; variables PDF1–17).
5. Some translated labels, title-field tags and long-piece max-length prose are ambiguous. Current manufacturer data and product-build compatibility are not established.
6. Full PDF/font/transitive license intake and six-version real SketchUp qualification remain future work, not falsely passed Phase1B tests.

These gaps justify **PARTIAL**, rather than PASS. The overall work is not BLOCKED: source access and intended repository are available; remaining questions are granular and the architectural constraints are explicit.

## Architecture and licensing recommendation

Retain the 17-module pure Ruby core/adapters design, with early finished-stack/edge resolution, separate division/pointset grammars, explicit reference/fit records, independent zone layers, physical occurrence identity and immutable accepted snapshots. Construction and Drawing share read-only final geometry/anchors; Drawing must not recompute construction independently.

Keep G01/G02 study-only; reject eval and unlicensedG08 intake. MIT tooling/examples may be adapted with notices and host/version checks. CurrentDentaku's Ruby>=3.2 is unsuitable for shared2021 runtime. Prawn remains on HOLD until license route, dependency closure, font choice and Ruby2.7/host evidence are recorded.06 distinguishes source-license permission from engineering approval.

## Acceptance assessment

| U2 criterion | Evidence/result |
|---|---|
| All available requested manuals actually inspected | Covered:13 files,555 indexed pages; review quality and limitations in 01 |
| Critical construction rules have page-level evidence | Covered:02–04 and 49-row trace table13 |
| Formulas/variables accurately documented | PARTIAL: meanings/relationships cited, remaining source conflicts and numeric contracts explicit |
| Architecture conflicts resolved or identified | Covered at design level:08–10 reconciliation; no implementation claim |
| Development repository identified | Covered:exact supplied repo, main/origin and empty-state inspection |
| Final report lists remaining gaps | Covered above and 11 |
| No production plugin code | Documentation/research tooling only; no plugin/RBZ/Phase2 |

## Deliverables, validation and commit

All fourteen existing reports under `docs/phase-01/` were revised in place.12 includes 38 small proposed backlog tasks and 29 additional manual-derived test scenarios;13 includes 49 exact-schema traceability rows. Planned test IDs are not executed plugin tests.

Document verification observed14 nonempty reports,0 broken relative links,13 matching cached PDF hashes,555 total PDF pages,49 trace rows with page numbers inside source bounds,38 backlog tasks and 29 manual fixture specifications. Seven independent research arithmetic checks passed; these are not parser/geometry/plugin tests. The archive and repository copy are separately checked for documentation-only contents and matching report hashes before delivery.

**Plugin automated tests: NOT RUN. Actual SketchUp runtime tests: NOT RUN.**  
**Git commit SHA: NONE — documentation changes remain uncommitted; initial repository had no HEAD. No remote push performed.**  
Exact upstream audit commits remain in 05. They are not JP commits.

## Phase2 recommendation

Resolve the high-impact formula/unit/profile ambiguities that affect the initial approved slice, then review12's backlog. Start only after explicit user approval. The first slice should demonstrate one original carcass, safe expressions/reference-aware divisions and one atomic resize/undo path. Do not import manufacturer defaults or excluded capabilities to fill evidence gaps.

Navigation: [inventory](01-source-inventory.md),[features](02-imos-feature-matrix.md),[formulas](03-formulas-and-variables.md),[construction](04-construction-rules.md),[GitHub](05-github-research.md),[licenses](06-license-audit.md),[compatibility](07-sketchup-compatibility.md),[architecture](08-system-architecture.md),[data model](09-data-model.md),[dependencies](10-module-dependencies.md),[risks](11-risk-register.md),[backlog](12-implementation-roadmap.md),[traceability](13-requirements-traceability.md).
