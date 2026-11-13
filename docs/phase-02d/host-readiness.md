# Host integration readiness: BLOCKED dependencies retained

Date:13 November2026. This is a dependency audit, not a host implementation or host test. It extends the existing architecture/model/support reports08/09/07 using the current code/evidence; no application window/model was opened or modified in this task.

The pure carcass design-state module is independently qualified. Production host application/export remains **BLOCKED** until the contracts below are resolved. A good preview, matching revision or source digest does not independently establish these guarantees.

| Dependency | Current evidence | Required closure |
|---|---|---|
| Material/catalog authority | Materials::Context explicitly returns caller_declared_unverified_catalog. UUID/version shape is checked; no catalog existence/compatibility registry is resolved. | Versioned supported material/characteristic records with reference resolution, provenance and explicit finished/substrate/surface/edge policy; reject missing/unsupported refs before host/export acceptance. No manufacturer units/profile defaults guessed. |
| Accepted PartSpec/material snapshot | Rectangular converter provides finished-envelope geometry and scoped preview data; full substrate/finished/face/edge/grain/reporting PartSpec contract from report09 is not implemented. | A validated supported physical snapshot profile binding actual parts/material contexts and source revision, with unsupported geometry/material cases failing clearly. Do not relabel bbox/preview data as a full accepted furniture Snapshot. |
| Canonical host persistence | Design currently owns canonical authoring in memory/JSON only. No namespaced model-dictionary schema, entity mapping or accepted/session compare-and-swap is implemented. | Specify exact stored schema/version/state hash/revision and mapping ownership; one geometry+persistence operation; stale/reentrant/undo/reopen/conflict policy and recovery. No unsynchronized parallel sidecar authority. |
| Real host qualification | Standalone Ruby2.7/3.2 tests pass; these do not exercise SketchUp Model/Entities/Undo/open/save or target CEF. Report07 host matrix remains NOT RUN. | Isolated scratch-host tests on supported actual builds after upstream contracts are defined; record exact host/Ruby versions and undo/abort/save/reopen evidence without changing user work. |

## Refusal and scope rules

- Current authoring decode/encode accepts only jpimos.carcass-design/1. Actual carcass-preview/design-snapshot/plain-core imports fail E_SCHEMA_UNSUPPORTED; unknown fields fail E_INPUT_CONTRACT. No derived input becomes authoring through silent conversion.
- A future host adapter/exporter must refuse incompatible or unresolved schemas/material/geometry using stable typed diagnostics. Proposed future codes: E_HOST_CONTRACT_UNRESOLVED, E_MATERIAL_REFERENCE_UNRESOLVED, E_PART_PROFILE_UNSUPPORTED. These are interface proposals, not fictitious implemented APIs.
- Never execute an unqualified loader, write an active model dictionary, create an RBZ or add a production export route as a workaround for these dependencies.
- Permitted next work is closing the material/snapshot/persistence contracts and isolated read-only inspection. Any proof-oriented host test must use a separate scratch model after its input profile/transaction boundary is defined.

The blocked status applies to host/export readiness, not the completed pure data module. No source conflict, license route, manufacturer profile or native-host compatibility is invented by this audit.
