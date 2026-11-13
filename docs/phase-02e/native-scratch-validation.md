# SketchUp scratch geometry qualification

Date: 13 November 2026. Scope: one static finished-envelope fixture, separate scratch model only. Not a production extension integration test.

The user executed a locally prepared one-shot Ruby probe through the SketchUp Ruby Console after automatic focus/typing failed. Native evidence reports SketchUp 21.0.339, embedded Ruby 2.7.1, empty initial model path and zero initial entities. The probe loaded the existing preview JSON, created four groups with six outward faces each in one native operation, checked them and saved a scratch SKP. No startup loader, model dictionary or extension was installed.

| Panel | Minimum mm | Maximum mm | Native volume mm³ (rounded) | Native checks |
|---|---|---|---|---|
| left | 0,0,0 | 18,560,720 | 7,257,600 | PASS |
| right | 582,0,0 | 600,560,720 | 7,257,600 | PASS |
| top | 18,0,702 | 582,560,720 | 5,685,120 | PASS |
| bottom | 18,0,0 | 582,560,18 | 5,685,120 | PASS |

Each group: 8 vertices, 12 edges, 6 faces, manifold=true and outward_normals=true. Bound tolerance 0.000001mm, volume tolerance 0.01mm³. Total volume 25,885,440mm³. save returned true; saved SKP is 338,171 bytes. The inspected source SHA256 is `827d957a5513ce6265ec933b8bfb99dd486bb762195ac197d4760d2b78ddb496` and independently matches the preview JSON. These are actual host measurements with floating conversion, not claims of exact host arithmetic.

Local evidence remains outside version control under this chat's `outputs/sketchup-native-probe/evidence.json` and `probe.skp`; the preview is `outputs/phase-02c/carcass-preview.json`. No original manual or proprietary figure is included. On subsequent live inspection the returned window title was `probe - SketchUp Pro 2021`; Ruby Console output contained the same probe command and PASS evidence path. Both screenshot capture attempts timed out with `window capture timed out: timed out waiting on channel`; no new visual inspection is claimed.

Not qualified: resizing in the host, undo/redo, abort recovery, save/reopen comparison, SketchUp 2022–2026, CEF, semantic entity mapping, materials/textures/edges, substrate solids or production persistence. This fixture verifies the current finished-envelope geometry subset only.

Official APIs used: [Group manifold and volume](https://ruby.sketchup.com/Sketchup/Group.html), [Model operation and save](https://ruby.sketchup.com/Sketchup/Model.html), [Entities.add_face](https://ruby.sketchup.com/Sketchup/Entities.html#add_face-instance_method).
