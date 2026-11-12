# JP IMOS PRO — Phase 1

Research date: 12 November 2026 (Europe/Berlin). Phase 1B revision. Status: PARTIAL. Research and architecture only.

Evidence labels: **VERIFIED** = explicit inspected evidence; **INFERRED** = conclusion from that evidence; **PROPOSED** = original design; **UNKNOWN** = insufficient evidence. A user requirement verifies requested scope, not proprietary product behavior. No plugin, RBZ, or excluded manufacturing functionality is delivered.

## Intake findings

The project distribution license is **UNKNOWN**; U1 asks for legal independence but does not say whether JP will be proprietary or copyleft. Accordingly no GPL code has been incorporated, and no automatic incompatibility between “commercial” and GPL is asserted. The design remains original regardless of the eventual distribution choice.

| Source | Verified licensing evidence | Proposed intake decision | Remaining obligation/risk |
|---|---|---|---|
| OpenCutList G01 | GPLv3 text; build manifest GPL-3.0 | STUDY ONLY | Any derivative distribution requires review of GPL scope and source obligations |
| Parametric Modeling G02 | GPLv3-or-later source headers and frontend manifest | STUDY ONLY | Preserve distinction from its separately licensed bundled libraries |
| Official tutorials G03 | MIT LICENSE | ADAPT | Retain copyright and permission notice for copied substantial portions |
| API stubs G04 | MIT LICENSE/gemspec | REUSE in tooling | Pin API generation and keep out of runtime |
| TestUp G05 | MIT LICENSE | REUSE in tooling | Bundled gems/native helpers have their own intake requirements |
| VS Code template G06 | MIT LICENSE.md | ADAPT in tooling | Copied configs and dependencies need notice/version tracking |
| Prawn G07 | COPYING and nonstandard LICENSE, alternatively GPLv2/v3 | Conditional ADAPT candidate | Choose and record actual license route; do not label merely permissive without review |
| AI Cabinets G08 | No root license/metadata license identified | REJECT reuse | Public visibility alone grants no general modification/distribution permission |
| Kiwi G09 | Modified BSD terms in LICENSE | STUDY ONLY for now | Retain notices/disclaimer; no endorsement; native dependency review |
| Dentaku G10 | MIT LICENSE and gemspec | Current version STUDY ONLY | Ruby floor and dependencies prevent unmodified baseline adoption |
| imos manuals M01–M13 | Now available; historical copyright/property notices inspected | Functional study only; no original asset redistribution | PDF/extraction/render cache stays outside repository and output archive |
| SketchUp runtime/API | Vendor platform, not bundled open-source JP dependency | Target platform | Review vendor distribution terms when packaging; no runtime redistribution implied |

Evidence: pinned source and license file links in [05](05-github-research.md). This table reports the inspected evidence; it does not certify all transitive licenses or replace advice about an actual distribution.

## Independent implementation boundary — PROPOSED

Write requirements in original terms, label each with provenance, and independently implement behavior from permitted evidence. Do not obtain proprietary source, decompile binaries, copy manual diagrams or redistribute proprietary furniture/material/hardware databases. The project name supplied by U1 contains “IMOS”; trademark/name clearance is unresolved, and no affiliation should be implied.

For every future included package record name, exact version/commit, download origin, checksum, SPDX expression or exact nonstandard terms, selected licensing route, runtime/build/dev role, modified files, notices, direct/transitive dependencies and distribution location. Maintain a release SBOM and notices file. Neither package metadata nor a root license alone clears bundled fonts, textures, native libraries or example assets.

## Phase 1B reuse decision record

This continues the pinned audit in 05; no upstream survey was restarted. In Phase 1B, the pinned G03–G07 licenses/manifests and G10 gemspec were fetched again. Legal permission under a source license and engineering approval to integrate it are separate decisions. No candidate was installed or executed.

