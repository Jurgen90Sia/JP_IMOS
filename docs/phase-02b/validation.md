# Project-core unit 1 qualification

Date: 13 November 2026 (Europe/Berlin). Base design/plan commit: bf411e8242bf3d971f0753f0816e86a702a3bba0. Implementation branch: feat/phase-2b-project-core. Scope: codec, closed authored records, parameters and structural references only.

## Verification

Full command: `ruby test/all_test.rb` on real Windows Ruby2.7.8p225 (x64-mingw32) and Ruby3.2.9 (x64-mingw-ucrt). Final counts are recorded after the repository copy is tested. This runner includes the unchanged Phase2A engine suite and all project-core test files exactly once, in sorted order. An absolute Dir.glob returned no matches in this Windows environment; the runner uses Dir.children plus filename filtering instead, and the observed combined counts confirm discovery.

| Fixture group | Coverage / result |
|---|---|
| PC01 | Exact3/10mm and sq Unicode round-trip, stable JSON order, frozen decoded copy, caller unmodified |
| PC02 | Escaped/nested duplicate JSON keys, malformed UTF-8, closed fields/types, unknown/forbidden object data |
| PC03 | Full historical/unknown schema rejected, no silent migration or data dropping |
| PC04–PC05 | Pinned version links, repeated definition across distinct instances, unique scoped IDs and missing-version failure |
| PC06 | Required dimensions, optional default vs absent/zero/false, no injected authored override |
| PC07 | Host Float/NaN and invalid ratio rejection, exact-positive dimensions, unsupported Angle and reserved names |
| Z11 structural subset | Missing root/child/slot, slot roles, duplicate slots, shared children, cycles and unreachable nodes |
| Q01 structural subset | JSON byte/depth/work limits, record/parameter quotas, zone depth32/33, exact10,000 occurrence upper-bound and overflow |
| Existing E01–E20/N01–N24 | Phase2A expression/division fixture families retained and rerun |

PC08/Q02 and numeric zone fixtures Z01–Z10/Z12–Z15 are **not implemented by this unit**. No prepared revision or geometry acceptance is claimed. Future resolution can reject structurally valid expressions or layer bounds.

## Red/green and review

Each task began with observed failures: absent parser/entry; absent public codec; invalid parameter inputs initially succeeding; missing topology checks initially succeeding. Focused passes were committed separately. Additional regressions were observed failing for unknown host comparison callbacks, oversized raw JSON numeric tokens, lexical error priority (including indexes10 vs2), and cross-definition topology priority.

One fresh-context reviewer inspected the whole module. Two remaining medium findings concerned field-error ordering and global topology stage priority. Both were fixed and protected by regression tests. The reviewer found no remaining critical/high issues in the reviewed scope. A review is not a claim of complete formal security proof.

Hardening avoids calling == or to_json on unknown host values; copies only accepted plain Ruby/JSON types; rejects cycles while allowing repeated noncyclic shared data; checks child scheduling before growing copied collections; and enforces aggregate text-byte quota. Quote-aware numeric scanning bounds unquoted integers before JSON can materialize huge bignums. All production paths remain host/file/network independent.

## Remaining boundaries

All original14 reports and the Phase2A engine/test files are preserved. The new design/plan are additive documents19/18. No source conflict or manufacturer dimension is resolved by this codec. Exact frame conventions, physical construction, full-project migration, host acceptance/undo and distribution licensing remain separate work.

The approved plan's first-unit choice is deliberately narrower than the full Phase2B design: approximate optional numeric bindings are rejected, and revision preparation waits for a real matching ZoneSnapshot. These restrictions are explicit; there are no fake successful stubs.

## Final repository-file results

Both real runtimes passed the full combined suite: **32 tests, 706 assertions, zero failures/errors/skips** per runtime. Ruby versions: 2.7.8p225 x64-mingw32 and 3.2.9 x64-mingw-ucrt. Results were reproduced after copying final files into the intended JPMOS repository. Ruby syntax and git whitespace checks also passed. Parameter-array lexical priority received an additional observed red/green regression before final qualification.
