# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Method and scope

Public repository metadata, default-branch commit endpoints, recursive trees and selected actual file contents were inspected. Commits below are commit endpoint SHAs, not invented release tags. No repository was cloned, installed, executed or copied into plugin production code. Branch heads can move; links are pinned to the inspected commit.

Coverage: six requested repositories plus four additional repositories covering cabinet construction, constraints, safe-expression prior art and vector PDF. Additional search results were discovery leads only; no functionality is attributed to uninspected search hits. SVG evidence comes from OpenCutList's inspected writer. Research is targeted, not an exhaustive survey or whole-repository security audit.

## G01 — lairdubois/lairdubois-opencutlist-sketchup-extension

Repository: [lairdubois/lairdubois-opencutlist-sketchup-extension](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension)  
Default branch: `master`  
Inspected commit: [`1ef3e14c896171eed8cd77ede440c7f5563e943e`](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/commit/1ef3e14c896171eed8cd77ede440c7f5563e943e)

**Decision: STUDY ONLY.** VERIFIED: Ruby controllers dispatch workers; the cutlist generation worker imports cutlist part/group models, geometry helpers and material attributes. MaterialAttributes defines categories for sheet goods, edge material and hardware and records grain/thickness. The drawing projection worker uses a Fiddle Clippy wrapper; its drawing writer supports SVG and DXF. These are inspected implementations, not claims of a complete architectural match.

The common formula worker at line 37 invokes Ruby eval after a parser check. **REJECT that evaluation technique** for JP: it violates U1 regardless of upstream filtering. The cutlist controller also wires packing/cutting-diagram capabilities; exclude those entirely. Dependencies inspected: development minitest and API stubs; Gulp/Twig/LESS build tooling; native Fiddle wrappers visible in inspected imports. Full bundled dependency licenses remain unaudited.

Tests: inspected FormulaParser TestUp tests include forbidden-input cases; tree also contains axes/dimension/geometrix tests and SKP fixtures. build/package.json has an intentionally failing no-test npm script, so npm test is not evidence of Ruby test coverage. No upstream tests executed. Compatibility with all six JP hosts is UNKNOWN. Potential reuse is conceptual: BOM identity, material metadata, projection pipelines. GPL obligations and native modules make code transplantation unsuitable pending a deliberate licensing decision.

Inspected files:
- [LICENSE](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/LICENSE)
- [Gemfile](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/Gemfile)
- [build/package.json](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/build/package.json)
- [src/ladb_opencutlist/ruby/controller/cutlist_controller.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/src/ladb_opencutlist/ruby/controller/cutlist_controller.rb)
- [src/ladb_opencutlist/ruby/worker/cutlist/cutlist_generate_worker.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/src/ladb_opencutlist/ruby/worker/cutlist/cutlist_generate_worker.rb)
- [src/ladb_opencutlist/ruby/worker/common/common_drawing_projection_worker.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/src/ladb_opencutlist/ruby/worker/common/common_drawing_projection_worker.rb)
- [src/ladb_opencutlist/ruby/worker/common/common_eval_formula_worker.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/src/ladb_opencutlist/ruby/worker/common/common_eval_formula_worker.rb)
- [test/TC_Ladb_Parser_FormulaParser.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/test/TC_Ladb_Parser_FormulaParser.rb)
- [src/ladb_opencutlist/ruby/model/attributes/material_attributes.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/src/ladb_opencutlist/ruby/model/attributes/material_attributes.rb)
- [src/ladb_opencutlist/ruby/worker/common/common_write_drawing2d_worker.rb](https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/1ef3e14c896171eed8cd77ede440c7f5563e943e/src/ladb_opencutlist/ruby/worker/common/common_write_drawing2d_worker.rb)

## G02 — SamuelTallet/SketchUp-Parametric-Modeling-Plugin

Repository: [SamuelTallet/SketchUp-Parametric-Modeling-Plugin](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin)  
Default branch: `main`  
Inspected commit: [`25b5d31f06f3e5d5810909426f3e80c9199a6d42`](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/commit/25b5d31f06f3e5d5810909426f3e80c9199a6d42)

**Decision: STUDY ONLY.** VERIFIED: Node dispatches computational node types; CalculateNode uses Dentaku with supplied inputs; ParametricEntities resets computed state and evaluates nodes inside a host operation. Its redraw calls erase then draw as separate routines; do not assume this guarantees atomic replacement after an error. The current frontend manifest lists React, Rete, Vite, TypeScript and Vitest; its development Node requirement is ≥24, not an embedded CEF runtime requirement.