| Candidate | License / permission at inspected commit | Ruby / host compatibility | Dependency risk | Integration method | Phase 1B decision |
|---|---|---|---|---|---|
| G01 OpenCutList | GPLv3; conditional permissions, no unconditional JP license compatibility established | Whole-extension 2021 compatibility not established | Native wrappers and large bundled graph; formula worker uses eval | Observe concepts only; no copied engine or linked dependency | **NO intake**; eval worker rejected |
| G02 Parametric Modeling | GPL-3.0-or-later; conditional permissions | Unverified whole-extension baseline; vendored parser version differs from current upstream | Frontend/bundled libraries have separate terms | Concept study only; no GPL module copied | **NO intake** under present JP decision |
| G03 official hello-cube example | MIT permits adaptation if notice is retained | Inspected method uses older face/group/operation APIs and no post-2.7 Ruby syntax; actual host execution unverified | Runtime SketchUp only in this method | Adapt loader/operation pattern into JP namespace, add rollback; keep notice if copied | **Permitted conditionally by MIT; engineering gate pending** |
| G04 API stubs | MIT permits development use with notice | gemspec Ruby >=2.0 includes 2.7; newer API declarations need version filtering | No runtime dependency declared in inspected gemspec; IDE tooling separate | Development gem only, pinned; never runtime geometry substitute | **Permitted for tooling; host availability filtering required** |
| G05 TestUp | MIT permits use with notice | README SketchUp 2017+ is a declared range, not six-host validation | Minitest 5.15.0; development gems; native helpers; old UI toolchain | Install only into test hosts; separate tooling lockfile; no end-user runtime requirement | **Permitted for development; exact build/ABI qualification pending** |
| G06 VS Code template | MIT permits adapting configs/examples with notice | Current debug recipe requires SketchUp 2024+; not an unchanged 2021 solution | Floating development tool versions; present Gemfile also lists fiddle | Select minimal configs; define separate 2021/2.7 and 2024+/3.2 workflows; no full-template import | **Limited configuration adaptation permitted; debugger blocked on 2021** |
| G07 Prawn | Choice of original Ruby terms or GPLv2/v3; chosen route not recorded yet | gemspec >=2.7 accepts 2.7 syntactically; host and transitive compatibility untested | matrix ~>0.4, pdf-core ~>0.10.0, ttfunk ~>1.8; fonts; Ruby namespace collisions | Optional PDFSerializer port; bundle exact vetted versions offline; no runtime gem installation | **HOLD integration** pending license-route, transitive and host evidence |
| G08 AI Cabinets | No reuse permission established from inspected license evidence | No qualified 2021 runtime result | Unlicensed code/defaults/assets and excluded features | No intake | **REJECT** |
| G09 Kiwi | Modified BSD permits use with notices/non-endorsement | C++ rather than Ruby; no qualified Ruby/SketchUp adapter | Native builds per OS/ABI; more machinery than initial DAG needs | Study solver concepts; no initial native dependency | **Defer; no Phase 2 dependency** |
| G10 current Dentaku | MIT permits use with notice | **Ruby >=3.2**, excludes SketchUp 2021's 2.7 baseline | bigdecimal >=3.1, concurrent-ruby ~>1.1, tsort >=0.1.1 | No current-version integration; no unverified “older version” exemption | **REJECT current commit for shared runtime** |

Evidence URLs, exact commits and file paths remain in [05](05-github-research.md). Prawn dependencies were not individually re-audited, so its Ruby floor is not a declaration that its entire dependency closure works on 2.7.

**Selected parser direction: original restricted typed parser, PROPOSED.** No eval, instance_eval, class_eval or user-defined executable callback is permitted for expression interpretation. This is a design choice, not an independently verified implementation. A future older Dentaku candidate needs an exact audited commit, license, dependency closure and Ruby-2.7 execution result before reconsideration. No such alternative has been approved here.

## Dependency license coverage

The identified JP_IMOS repository initially contains no application dependency. External dependency findings are partial: manifests were inspected, but full lockfile resolution, all vendored headers and every transitive license were not audited. Prawn's pdf-core/ttfunk/matrix, Dentaku's bigdecimal/concurrent-ruby/tsort and frontend/tooling transitive packages are **not approved for redistribution** by this report.

No code was copied into a production extension in Phase 1. Research file URLs are references, not embedded vendored source. Phase 2 can begin with dependency-free core experiments only after explicit approval; redistribution requires the separate package intake review.



## Manual copyright and source handling update

M01–M13 are now available and audited; the earlier MISSING licensing row is superseded. Historical manual copyright/property notices are visible, for example Manual Artikull Parametrik.pdf pp. 2 and Manual Ndarja Lineare.pdf pp. 2. The supplied files are evidence for functional study, not permission to redistribute their screenshots, textures, databases or full text. Source PDFs/extractions/renderings stay in the local research cache. Delivered reports use original paraphrases, formulas with classification and page locators; no original screenshots are included in the public repository preparation.

The supplied JP_IMOS GitHub repository is public and initially has no license. No license was invented or added and no repository visibility/access setting changed. Documentation-only local preparation is not a license choice or permission to copy GPL/nonlicensed source.
