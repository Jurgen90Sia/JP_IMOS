# Prepared revision qualification

Date:13 November2026 (Europe/Berlin). Base integrated resolver:ea15eb59d4f04e3454b60a4ff118eeca0f109fd5. Feature branch:feat/prepared-project-revisions. Scope: pure revision preparation, not host acceptance.

| Evidence | Verified behavior |
|---|---|
| PC08 | Stale expected revision rejected before bad replacement arithmetic; valid7->8 matching document/snapshot |
| Q02 | Exact safe-integer maximum exhausted; maximum-minus-one prepares maximum; no-op rejects even reordered Hash keys |
| Identity/version | Project/replacement-revision mismatch rejected; same-version definition edits rejected; new version and updated pin succeeds |
| Authored semantics | Locale/origin edits and explicit optional-input presence produce a new revision; caller authoring shape retained |
| Immutability/atomicity | Frozen/reused input accepted; returned document/snapshot immutable; failed math returns no partial value or changed input revision |
| Shared limits | Both validations+comparison fit10000 work in the fixture, candidate resolution exhausts that same quota; default cap succeeds; recovery independent |
| Text quota | Both documents fit4096 bytes individually, combined copied text exceeds request quota and fails |
| Diagnostics | Current/replacement pointers scoped; division-by-zero span/grammar/context retained; malformed backend policy stays structured |

The initial absent revision module and absent public operation were observed failing before their respective implementations. Focused guard/no-op tests then passed, followed by complete candidate/snapshot tests. Existing48-test resolver/project/engine suite remains part of the combined runner. Task3 added boundary qualification and reran all tests.

One fresh-context whole-branch static review found no concrete actionable issues in guards, no-op semantics, local version checks, shared budgets, ownership/freezing or scoped diagnostics. The reviewer did not repeat the unchanged suite or inspect later-added Task3 tests; those were executed on both runtimes. No independent formal proof or host test is claimed.

## Runtime results

Full `ruby test/all_test.rb`: **58 tests,1012 assertions,zero failures/errors/skips** on each real Windows runtime:Ruby2.7.8p225 x64-mingw32 and Ruby3.2.9 x64-mingw-ucrt. Final repository-file results and syntax/whitespace checks are captured before commit/integration.

## Explicit limits

Current/replacement pair checks cannot enforce historical definition immutability across an absent registry. Preparation does not certify a host-accepted current snapshot or serialize acceptance. Two concurrent preparations can both describe next8; future acceptance must reject a stale base. No source-manual rule, construction formula, geometry or UI behavior is invented here. Historical14 reports remain unchanged; no proprietary assets or new runtime dependencies are committed.