License is GPL-3.0-or-later in inspected source headers and frontend manifest; docs/LICENSE supplies GPLv3 text. Vendored Dentaku has a separate MIT notice, but use upstream if adopting it independently. Inspected Vitest formula tests cover arithmetic and math functions; Ruby/SketchUp runtime behavior was not tested. Current UI bundles and declared dependencies cannot be assumed to support SketchUp 2021's embedded browser. Useful as graph-evaluation and regeneration prior art; do not copy GPL implementation into an independently licensed product.

Inspected files:
- [docs/LICENSE](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/docs/LICENSE)
- [source/parametric_modeling/calculate_node.rb](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/source/parametric_modeling/calculate_node.rb)
- [source/parametric_modeling/node.rb](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/source/parametric_modeling/node.rb)
- [source/parametric_modeling/parametric_entities.rb](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/source/parametric_modeling/parametric_entities.rb)
- [source/parametric_modeling/Nodes Editor/package.json](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/source/parametric_modeling/Nodes%20Editor/package.json)
- [source/parametric_modeling/Libraries/dentaku.license.txt](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/source/parametric_modeling/Libraries/dentaku.license.txt)
- [source/parametric_modeling/Nodes Editor/src/editor/engine/__tests__/evaluateFormula.test.ts](https://github.com/SamuelTallet/SketchUp-Parametric-Modeling-Plugin/blob/25b5d31f06f3e5d5810909426f3e80c9199a6d42/source/parametric_modeling/Nodes%20Editor/src/editor/engine/__tests__/evaluateFormula.test.ts)

## G03 — SketchUp/sketchup-ruby-api-tutorials

Repository: [SketchUp/sketchup-ruby-api-tutorials](https://github.com/SketchUp/sketchup-ruby-api-tutorials)  
Default branch: `main`  
Inspected commit: [`f9827d173c6fcec179dfba259804090aaeaad429`](https://github.com/SketchUp/sketchup-ruby-api-tutorials/commit/f9827d173c6fcec179dfba259804090aaeaad429)

**Decision: ADAPT.** VERIFIED: the hello-cube example namespaces extension code, starts a model operation, creates a group, adds a face, extrudes and commits. It depends on the SketchUp runtime. The inspected example is teaching code, with no failure rollback in that method; production code needs explicit abort handling. No test suite for this example was identified in the inspected recursive tree. MIT permits candidate adaptation with notices. This example establishes a host API pattern, not furniture geometry or blanket 2021–2026 certification.

Inspected files:
- [LICENSE](https://github.com/SketchUp/sketchup-ruby-api-tutorials/blob/f9827d173c6fcec179dfba259804090aaeaad429/LICENSE)
- [examples/01_hello_cube/ex_hello_cube/main.rb](https://github.com/SketchUp/sketchup-ruby-api-tutorials/blob/f9827d173c6fcec179dfba259804090aaeaad429/examples/01_hello_cube/ex_hello_cube/main.rb)

## G04 — SketchUp/ruby-api-stubs

Repository: [SketchUp/ruby-api-stubs](https://github.com/SketchUp/ruby-api-stubs)  
Default branch: `main`  
Inspected commit: [`1190aeadef137796d717d8de6eba2005d0efd7c3`](https://github.com/SketchUp/ruby-api-stubs/commit/1190aeadef137796d717d8de6eba2005d0efd7c3)

**Decision: REUSE (development only).** VERIFIED: MIT gem metadata requires Ruby ≥2.0. The inspected Entities stub contains declarations including methods from newer hosts; it is documentation/autocomplete data, not a SketchUp geometry runtime. It must not be loaded as a substitute host or used to prove geometry tests pass. Pin a version or filter method availability for the target host. No functioning geometry test implementation is claimed. Benefit: editor/static API awareness; risk: newer symbols make unsupported calls appear available.

Inspected files:
- [LICENSE](https://github.com/SketchUp/ruby-api-stubs/blob/1190aeadef137796d717d8de6eba2005d0efd7c3/LICENSE)
- [README.md](https://github.com/SketchUp/ruby-api-stubs/blob/1190aeadef137796d717d8de6eba2005d0efd7c3/README.md)
- [sketchup-api-stubs.gemspec](https://github.com/SketchUp/ruby-api-stubs/blob/1190aeadef137796d717d8de6eba2005d0efd7c3/sketchup-api-stubs.gemspec)
- [lib/sketchup-api-stubs/stubs/Sketchup/Entities.rb](https://github.com/SketchUp/ruby-api-stubs/blob/1190aeadef137796d717d8de6eba2005d0efd7c3/lib/sketchup-api-stubs/stubs/Sketchup/Entities.rb)

## G05 — SketchUp/testup-2

Repository: [SketchUp/testup-2](https://github.com/SketchUp/testup-2)  
Default branch: `main`  
Inspected commit: [`8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd`](https://github.com/SketchUp/testup-2/commit/8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd)

**Decision: REUSE (development only, pinned host-compatible version).** VERIFIED: TestUp::TestCase inherits Minitest::Test and includes SketchUp test utilities when Sketchup is defined. README requires SketchUp 2017+ for the current line; Gemfile pins Minitest 5.15.0 and lists development/analytics tools. package.json uses Vue 2/Webpack 4 build dependencies and a no-test npm script. The repository includes native taskbar helpers in its tree; do not assume their ABI is interchangeable across hosts.

The runner supports in-host testing, but no JP suite exists yet and no runtime test was executed. Keep runner tooling out of the end-user extension dependency graph. Its declared minimum does not prove the current checkout was tested on each supported JP version.

Inspected files:
- [LICENSE](https://github.com/SketchUp/testup-2/blob/8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd/LICENSE)
- [Gemfile](https://github.com/SketchUp/testup-2/blob/8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd/Gemfile)
- [package.json](https://github.com/SketchUp/testup-2/blob/8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd/package.json)
- [src/testup/testcase.rb](https://github.com/SketchUp/testup-2/blob/8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd/src/testup/testcase.rb)
- [README.md](https://github.com/SketchUp/testup-2/blob/8d9c2acdb0d4a46f5e2cddc60a2fc4a0f67a09bd/README.md)

## G06 — SketchUp/sketchup-extension-vscode-project

Repository: [SketchUp/sketchup-extension-vscode-project](https://github.com/SketchUp/sketchup-extension-vscode-project)  
Default branch: `main`  
Inspected commit: [`e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2`](https://github.com/SketchUp/sketchup-extension-vscode-project/commit/e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2)

**Decision: ADAPT (development configuration only).** VERIFIED: MIT template supplies a namespaced cube example and a TestUp geometry test; inspected test resets model state and exercises cube creation. Gemfile supplies development lint/editor tooling. README states the present debugging setup requires SketchUp 2024+, with older hosts requiring an older commit. Therefore do not adopt the entire current template for 2021–2023 unchanged. Select separate debug configurations and pinned tooling. No test in this repository was executed by this audit.

Inspected files:
- [LICENSE.md](https://github.com/SketchUp/sketchup-extension-vscode-project/blob/e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2/LICENSE.md)
- [Gemfile](https://github.com/SketchUp/sketchup-extension-vscode-project/blob/e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2/Gemfile)
- [src/ex_hello_cube/main.rb](https://github.com/SketchUp/sketchup-extension-vscode-project/blob/e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2/src/ex_hello_cube/main.rb)
- [tests/Cube Example/TC_Example_Main.rb](https://github.com/SketchUp/sketchup-extension-vscode-project/blob/e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2/tests/Cube%20Example/TC_Example_Main.rb)
- [README.md](https://github.com/SketchUp/sketchup-extension-vscode-project/blob/e13ba9dd01bdf4ab9392aa1c9850b73c54e381d2/README.md)

## G07 — prawnpdf/prawn

Repository: [prawnpdf/prawn](https://github.com/prawnpdf/prawn)  
Default branch: `master`  
Inspected commit: [`c5be930cdeed13da3f8ecfb2f939e2190ec05a20`](https://github.com/prawnpdf/prawn/commit/c5be930cdeed13da3f8ecfb2f939e2190ec05a20)

**Decision: ADAPT candidate; integration not approved.** VERIFIED: Document handles page creation/rendering; Graphics exposes path primitives; inspected graphics specs use PDF::Inspector to verify line operators. gemspec requires Ruby ≥2.7 and runtime matrix ~>0.4, pdf-core ~>0.10.0, ttfunk ~>1.8. Those transitive packages and fonts need independent license/version review.

COPYING offers Matz's original Ruby terms or GPLv2 or GPLv3; LICENSE contains the nonstandard alternative terms. It is incorrect to report this as simply MIT or as necessarily GPL-only. A selected license route and packaged notices must be documented before use. Suitable candidate for pure Ruby vector output and Unicode font embedding; compatibility is a gem requirement, not a successful SketchUp host test. Namespace collisions, font coverage, PDF reproducibility and dependency isolation remain risks.

Inspected files:
- [LICENSE](https://github.com/prawnpdf/prawn/blob/c5be930cdeed13da3f8ecfb2f939e2190ec05a20/LICENSE)
- [COPYING](https://github.com/prawnpdf/prawn/blob/c5be930cdeed13da3f8ecfb2f939e2190ec05a20/COPYING)
- [prawn.gemspec](https://github.com/prawnpdf/prawn/blob/c5be930cdeed13da3f8ecfb2f939e2190ec05a20/prawn.gemspec)
- [lib/prawn/document.rb](https://github.com/prawnpdf/prawn/blob/c5be930cdeed13da3f8ecfb2f939e2190ec05a20/lib/prawn/document.rb)
- [lib/prawn/graphics.rb](https://github.com/prawnpdf/prawn/blob/c5be930cdeed13da3f8ecfb2f939e2190ec05a20/lib/prawn/graphics.rb)
- [spec/prawn/graphics_spec.rb](https://github.com/prawnpdf/prawn/blob/c5be930cdeed13da3f8ecfb2f939e2190ec05a20/spec/prawn/graphics_spec.rb)

## G08 — tunnelvisionlabs/aicabinets

Repository: [tunnelvisionlabs/aicabinets](https://github.com/tunnelvisionlabs/aicabinets)  
Default branch: `main`  
Inspected commit: [`e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4`](https://github.com/tunnelvisionlabs/aicabinets/commit/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4)

**Decision: REJECT code reuse; STUDY ONLY for publicly observable design concepts.** No root LICENSE/COPYING file or recognized repository license was identified in the inspected tree/metadata; absent permission is not an open-source license. VERIFIED: lib/cabinet.rb is a loader shim; the legacy cabinet file delegates to a generator. The carcass generator imports separate side/bottom/top/back, shelf/front/partition, unit/tag/material modules. This confirms a modular generator architecture beyond its README.

The legacy file also contains drilling-related constants. These are excluded and must not enter JP data models or commands. Inspected per-bay Minitest tests load SketchUp test doubles; they cannot establish native geometry validity. A TestUp geometry suite exists in the tree but was not run. Gemfile lists RuboCop; declared host support was not verified. Do not transplant code, default dimensions, branding or assets.

Inspected files:
- [README.md](https://github.com/tunnelvisionlabs/aicabinets/blob/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4/README.md)
- [Gemfile](https://github.com/tunnelvisionlabs/aicabinets/blob/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4/Gemfile)
- [lib/cabinet.rb](https://github.com/tunnelvisionlabs/aicabinets/blob/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4/lib/cabinet.rb)
- [aicabinets/generator/legacy/cabinet.rb](https://github.com/tunnelvisionlabs/aicabinets/blob/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4/aicabinets/generator/legacy/cabinet.rb)
- [test/generator_per_bay_test.rb](https://github.com/tunnelvisionlabs/aicabinets/blob/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4/test/generator_per_bay_test.rb)
- [aicabinets/generator/carcass.rb](https://github.com/tunnelvisionlabs/aicabinets/blob/e1a138233ebd54bc1c0a88d1ff09e0fa2243b4e4/aicabinets/generator/carcass.rb)

## G09 — nucleic/kiwi

Repository: [nucleic/kiwi](https://github.com/nucleic/kiwi)  
Default branch: `main`  
Inspected commit: [`898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56`](https://github.com/nucleic/kiwi/commit/898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56)

**Decision: STUDY ONLY initially.** VERIFIED: Modified BSD / BSD-3-Clause terms in LICENSE; C++ Solver exposes add/remove constraints and documents duplicate/unsatisfiable conditions. Inspected SolverTest uses GoogleTest; tree also contains Python tests. Python packaging requires Python ≥3.10; that is not a Ruby integration.

Cassowary handles linear constraints, not general furniture construction, nonlinear geometry or discrete join selection. A native wrapper would add per-OS/per-ABI packaging and testing; no Ruby SketchUp adapter was identified in inspected files. Use a deterministic dependency DAG for Phase 2, reconsider a solver only for a demonstrated simultaneous-constraint requirement. Preserve notices and non-endorsement terms if later selected.

Inspected files:
- [LICENSE](https://github.com/nucleic/kiwi/blob/898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56/LICENSE)
- [README.md](https://github.com/nucleic/kiwi/blob/898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56/README.md)
- [kiwi/solver.h](https://github.com/nucleic/kiwi/blob/898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56/kiwi/solver.h)
- [tests/SolverTest.cpp](https://github.com/nucleic/kiwi/blob/898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56/tests/SolverTest.cpp)
- [pyproject.toml](https://github.com/nucleic/kiwi/blob/898d5cf9aa1b3a2ffa9019feaa6f51c25feacd56/pyproject.toml)

## G10 — rubysolo/dentaku

Repository: [rubysolo/dentaku](https://github.com/rubysolo/dentaku)  
Default branch: `main`  
Inspected commit: [`1b9950be405ecb0d425f8683447b58cf29796d1f`](https://github.com/rubysolo/dentaku/commit/1b9950be405ecb0d425f8683447b58cf29796d1f)

**Decision: STUDY ONLY for current commit; ADAPT candidate only after version selection.** VERIFIED: calculator orchestrates parser/tokenizer and AST evaluation; dependency resolver uses TSort and explicitly detects strongly connected components/self-dependencies. gemspec is MIT but now requires Ruby ≥3.2 with bigdecimal ≥3.1, concurrent-ruby ~>1.1 and tsort ≥0.1.1. This excludes an unmodified current release on SketchUp 2021–2023's Ruby 2.7 line.

Tokenizer and resolver patterns are useful prior art. A generic formula library does not automatically enforce JP's dimensional types, lazy condition semantics or resource limits. Tree contains calculator/tokenizer/resolver specs; these were not executed. Do not assume an older compatible release has identical APIs or licensing without pinning and auditing that release.

Inspected files:
- [LICENSE](https://github.com/rubysolo/dentaku/blob/1b9950be405ecb0d425f8683447b58cf29796d1f/LICENSE)
- [dentaku.gemspec](https://github.com/rubysolo/dentaku/blob/1b9950be405ecb0d425f8683447b58cf29796d1f/dentaku.gemspec)
- [lib/dentaku/calculator.rb](https://github.com/rubysolo/dentaku/blob/1b9950be405ecb0d425f8683447b58cf29796d1f/lib/dentaku/calculator.rb)
- [lib/dentaku/tokenizer.rb](https://github.com/rubysolo/dentaku/blob/1b9950be405ecb0d425f8683447b58cf29796d1f/lib/dentaku/tokenizer.rb)
- [lib/dentaku/dependency_resolver.rb](https://github.com/rubysolo/dentaku/blob/1b9950be405ecb0d425f8683447b58cf29796d1f/lib/dentaku/dependency_resolver.rb)

## Decision meaning

REUSE = candidate use with preserved notices and version pin, subject to integration checks; ADAPT = original integration around selected compatible material; STUDY ONLY = no code intake; REJECT = no reuse under current evidence. These are engineering intake decisions, not blanket legal approvals. No third-party runtime dependency has been finally selected.



## Phase1B candidate recheck and target repository

The existing ten-candidate research and all pinned source SHAs above are retained. Phase1B fetched the same pinned licenses/manifests for G03–G07, andG10 gemspec again; no whole-repository research was restarted. The permission/Ruby/dependency/integration decisions are consolidated in 06. No older Dentaku release was assumed compatible without separate verification; currentG10 is rejected for shared2021 runtime. No eval-based worker was adopted.

Target development repository is [Jurgen90Sia/JP_IMOS](https://github.com/Jurgen90Sia/JP_IMOS), explicitly supplied by the user after the earlier create-new instruction. Metadata:public, default main, size0, no identified license. Recursive-tree endpoint returned409 empty Git repository. Local clone main/origin was verified atC:\Users\arkitekt2\Documents\JPMOS. Initial HEAD is unborn; there are no prior application modules, tests or dependencies to audit. Only original research documentation is prepared locally. No proprietary PDF, source cache or third-party plugin code is copied into this public repository and no push is performed.
