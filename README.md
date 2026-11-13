# JP IMOS PRO

Original parametric furniture construction research for desktop SketchUp 2021–2026, with Albanian/English user-facing language support and millimeters as canonical units.

**Current implementation: Phase 2A parametric engine and Phase 2B project-core and exact zone resolver.** The user authorized the first module after Phase 1C. There is no installable extension or RBZ. See [engine API and tests](docs/phase-02a/README.md) and [qualification](docs/phase-02a/validation.md).

## Scope and evidence

The Phase 1B package contains 14 preserved reports based on13 user-supplied manuals(555 PDF pages), official SketchUp documentation and targeted source/license research. The manuals are historical Italian/English sources; filenames do not imply Albanian content or current product compatibility.

- [Project scope](docs/project-scope.md)
- [Phase 1 report and evidence limits](docs/phase-01/14-phase-01-final-report.md)
- [49-entry source traceability](docs/phase-01/13-requirements-traceability.md)
- [Phase 1C source-conflict register](docs/phase-01/15-source-conflicts.md)
- [First-module expression/division specification](docs/phase-01/16-expression-division-spec.md)
- [Baseline preservation and publication checks](docs/phase-01/17-baseline-validation.md)

The original14 reports are frozen Phase 1B research records. Their historical statements that documents are uncommitted or that no HEAD exists describe that earlier state; they do not describe a published baseline after the initial commit. Phase 1C evidence disposition and narrowed readiness are additive in 15–17. No older report is silently rewritten.

## Next permitted technical scope

The **Parametric Expression and Linear Division Engine** and **Project-Core Contract** are implemented. Its JP grammar has explicit types, reference contexts, limits and unsupported historical cases. This is an original supported subset; construction, drawings and host integration remain future work.

Drilling, CNC, CAM, nesting, toolpaths and machine postprocessors are excluded. No affiliation with proprietary imos software is implied.

## Source and license handling

Source PDFs, extracted text, rendered figures, credentials and generated artifacts stay outside version control. The public baseline contains original analysis and brief filename/page/formula references. No third-party implementation or proprietary source assets are vendored.

No project distribution license has been selected in this phase. MIT/BSD candidate terms do not license this repository automatically; GPL or unlicensed candidate code is not incorporated. See [license audit](docs/phase-01/06-license-audit.md).

The project-core codec/validation unit is authorized; exact zone resolution is implemented and host integration remains later work. The 14 historical Phase 1B reports are unchanged; their prior authorization/status statements remain dated research records.


## Project-core and zone design

[Phase 2B project-core and hierarchical-zone design](docs/phase-01/18-project-zones-spec.md) specifies lossless exact values, pinned definitions, positive partitions, explicit reservation slots, independent layers and prepared revisions. The user approved this design and its first-unit plan. The implemented subset is documented in [Project-Core API](docs/phase-02b/README.md), with [qualification](docs/phase-02b/validation.md). Run the combined suite with `ruby test/all_test.rb`. Zone arithmetic is documented in [Zone Resolver API](docs/phase-02b/zones.md); [Prepared revisions](docs/phase-02b/revisions.md) now return a matching immutable document and zone snapshot.

The next arithmetic slice is described in the [exact zone-resolver implementation plan](docs/phase-01/20-zone-resolver-implementation-plan.md). It reuses the merged project-core contracts; revision preparation is documented separately and SketchUp geometry remains future work. This plan was approved and executed; see [zone qualification](docs/phase-02b/zones-validation.md).

The [prepared-revision plan](docs/phase-01/21-prepared-revisions-implementation-plan.md) closes the pure-core revision contract. See [revision qualification](docs/phase-02b/revisions-validation.md); preparation does not publish accepted host state.
