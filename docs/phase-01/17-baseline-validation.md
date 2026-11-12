# Phase 1C baseline preservation and validation record

Date:12 November 2026. Target:[Jurgen90Sia/JP_IMOS](https://github.com/Jurgen90Sia/JP_IMOS), branch main, local checkoutC:\Users\arkitekt2\Documents\JPMOS.

## Preserved starting state

Initial inspection observed an unborn main branch, no published commit, origin fetch/push both set to the exact supplied HTTPS URL, and 14 untracked Markdown reports under docs/phase-01. There were no other worktree files or application dependencies. The remote refs endpoint independently returned409 empty repository before publication. No reset, clean, delete, rename, rebase orforce-push is part of this baseline workflow.

Every original report was compared byte-for-byte against the completed Phase 1B package. All 14 matched. They remain unchanged; additive files15–17 contain Phase 1C conclusions. The historical“uncommitted/no HEAD” statements in the preserved reports remain historical context, not current branch assertions after publication.

## Original report integrity manifest

| Preserved file | SHA-256 of original working-file bytes |
|---|---|
| docs/phase-01/01-source-inventory.md | 01dbdef7c10a464a15e3915ef5ed9f2933f282429630997250e9da3aa836c021 |
| docs/phase-01/02-imos-feature-matrix.md | 346c2bab56a6079d0be7240a19c22304af47cc85d61d518ccf92fcdf048f5f74 |
| docs/phase-01/03-formulas-and-variables.md | 5957482674d57276d5f784d62fd7d7cb6aedb938c3c103e650f555165f01ee24 |
| docs/phase-01/04-construction-rules.md | f65566b3edc59768c306b1b919d084924c53074c1126c9a9cfbaf3d2bf07cdd8 |
| docs/phase-01/05-github-research.md | e29e75eb1a68c004c7e44369eb90a90176e9d214ad5c537b02152824aa2ac298 |
| docs/phase-01/06-license-audit.md | 33e9e9f6d46e0cfb46bcf654afcc00b55c5bfeb247af150e9452dcaa94b9728a |
| docs/phase-01/07-sketchup-compatibility.md | 72239f35ed7f5cede5647a412ba59bebd204c1befbff00fc9b1fa785a2577ea9 |
| docs/phase-01/08-system-architecture.md | 427c4d894eb8e101f372013e6ccbfb65f6c5b69cb81d5682cccff2a82d45e6ee |
| docs/phase-01/09-data-model.md | b6ef25c69b2d3c0c3f393473be96bdde7262399840954356f3c9024ec81eb93d |
| docs/phase-01/10-module-dependencies.md | ddfa7474ae4a18629488832ca26065cc2e534a60d46cf3347d8ee31ac78804e9 |
| docs/phase-01/11-risk-register.md | 15b9810b32da18ff5d581313821417dff4efa03c9d3125519df50f546c274229 |
| docs/phase-01/12-implementation-roadmap.md | ae5e742e9708e9e5159ec65afc3ce0f6a1d33e27de7de58dba75b3f306b9350c |
| docs/phase-01/13-requirements-traceability.md | ec4aa3958a869e8e004b97c2a70afadee9ee1ac1db7bc088cc8fca2849d27a36 |
| docs/phase-01/14-phase-01-final-report.md | d93c031d81f81bd95d9d6169f1481e35fd771f84ec449e9d70e44198497a1f56 |

## Public-content review

The candidate baseline is an explicit20-file allowlist:14 preserved reports, README.md,.gitignore, docs/project-scope.md, and additive reports15–17. Only Markdown and the ignore file are eligible. No PDF, source extraction, rendering, screenshot, figure, archive, credential, binary, plugin or production source file is eligible.

The14 reports were reviewed as original analysis/architectural proposals with brief source locators/formulas. Their Markdown contains 0 image embeds and 0 recognized credential signatures. A supplementary case-normalized12-word source-page n-gram comparison found0 matches against the cached13-manual extraction. This is a reproduction screen, not a proof of originality or blanket copyright clearance; formulas/names/page references are also assessed in context. No original figure or full manual text is published.

The .gitignore excludes all PDFs/CAD sources/archives, research cache locations, figure formats, credentials, temporary/generated output and machine-local configuration. Future original figures orrelease assets require explicit review and narrowly scoped exceptions rather than disabling source protection.

## Traceability and specification review

All 49 original trace rows were reviewed and cited page indices checked against actual PDF page counts. Source hashes remain in 01; all 13 cached PDF hashes still match the Phase 1B extraction inventory. Total555 pages remains the correct inventory count. Fifteen source-conflict/contract categories plus the context-dependent finished-stack/reporting distinction are explicitly recorded as SC01–SC16 in 15.

The first-module spec16 separates JP engineering expressions from affine division terms, declares inputs/outputs/units/dependencies/errors/limits, and includes 20 positive and 24 negative/boundary fixtures. Repetition/quantization support is deliberately bounded. Source-conflicted or unknown syntax cannot silently fall back to Ruby evaluation. A fresh builder review identified negative-affine-coefficient, scalar-lifting andapproximate-number contracts; these were specified explicitly, including rejection ofinexact division inputs. No engine code, tests or host integration is created; future fixtures are not reported as passing plugin tests.

## Publication verification protocol

Stage only the 20 declared files after rechecking the 14 hashes; disable automatic line-ending conversion for that staging operation so original bytes are preserved. Inspect staged filenames/content and secret/proprietary-format screens before committing.

Required initial commit message:`docs: establish JP IMOS PRO phase 1 research baseline`.

Push only main toorigin/main with a normal fast-forward push. Do not force if the remote has changed. Successful command output alone is insufficient:compare local HEAD togit ls-remote origin refs/heads/main, then independently inspect the exact commit/tree through GitHub. Verify20 expected paths, all 14 report blobs, andabsence of proprietary/production files. Confirmclean worktree.

The exact resulting commit SHA and observed remote checks are reported outside this committed file to avoid an impossible self-referential commit hash. This record contains no invented future SHA orclaim that a push succeeded before it was verified. Source-conflict evidence remains PARTIAL evenwhen Phase 1C's documentation/publication tasks pass.

No Phase 2 implementation starts without explicit user authorization.

