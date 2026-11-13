# Rectangular physical part — original JP supported profile

Date: 13 November 2026. This is a PROPOSED original contract implemented under standing autonomous authorization. It adds no interpretation of unresolved imos formulas.

## Scope and contract

`JPImosPro::Physical::RectangularPart.build(intent:, limits: {})` prepares one explicit unbanded rectangular part. It uses the existing exact rational mm geometry and finished material stack. It does not accept project/session state, verify catalog authority, bind a project revision, prove that the supplied recipe matches its zone, publish host state, or constitute an accepted general PartSpec. Those checks belong to the later owning project profile. Returned status is `prepared_unbound_part`; material reference status remains `caller_declared_unverified_catalog`.

Input is a closed plain-data record:

| Field | Contract |
|---|---|
| schema | `jpimos.rectangular-part-intent/1` |
| id | Canonical UUID supplied by the caller; no generated or host entity ID |
| occurrence_ref | Exactly article_instance_id UUID and role left/right/top/bottom |
| owner_zone_ref | Exactly article_instance_id UUID and authored_zone_id UUID; article ID must match occurrence_ref |
| rule_version | Existing `top_bottom_between_sides-v1` |
| face_size | Exactly two positive exact Length/mm DTOs, u and v |
| frame | Finished-envelope origin as three exact Length/mm DTOs and a right-handed signed-permutation basis, columns u/v/n; same supported frame subset as existing geometry |
| characteristic | Existing closed additive_finished_stack-v1 authored material context, with explicit nominal_purchase_thickness, finished_substrate_thickness and dimensional_surfaces |
| grain | Exactly substrate and surfaces. substrate is explicit none/u/v; surfaces is an equally long array of none/u/v values aligned by index with dimensional_surfaces. none means an explicit absence of directional constraint, never UNKNOWN. |
| edges | Exactly u_min/u_max/v_min/v_max, each exactly `{kind: none}`. No band material/thickness/allowance is silently discarded. |

Output `jpimos.rectangular-physical-part/1`, profile `jp-rectangular-unbanded-v1`, contains id, occurrence_ref, owner_zone_ref, rule_version, status, resolved characteristic, grain, edges, finished_dimensions, substrate_dimensions, finished_geometry, substrate_geometry, surface_layers, actual_volume and content_sha256. Geometries use the existing exact rectangular solid/vertices/face loops/bounds/volume DTO. A layer has source_index, side, material_ref, grain and geometry. Hash covers canonical JSON of every other output field. No date is semantic.

## Geometry and ordering

Let A=u*v, S=finished substrate thickness, N=sum of near layer thicknesses and F=sum of far layer thicknesses. Finished thickness T=N+S+F. Nominal purchase thickness does not enter geometry. Both in-plane substrate dimensions equal u/v for this explicitly unbanded profile.

The frame origin is the finished n_min envelope. Substrate starts at offset N along the frame's n column. Near layers occur from the outside n_min face toward the substrate, preserving their relative input order. Far layers occur from substrate toward n_max, preserving their relative input order. Interleaved near/far declarations keep their input indices in the returned layer array. Each side has its own cursor. Layers occupy disjoint slabs, and A*S + sum(A*layer thickness) = A*T. This explicit order is a JP convention; no proprietary historical order is claimed.

Reference example: origin[100,200,300], identity basis, u600/v400, nominal19, S18, near1 + near0.5, far2. T21.5; substrate z301.5..319.5; finished z300..321.5. Volumes: substrate4,320,000; near240,000 and120,000; far480,000; total5,160,000 mm³. A reversed n column changes article offsets, not local grain axes or thickness arithmetic.

Unsupported schema -> E_SCHEMA_UNSUPPORTED; unknown/missing/malformed fields -> E_INPUT_CONTRACT; unsupported band kind/rule -> E_PART_PROFILE_UNSUPPORTED; mismatched occurrence/zone article -> E_REFERENCE_MISMATCH. Existing material/quantity/geometry diagnostics remain stable and point into their existing scoped fields. A shared CoreBudget covers copying, material resolution, every solid, canonical hashing and freezing. Any error returns value=nil, with no caller mutation or partial physical part.

## Approaches and implementation plan

Chosen: a small local physical-part builder, reusing exact geometry and material resolution. Returning only dimensions would omit substrate/layer solids. Jumping directly to accepted project PartSpecs would conflate this local proof with unresolved authoring/revision/registry/host ownership. No new dependency; Ruby 2.7 minimum.

Task 1 files: create `lib/jp_imos_pro/physical/rectangular_part.rb`, `test/physical/rectangular_part_test.rb`; update README and current host-readiness dependencies.

- [x] RED: test absent entry point, bare panel, asymmetric/interleaved rational layers, reversed basis, explicit grain/edge coverage, incompatible inputs, caller ownership, hash behavior and resource exhaustion.
- [x] Implement bounded owned validation and exact finished/substrate/layer geometry; no eval, fallback thickness, imported derived data or catalog authority claim.
- [x] GREEN: full suite on real Ruby 2.7.8 and 3.2.9, including all101 baseline tests.
- [ ] Independent read-only branch review, fix substantive findings with regression tests, record evidence and publish/integrate under standing authorization.

Review focus: absent grain mistaken for none; banded input silently treated as unbanded; near offset applied in global Z rather than part n; interleaved layers advancing the wrong side; imported physical output becoming authoring. Each has a targeted test. Project binding and host qualification remain separate dependencies.

## Qualification ledger

Base main `2257e5e52addc4f666d6fc0c220db055f6c60585`, clean; baseline101 tests /1,505 assertions passed. Reused the clean linked checkout on new branch `feat/rectangular-physical-part`. No existing project files or user models were changed.

Task1 RED: eight test methods reported the missing `Physical` entry point before implementation. First GREEN:8 tests /89 assertions. Added side-panel n=X and aggregate-budget qualification. Final full suite on real Ruby2.7.8 and3.2.9:111 tests /1,607 assertions, no failures/errors/skips. All101 baseline tests retained. At work8,000 the bare part succeeds but the complete three-layer preparation fails without a partial result; fresh default-budget preparation succeeds. No expected-output or schema ruling was needed.

The implementation is original pure Ruby. No new library/runtime dependency, plugin startup code, RBZ, native model persistence, production export, proprietary PDF or figure was added. General banded/profile/sweep parts and project-bound physical acceptance remain unsupported. Native execution of this new module is NOT RUN.
