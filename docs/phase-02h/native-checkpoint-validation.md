# Native draft checkpoint save/reopen — scoped PASS

Date:13 November2026. Host SketchUp21.0.339, embedded Ruby2.7.1, backend `2.7.1-x64-mswin64_140-Math`. Agent-executed one-shot probe through the observed Ruby Console. Code source main `0346eb31c523736a30177e4f8efaf391ef079bc4`.

## Boundary

This qualifies draft source JSON in a **probe-only** model dictionary, not a production namespace or accepted project/geometry mapping. Dictionary `JP_IMOS_PRO_PHASE_02H_CHECKPOINT_PROBE`, key `draft_checkpoint_json`. Existing visible geometry is a collection of earlier samples; the stored800mm authored project is a separate draft. The probe does not claim that those visible samples represent its accepted snapshot.

The synthetic authoring source was encoded freshly with the actual embedded numeric backend. The standalone2.7.8 checkpoint was not silently migrated or relabeled. All successful encode/decode operations used the same explicit native policy/backend.

## Preservation and test

The first attempt stopped before any dictionary write because the model had unsaved changes. A later diagnostic found an open edit context on the known scratch top panel. That context was closed without geometry removal, and current contents were preserved by Save As to a new `source-before.skp`; save=true, modified_after_save=false, geometry_unchanged=true. The existing reviewed source file was not overwritten. Initial blocked evidence remains local alongside the successful attempt's evidence.

The successful probe required the preserved scratch path, five named top-level JP IMOS groups, no open edit context/unsaved changes and an absent probe dictionary. It built and decoded the checkpoint before mutation, wrote only the JSON attribute in one native operation, read/decoded it again and saved a new `checkpoint-probe.skp`.

For the persistence test it opened `source-before.skp` and confirmed that the probe dictionary was absent. It then opened `checkpoint-probe.skp` and retrieved/decoded the persisted attribute. Both `Sketchup.open_file(..., with_status: true)` calls returned LOAD_STATUS_SUCCESS(0). This sequence avoids treating a same-document memory reread as disk persistence.

## Observed results

| Check | Result |
|---|---|
| Native checkpoint encode/decode and dictionary round-trip | PASS |
| Native source-policy/revision/registry/physical snapshot rebuild | PASS |
| SKP save | true |
| Reference and checkpoint file loads | status0 / status0 |
| Dictionary absent in reference | true |
| Checkpoint bytes preserved after reopen | true |
| Rebuilt snapshot identical after reopen | true |
| Geometry unchanged after write and reopen | true / true |
| Reopened authored revision / physical parts | 8 /4 |

Checkpoint size5,127bytes; SHA256 `a90fb11787577c6a451d08dea6221edcc0e2ca0c7ecc7144335b5bf4041f6ab1`. State SHA256 `71052fbbd1d7d72e76b67acb9040b41c4fa660504f1e1d1ef166644a4d5e2042`; native snapshot SHA256 `e5acfcac822e590fd2c0dcde6b116e8a1d9b6a04eb0337fd1581f9b9bcdb25a0`.

The unchanged-geometry proof traverses nested groups, transforms, hidden flags, face vertices and normals, using6 decimal mm coordinate rounding and12 decimal transform/normal rounding. It compares against the preserved current scratch copy, not against the historical file before any later user edits. Geometry fingerprint SHA256 `7e8a4c76cb2f880b61b51295aa687bda3aecaa9d6479f3c6ea173b246021889a`.

The agent independently inspected the native JSON report and source-preservation report, matched the stored checkpoint file hash and all five loaded module byte hashes against local source. The saved checkpoint SKP is365,114bytes; preserved source SKP363,824bytes. Local artifacts remain outside Git under `outputs/native-checkpoint-probe-02/`: evidence.json, source-preservation.json, host-checkpoint.json and the two SKPs. No proprietary source, user project or binary artifact is published.

## Still unqualified

This is same-process SKP reopen, not application restart or automatic plugin discovery. No installable loader/RBZ was added. Undo/redo, forced native abort/recovery, stale/reentrant accepted-state CAS, entity mapping and atomic accepted geometry+checkpoint replacement remain NOT RUN/unresolved. Manufacturer authority, unsupported geometry and numeric-backend migration are unchanged. Production host readiness remains BLOCKED; this closes only controlled draft dictionary storage and reopen reconstruction.

Official APIs: [Model attributes/operations/save](https://ruby.sketchup.com/Sketchup/Model.html), [Sketchup.open_file](https://ruby.sketchup.com/Sketchup.html#open_file-class_method).
