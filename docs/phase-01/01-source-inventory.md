# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Phase 1B source availability and repository

This report supersedes the Phase 1 “all manuals missing” inventory. Initial Phase 1 was PARTIAL because the PDFs were absent from the chat workspace. In Phase 1B the open Explorer window revealed the original network folder, and a read outside the restricted process succeeded. All thirteen requested PDFs were copied, without altering originals, into the local research cache `work/manuals/`. Sources are not included in public repository uploads or the documentation archive.

Original source folder: `Z:\Jurgen\MATERIALE IMOS (2)\MATERIALE IMOS\Manuale`. Before that discovery, no PDFs were found in this chat workspace or attachments; the broader Documents/Codex scan encountered37 inaccessible unrelated-tool directories. That initial bounded search is no longer the final availability result.

The user supplied `C:\Users\arkitekt2\Documents\JPMOS` and explicitly identified [Jurgen90Sia/JP_IMOS](https://github.com/Jurgen90Sia/JP_IMOS). Public GitHub metadata reports default branch main, public visibility, no license. Tree lookup returned409 “Git Repository is empty.” After confirming the destination directory was empty, the repository was cloned there. Origin fetch/push URL is `https://github.com/Jurgen90Sia/JP_IMOS.git`; active branch main; HEAD initially unborn, no existing tracked source/modules/tests/dependencies. There was no existing work to restructure. A per-command safe.directory setting handles the restricted process's different OS identity; no global Git trust setting was changed.

Only documentation is prepared in the actual repository. No plugin scaffold, RBZ, runtime dependency or excluded functionality is added. Remote naming JP_IMOS differs from the project label JP IMOS PRO; no second/unrelated JP_IMOS_PRO repository is created. The earlier instruction to create a new repository is satisfied by using the exact repository URL subsequently supplied by the user.

## Request and locator conventions

U1 is the original attached master prompt, sections1–15. U2 is the Phase1B request, Tasks1–6 and acceptance criteria. Neither is a PDF. Manual locators below are **one-based PDF page indices**; displayed printed folios match the cited examples, and FAQ footers use page/total. A filename is not evidence of content language. The Albanian filenames contain Italian originals and English translations, not Albanian prose editions.

## Actual manual inventory

All pages in all 13 PDFs were parsed and read, total 555. Text was extracted per page with pypdf, with metadata and SHA-256 recorded. Sparse/image pages were rendered and inspected; relevant tables, examples and figures were reviewed. This is not a claim that every screenshot on every page was individually enlarged.

| ID | Exact filename | Pages | Language | Displayed edition/date evidence | Relevant chapters/pages | Extraction quality / unreadable or missing pages |
|---|---|---:|---|---|---|---|
| M01 | Manual Artikull Parametrik.pdf |90| Italian | Articolo parametrico; Nov-09 cover p1 | Article/frames4–26; junctions27–36; zones37–61; fronts62–74; frame/plinth78–85 | Good text; p10,23 visually blank except folio; p30 screenshot-only. No missing indexed pages or wholly unreadable page observed. |
| M02 | Manual Menaxhimi i Elementeve.pdf |130| Italian | Gestione Elementi; Nov-09 p1; metadata category IMOS5.5 is not precise build | Materials7–28; MultiPart29–42; stretchables43–53; principles58–101; long pieces103–119; reveal rules121–130 | Good text, schematic labels merge; sparse57,86,101 are illustrated, not missing. Diagram-specific uncertainties retained. |
| M03 | Manual Manager.pdf |94| English machine translation; Italian screenshots | The Manager; Nov-09 p1 | Hierarchy4–10; scanning12–17; metadata19–28; parts44–47; edges65–84; edit scope89–94 | Joined words/translation errors. Sparse41,46,51,57,88 checked against Italian companion. No wholly unreadable page observed. |
| M04 | 00_Manager.pdf |94| Italian | Il Manager; Nov-09 p1; creation metadata27Nov2009 | Same underlying chapters as M03 | Companion/original, not independent third-party confirmation. Sparse46,51,57,88 are diagrams. No wholly unreadable page observed. |
| M05 | Manual Ndarja Lineare.pdf |12| English machine translation; Italian screenshots | Linear Division; Nov-09 p1 | Syntax5–8; descriptors9–10; panel references11–12 | Good text; exponent glyph missing even in rendered p8; p12 prose487.3 conflicts with screenshot474.7. Broken cross-references p8. No missing indexed pages. |
| M06 | Manual Ndertim i Lire.pdf |40| English machine translation; Italian screenshots | Free construction; Nov-09 p1 | Linked plan/section4–27; prefabricated paths28–31; embedded article32–37; joins38–40 | Translation/icon loss; sparse13,23,26,31,39 are illustrated. No wholly unreadable page observed. |
| M07 | Manual Sirtaret.pdf |30| English machine translation; Italian screenshots | Drawers; Nov-09 p1 | Types5–7; references8–14; fronts15–17; components18–22; contextual systems24–30 | Good main text; “bank”/“fund” are translation artifacts. All pages visually reviewed; fine screenshot microtext not adopted as defaults. |
| M08 | Variablat e brendshme te Sirtareve ne Imos.pdf |20| English; some German enums | Constructive connector characteristics - Drawers; browser-PDF metadata11Mar2025; exact product build UNKNOWN | Boxes/constructed1–6; systems7–12; purchased13–17; stretchables18–19; lock20 | Good text/tables; repeated/blank labels and missing field units are source defects. All pages visually reviewed. |
| M09 | Manual per krijimin e dyerve.pdf |16| Italian | Actual subject Costruzione di un pezzo MultiPart; footer21Oct2020 | Virtual thickness1; points2–8; children9–10; edge/report axes11–14; display15–16 | Good text and diagrams; not a general hinged-door manual despite filename. No wholly unreadable page observed. |
| M10 | Manual per futjen e dorezave.pdf |6| Italian | Inserire nuovi elementi di ferramenta - Maniglia; footer11Feb2020 | Catalog/underlying asset1–3; visual asset origin5–6 | Good text; predominantly hardware-intake example with excluded operations. No general handle placement formula supplied. |
| M11 | Manual per futjen e kembeve.pdf |7| Italian | Gestione foratura piedini; footer24Jun2020 | Visual leg reference2–4; coordinated occurrence7 | Good text; predominantly drilling, deliberately excluded. Not a leg dimension catalog. No wholly unreadable page observed. |
| M12 | Manual per krijimin e texturave.pdf |3| Italian | Inserire una nuova texture; footer13Dec2019 | Render principles/images1; wrapper/reflectivity2; application/scale3 | Good text, numbered screenshot callouts checked. Scale units not documented. All 3 pages visually reviewed. |
| M13 | Manual Skuadrim dhe Layout.pdf |13| English machine translation; Italian screenshots | Squaring and Layout; Nov-09 p1 | Templates4–6; attributes7–9; paper/views10–13 | Good text with corrupt/ambiguous attribute labels. Visual review7–12; PDF engine/section algorithms not documented. |

**MISSING: none of the 13 requested files.** Missing source pages cannot be inferred from a successful parse alone: no absent page indices or wholly unreadable pages were observed, but there is no publisher checksum/master set to prove these files contain every original page. Sparse text alone is not treated as failed extraction.

The source directory also contains 20 other PDFs. They are outside this thirteen-file audit and were not silently counted as reviewed. No machining-focused supplementary manual was adopted into scope.

## File integrity

Exact cached file SHA-256 values:

| PDF | SHA-256 |
|---|---|
| 00_Manager.pdf | 3333e5e3d03695c025dc2fc6def11a078d693437c0526d752eba00681a12e0d2 |
| Manual Artikull Parametrik.pdf | bb6b1f75b510bd2a51d2d6a576f18d73387527cee4ac626393d2ce2afc475667 |
| Manual Manager.pdf | 80659ae42fec4f4c5f99c86873d2e180027fa23fc169e218d64810f069812453 |
| Manual Menaxhimi i Elementeve.pdf | a2f8db08dbe38619425aa1eb75d75628e518507941889f76d67a0a4343ae5335 |
| Manual Ndarja Lineare.pdf | 4075899e64dba301b8c82eb6890234d0f6843798e3d4f2b40f2c42ced63b35fb |
| Manual Ndertim i Lire.pdf | 99819b59205c661d0a606e5309195a4479e3ffda429ba19dd6c36db76619abb3 |
| Manual per futjen e dorezave.pdf | 8535be19a0463e0441c02543c8bad5197de4c966d39178d8d6ee76b8a54b6757 |
| Manual per futjen e kembeve.pdf | 26c541a67db968f27b91fab7b516c3fbfaa4bbda682c1e127934fa8fa3c08034 |
| Manual per krijimin e dyerve.pdf | 1aa6224e6a8b1660015efe21a09c6cb0732d092b3142491f984ee4243ead0a43 |
| Manual per krijimin e texturave.pdf | 5aa57cfd2969a0d19730adbe8107ea0f17e50d0c03bf28a1804b75f481a2cc65 |
| Manual Sirtaret.pdf | fe2dc5b2cde04a943f1c1f946f7df13e719f18dc8282833c38f0ead2b4f2810f |
| Manual Skuadrim dhe Layout.pdf | 3504c2e8d02a3241705d8669b1427a86743242fd64683ad0d0f6b91861638eff |
| Variablat e brendshme te Sirtareve ne Imos.pdf | 0e9778cbe3766571072725250394c7dbe7c14000d163f7cf55e593bb455ea5c8 |

## Review method and source limits

All 102 pages of Article/Linear text read by the primary reviewer; sample visual pages Article10,23,30,43,51 and Linear8–12, with reference diagrams inspected. All 199 Element/Free/MultiPart/Handle/Leg pages read, with 33 selected pages visually reviewed. All 201 Manager/Layout pages read, with important/image-only pages visually checked. All 53 Drawer/Variable/Texture pages read and visually checked. pypdf warned about Symbol CFF font encoding; numeric/operator ambiguities were checked in rendered pages rather than guessed. No current imos installation was used to resolve source contradictions. Exact tests below are planned, not executed plugin tests.


## External evidence inventory

The six requested repositories and four additional candidates were inspected through public GitHub metadata, commit, recursive tree and selected file endpoints. Exact commits, licenses and inspected files are recorded in [05](05-github-research.md). This was a targeted source audit, not a full security or transitive dependency audit.

Official sources inspected:

| ID | Primary source | Evidence scope |
|---|---|---|
| S1 | [SketchUp release notes](https://ruby.sketchup.com/file.ReleaseNotes.html) | Version changes and compatibility boundaries |
| S2 | [HtmlDialog](https://ruby.sketchup.com/UI/HtmlDialog.html) | Embedded browser and callback behavior |
| S3 | [Model](https://ruby.sketchup.com/Sketchup/Model.html) | Operations, collections and exports |
| S4 | [Entities](https://ruby.sketchup.com/Sketchup/Entities.html) | Geometry creation and section placement |
| S5 | [ComponentDefinition](https://ruby.sketchup.com/Sketchup/ComponentDefinition.html), [ComponentInstance](https://ruby.sketchup.com/Sketchup/ComponentInstance.html) | Shared geometry and placement |
| S6 | [Transformation](https://ruby.sketchup.com/Geom/Transformation.html) | Local/world placement and inversion |
| S7 | [AttributeDictionary](https://ruby.sketchup.com/Sketchup/AttributeDictionary.html) | Persistence at model/entity level |
| S8 | [Material](https://ruby.sketchup.com/Sketchup/Material.html) | Surface color/texture APIs |
| S9 | [Selection](https://ruby.sketchup.com/Sketchup/Selection.html) | Selection semantics |
| S10 | [SectionPlane](https://ruby.sketchup.com/Sketchup/SectionPlane.html) | Section controls |
| S11 | [LayOut overview](https://ruby.sketchup.com/file.LayOut.html), [Document export](https://ruby.sketchup.com/Layout/Document.html#export-instance_method) | Native document integration |
| S12 | [Exporter options](https://ruby.sketchup.com/file.exporter_options.html) | OS-specific PDF options |
| S13 | [Extension registration](https://ruby.sketchup.com/Sketchup.html#register_extension-class_method) | Loader integration |

These are living pages, not version-frozen 2021 documentation. They currently include entries beyond the target range, including 2027; newer entries must not be silently applied to 2021–2026. No source publish date is inferred from a crawler's date. API evidence identifies documented support, not successful real-host execution.
