# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Support policy — PROPOSED

Use Ruby 2.7-compatible syntax for the shared core and capability adapters for host differences. Support target is desktop SketchUp 2021–2026, not SketchUp for Web. Host platform/OS builds require a separate matrix. Windows is the current research environment; macOS support is a design target requiring actual hosts, not a certified outcome.

## Version matrix

VERIFIED entries come from official API notes/class version annotations; INFERRED entries are explicitly identified. No target host was launched.

| Version | Embedded Ruby baseline | Browser baseline | API constraint / policy | Runtime validation |
|---|---|---|---|---|
| 2021.0 | VERIFIED 2.7.1 | INFERRED CEF64 from HtmlDialog's prior milestone | Use ordinary Entities; no 2021.1 sizing methods/constants | NOT RUN |
| 2021.1+ | VERIFIED 2.7.2 | VERIFIED CEF88 | Content-sizing additions available; retain 2021.0 fallback | NOT RUN |
| 2022 | INFERRED Ruby 2.7 line; exact patch not independently verified | INFERRED CEF88 milestone | EntitiesBuilder begins 2022; optional fast path only | NOT RUN |
| 2023 | INFERRED Ruby 2.7 line; exact patch not independently verified | INFERRED CEF88 milestone | Overlays available; optional preview enhancement | NOT RUN |
| 2024 | VERIFIED 3.2.2 | VERIFIED CEF112 | LayOut page_range added; separate Ruby 3 behavior checks | NOT RUN |
| 2025 | INFERRED continuation of 3.2.2, verify installed build | VERIFIED CEF128 | Keep newer material/graphics features optional | NOT RUN |
| 2026 | INFERRED continuation of 3.2.2, verify installed build | VERIFIED CEF137 | Scene property changes need operations; reject singular transforms | NOT RUN |

Sources: [release notes](https://ruby.sketchup.com/file.ReleaseNotes.html), [HtmlDialog milestones](https://ruby.sketchup.com/UI/HtmlDialog.html). Exact Ruby/browser builds must be logged from each installed host. “Not independently verified” is deliberate; no blanket six-version compatibility is claimed.

## API inventory and availability gates

| Concern | Documented baseline or limitation | JP design requirement |
|---|---|---|
| Registration | [Sketchup.register_extension](https://ruby.sketchup.com/Sketchup.html#register_extension-class_method) supports extension loaders | Small namespaced loader, register once, no globals or startup geometry |
| HtmlDialog | [UI::HtmlDialog](https://ruby.sketchup.com/UI/HtmlDialog.html) available since 2017; asynchronous callbacks; closing clears callbacks | Keep dialog alive; rebind on reopen; request IDs and explicit result delivery |
| JS/Ruby transport | Basic values convert; structured return delivery is a 2027 addition outside scope | 2021–2026 use JSON-safe messages and execute_script response dispatch |
| Definitions/instances | [Definition](https://ruby.sketchup.com/Sketchup/ComponentDefinition.html) shares geometry across [instances](https://ruby.sketchup.com/Sketchup/ComponentInstance.html) | Make changed definitions unique or replace by geometry fingerprint |
| Transformations | [Transformation](https://ruby.sketchup.com/Geom/Transformation.html) supports frames; 2026 inversion rejects singular matrices | Validate finite/invertible transforms on every version |
| Attributes | [AttributeDictionary](https://ruby.sketchup.com/Sketchup/AttributeDictionary.html) stores model/entity metadata | Namespaced schema, version and logical IDs; do not alter other dictionaries |
| Materials | [Material](https://ruby.sketchup.com/Sketchup/Material.html) supports classic surfaces/textures | Keep authoritative thickness/grain/edges in canonical model; gate later features |
| Selection | [Selection](https://ruby.sketchup.com/Sketchup/Selection.html) is not ordered by selection time | Resolve logical IDs and filter foreign entities |
| Operations/undo | [Model.start_operation](https://ruby.sketchup.com/Sketchup/Model.html#start_operation-instance_method) operations cannot nest | One operation for accepted update; abort on failure; no nested rule operations |
| Geometry | [Entities](https://ruby.sketchup.com/Sketchup/Entities.html) ordinary face creation predates baseline | 2021 fallback; EntitiesBuilder only when available |
| Sections | [SectionPlane](https://ruby.sketchup.com/Sketchup/SectionPlane.html) can be created from Ruby since 2014 | Host section display optional; standalone section topology independent |
| LayOut | [Overview](https://ruby.sketchup.com/file.LayOut.html) includes API in SketchUp | Optional exporter, separate coordinate conversion and host tests |
| PDF | [Model exporter options](https://ruby.sketchup.com/file.exporter_options.html) differ by OS | Do not assume native model export satisfies sheet/layout requirements |
| LayOut export | [Document.export](https://ruby.sketchup.com/Layout/Document.html#export-instance_method) since 2020.1; page_range since 2024 | Use older start/end mechanism for baseline; feature-gate range syntax |

## Lengths and coordinates

Canonical mm converts at SketchUp boundaries: inches=mm/25.4; never depend on display precision or model unit settings. LayOut's 2D coordinates use inches, top-left origin and downward Y, as [officially documented](https://ruby.sketchup.com/file.LayOut.html). PDF uses points, with points=mm·72/25.4 and a backend-specific Y flip. A canonical paper scene stays in mm.

## Bridge and transactions — PROPOSED

Use request_id, command, expected_revision, payload and protocol_version. Validate size/types before any operation; reject stale revisions and unknown commands. Escape outbound JSON with a real serializer; never interpolate user expressions into executable JavaScript or Ruby. Ruby is authoritative. UI results are an explicit dispatch message, independent of callbacks' return values.

Evaluate candidate snapshot before mutation. Store the accepted canonical document and entity mapping in the same undoable host operation as geometry. After undo/redo reload the stored revision and invalidate derived caches. Defer observer-triggered work and prevent reentrancy; do not start host operations from arbitrary rule callbacks.

## Required future checks

Pure core tests on Ruby 2.7 and 3.2 establish expression, rule, geometry-spec and BOM behavior only. Stub/static checks establish method awareness only. Real host tests must establish face topology, material mapping, performance, HtmlDialog/CEF behavior, selection context, undo/redo, save/reopen, sections and exporters. Test all six majors on supported OS builds, including 2021.0 if retained. No automated plugin tests or real-host tests were run during this documentation phase.

Future host reports must include full SketchUp build, OS, Ruby version, CEF version where accessible, extension commit, fixture hash and observed results. A successful current SketchUp run cannot certify an older version.



## Phase1B evidence boundary

All 13 imos PDFs are now reviewed, but their2009–2025 historical editions do not certify SketchUp2021–2026 API/runtime behavior. The official API audit above is retained. No new production methods or runtime tests were introduced. Candidate G03–G07/G10 version/license recheck is in 06; current Dentaku still excludesRuby2.7 and current template debug recipe still excludes2021. Finished thickness, reference-face, box and layering changes affect domain contracts, not the documented host version floor. Use explicit unit provenance for imported source fields; do not equate JP's internalmm requirement with an undocumented vendor-table unit.
