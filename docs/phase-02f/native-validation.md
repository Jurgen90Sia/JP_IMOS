# Physical-part native qualification — PASS for the scoped probe

Date: 13 November 2026. Actual host: **SketchUp 21.0.339 / embedded Ruby 2.7.1**. The agent invoked the local physical-part builder through the observed Ruby Console in the existing isolated JP IMOS scratch model. No installation or startup hook was added.

## Inputs and identification

Code source: merged physical-part module from main `3e2ffbbf0961152b160f6c9b80f665eea3374514`. Module file SHA256: `d4fae64d4d6cb1ea28560b58359e286fc66f9dee52f3c5d8dae9a1380eff0c2f`. Synthetic intent file SHA256: `2262fa6148ec1ff12b17944db45fc2bb19a7f93596f6af24ac0504d913f3a913`. Both independently matched the hashes written by the host probe. The first case's output content hash exactly matched standalone Ruby: `6da3f209eb7cd51811e21022cda36478278c2c7ba329fb910a4a8a08e54ef406`.

The probe required the known scratch model path, no open edit context, exactly the four original named panel groups, and their original native bounds/volumes/topology. It then added a separately named root containing four demonstration cases in one operation. It did not erase entities. Native fingerprints of the original four groups were equal before and after the test. The original scratch file was preserved; new SKP files were saved under the new output directory.

## Native results

| Case | Solids measured | Physical volume mm³, rounded | Result |
|---|---:|---:|---|
| layered_identity | 5 | 5,160,000 | PASS |
| layered_side_x | 5 | 5,160,000 | PASS |
| layered_reversed_n | 5 | 5,160,000 | PASS |
| bare_identity | 2 | 4,320,000 | PASS |

All **17 measured solids** have 8 vertices,12 edges,6 faces, manifold=true, outward_normals=true, matching bounds within0.000001mm and matching volumes within0.01mm³. Each case includes a hidden finished-envelope inspection proxy. Thus the17 measurements represent13 physical substrate/layer solids plus4 proxies; the physical volume totals exclude the proxies. Visible colors only distinguish probe solids; no texture/grain rendering is qualified.

Layered cases use600×400mm face dimensions, nominal procurement19mm, substrate18mm and near1mm/far2mm/near0.5mm layers. Finished thickness21.5mm. Native substrate volume4,320,000mm³, layer volumes240,000/480,000/120,000mm³. Identity, n=X and reversed-n frame bounds and all outward face normals passed. Floating host measurements retain their recorded numerical residuals; this is not a claim of exact SketchUp arithmetic.

Four embedded-builder negative cases also passed with value=nil: missing grain E_INPUT_CONTRACT, banded edge E_PART_PROFILE_UNSUPPORTED, reflected frame E_INVALID_GEOMETRY, work limit E_RESOURCE_LIMIT. These are request-level refusal checks, not tests of native operation abort or transaction recovery.

## Saved and inspected evidence

Local outputs remain outside the public repository in `outputs/native-physical-20261113-143257-707214/`: evidence.json, physical-probe.skp, physical-probe-reviewed.skp and physical-probe-overview.png. The initial saved SKP is355,323bytes. The agent independently read all JSON measurements and the live Console PASS output, verified input/code hashes, and inspected the PNG rendered by the actual host. The reviewed overview fits the original carcass and four new samples without clipping. The Console confirmed image=true and saved=true for that reviewed view.

Windows screenshot capture timed out; this did not prevent native Console execution or export of the host-rendered image. The PNG is a native model render, not a captured desktop UI. Original manuals, user projects and binary artifacts were not published.

## Qualification boundary

PASS applies to this local physical-part profile's embedded execution, native solid projection, four declared fixtures, four refusal cases, source/content consistency and successful scratch saves. Save/reopen persistence, resize lifecycle, undo/redo, forced native abort/recovery, semantic host mapping, canonical project dictionaries, grain textures, CEF and SketchUp2022–2026 remain **NOT RUN**. Project revision/catalog authority binding and production host acceptance remain separate unresolved contracts. This result does not produce an installable extension or RBZ.

Official API references: [Group manifold and volume](https://ruby.sketchup.com/Sketchup/Group.html), [Model operations and save](https://ruby.sketchup.com/Sketchup/Model.html), [View.write_image](https://ruby.sketchup.com/Sketchup/View.html#write_image-instance_method), [Camera](https://ruby.sketchup.com/Sketchup/Camera.html).
