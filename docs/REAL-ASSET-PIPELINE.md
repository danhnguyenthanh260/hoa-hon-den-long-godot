# Real-reference 3D Asset Pipeline

## 1. Rights gate

| Source | Raw image in repo | Derivative game asset | Rule |
|---|---:|---:|---|
| Team-captured | Yes, with site/privacy clearance | Yes | Preferred |
| CC0 / public domain | Yes | Yes | Preferred |
| CC BY | Yes, with author, link, license, changes | Yes | Accepted |
| CC BY-SA | Conditional | Conditional | Separate distribution review |
| CC BY-NC | No commercial use | No | Reject |
| CC BY-ND | Editing/extraction conflicts | No | Reject |
| Wikimedia Commons | Per file only | Per file only | Commons is not a blanket license |
| Stock media | Usually no raw redistribution | EULA-specific | Do not commit raw by default |
| Street View / Earth | No extraction, tracing, or stitching | No | Scouting only |
| Search/Pinterest/social media | No | No | Reject |

Primary policy sources:

- [Creative Commons BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- [Creative Commons CC0](https://creativecommons.org/publicdomain/zero/1.0/)
- [Wikimedia reuse guidance](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia)
- [Google Geo guidelines](https://about.google/brand-resource-center/products-and-services/geo-guidelines/)

This is a production policy, not legal advice. Unclear rights stop the asset.

## 2. Capture dossier

Minimum for a simple prop:

- front, rear, left, right;
- 45-degree diagonals;
- top/bottom when visible;
- macro views of joints, hinges, fasteners, rim, feet, and wear;
- two non-collinear measured dimensions;
- gray card/color checker where color fidelity matters;
- camera map and contact sheet.

Architecture additionally requires:

- elevations, roof line, underside and circulation;
- bay spacing, wall/column thickness, floor and handrail levels;
- joinery and module repetition;
- material boundary and drainage/weathering evidence;
- dated restoration state;
- explicit `unknown` coverage.

Photogrammetry capture uses overlapping closed loops at low, middle, and high
angles. A surface must appear in at least two useful images. Keep angle changes
below roughly 30 degrees and move from whole object to detail.

Sources:

- [RealityScan capture guide](https://rshelp.capturingreality.com/en-US/tutorials/takingpictures.htm)
- [Agisoft image capture guidance](https://agisoft.freshdesk.com/support/solutions/articles/31000149337-how-to-take-images-and-some-tips)

## 3. Method selection

| Asset type | Method |
|---|---|
| Walls, columns, roofs, doors, stairs, modular joins | Measured manual modeling |
| Old stone, brick, timber, statue, irregular terrain | Photogrammetry high-poly + retopo/bake |
| Hero landmark | Measured shell + scan detail + manual join correction |
| Repeated background module | One verified manual master + authored variants |
| Loose natural clutter | Scan, procedural, or reviewed AI base |
| Character close-up | Sculpt/scan/character pipeline; AI only for exploratory base |

## 4. Production stages

1. Freeze raw reference and SHA-256 manifest.
2. Classify view coverage and rights.
3. Solve scale from at least two non-collinear measurements.
4. Match cameras and draw measured elevations/sections.
5. Build high-poly evidence model or measured shell.
6. Retopologize by real construction modules and gameplay needs.
7. Set pivots and snap points at actual connection locations.
8. UV with stable texel density; remove lighting from base color.
9. Author OpenGL normal, roughness, metallic, AO, and packed ORM where useful.
10. Create LOD0/1/2/3 targets near 100/50/20/5 percent and review silhouette.
11. Author primitive/convex collision; concave trimesh only on controlled static geometry.
12. Export GLB/glTF 2.0 and import with tangents, mesh LOD, shadow mesh, and UV2 settings reviewed.
13. Run 360, fixed-angle, wireframe, material, collision, gameplay-scale, and performance QA.

Godot sources:

- [3D formats](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)
- [3D import configuration](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)
- [Standard and ORM materials](https://docs.godotengine.org/en/4.5/tutorials/3d/standard_material_3d.html)
- [Mesh LOD](https://docs.godotengine.org/en/4.5/tutorials/3d/mesh_lod.html)
- [Visibility ranges](https://docs.godotengine.org/en/4.5/tutorials/3d/visibility_ranges.html)
- [Occlusion culling](https://docs.godotengine.org/en/4.5/tutorials/3d/occlusion_culling.html)
- [Collision shapes](https://docs.godotengine.org/en/4.5/tutorials/physics/collision_shapes_3d.html)

## 5. Acceptance thresholds

Project thresholds, not claims from the linked tools:

| Gate | Hero | Gameplay | Background |
|---|---:|---:|---:|
| Primary dimension error | <=1% | <=2% | <=5% |
| Camera-overlay silhouette error | <=2% image dimension | <=3% | <=5% |
| Fixed views | 4 sides + 4 diagonals + needed top/bottom | 4 sides + diagonals | 4 sides |
| Visible gameplay-distance seam | 0 | 0 | Minor only if outside focus |
| Non-manifold/flipped normals | 0 | 0 | 0 |
| Collision penetration or false blockage | 0 | 0 | 0 |
| Baked light/highlight in base color | 0 | 0 | 0 |

Every asset review package includes:

- 36-frame turntable, 10-degree steps;
- fixed 0/45/90/135/180/225/270/315 degree views;
- albedo, lit PBR, normal, roughness, wireframe, and collision passes;
- top/bottom and hidden-face check;
- camera overlays against canonical references;
- player-scale and worst-lighting screenshots;
- independent reviewer decision.

## 6. Meshy decision matrix

| Asset | Meshy use | Final authority |
|---|---|---|
| Rock, root, sack, debris, non-symbolic pottery | Conditional base/filler | Manual cleanup and QA |
| Supernatural creature | Concept/high-poly base | Manual silhouette, anatomy, rig, materials |
| Distant non-speaking NPC | Conditional body base | Rebuilt face/hands/clothes/rig |
| Minh or close speaking NPC | No final Meshy asset | Sculpt/scan/character production |
| Heritage house, facade, bridge, roof, column | No | Measured modeling and scan evidence |
| Door, stair, moving/connecting object | No | Measured clearance, pivot, and joins |
| Hero lantern, altar, ritual object | Concept only | Real construction evidence |
| Small ornament | High-poly bake only | Manual motif correction and retopo |
| Sign, calligraphy, emblem | No | Verified human-authored text/art |
| Distant window filler | Yes after review | Silhouette/poly/performance QA |

Meshy Multi-Image currently accepts up to four views and exposes remesh,
polycount, PBR, and GLB options. This does not make its output measured or
historically correct.

- [Meshy Multi-Image API](https://docs.meshy.ai/en/api/multi-image-to-3d)
- [Meshy terms](https://www.meshy.ai/terms-of-use)

Recheck terms before each production batch. Do not upload proprietary,
restricted heritage, private face, or unreleased source material to a plan that
permits training or public sharing.

### Meshy input contract

```text
front, rear, left, right images of the same isolated object
neutral perspective and consistent orientation
known real-world dimensions recorded outside Meshy
image_enhancement=false
remove_lighting=true
enable_pbr=true
auto_size=false
save_pre_remeshed_model=true
target_format=glb
```

### Prompt: market filler

```text
Single freestanding Vietnamese market basket, hand-woven bamboo construction,
physically plausible crossing strips and rim joint, asymmetrical use wear,
empty interior, no text, no logo, no person, isolated object, neutral background,
real-world height 0.42 m. Preserve thin gaps between weave. This is a base mesh;
do not add decorative motifs absent from the reference.
```

### Prompt: material pass

```text
Photorealistic aged Hội An material based strictly on the supplied object:
sun-faded natural bamboo, uneven hand weaving, localized humidity darkening,
small edge wear, non-metallic, physically plausible roughness, no painted text,
no logo, no fantasy ornament, no baked shadows, no highlights, neutral color.
Preserve geometry and material boundaries from the reference.
```

### Prompt: supernatural base

```text
Single humanoid creature base mesh for an original cinematic psychological
horror game. Human proportions remain plausible at first glance; subtle
asymmetric shoulder, slightly overlong distal fingers, damp cloth layers, no
gore, no weapon, no text. Neutral A-pose, separated fingers and limbs, clean
full-body silhouette. Do not copy any existing game character.
```

Mandatory post-Meshy work:

- scale, pivots, transforms;
- hidden/fused geometry, manifold, normals and tangents;
- topology, UV and baked-light removal;
- PBR calibration;
- face/hand/anatomy and rig deformation;
- collision, LOD, GLB import, 360 review and performance.

## 7. Performance contract

- 1080p/60 target: 16.67 ms total frame.
- Vertical-slice p95 CPU and GPU budgets: each <=13.5 ms.
- Profile the worst route: long alley, fog/rain, many visible lights, open
  interiors, NPCs, reflections, and chapter transitions.
- VRAM peak below 75% of the agreed target GPU.
- 4K only for justified hero assets; 2K gameplay; 1K/atlas clutter.
- Bake most architecture lighting; preserve dynamic lights for gameplay and
  cinematic change.
- Use occlusion for alleys/interiors, but author simplified static occluders.

## 8. Current real-reference batch

`reference-library/chua-cau-2024/` is the first copyright-verified batch. It records the
post-2024-renovation state and cannot silently stand in for an older historical
version. Its initial series covers one canal-facing elevation plus both portals;
opposite elevation, diagonals, roof, underside, joinery, and measured dimensions
remain separate evidence gates. The files contain identifiable people, so public
redistribution remains pending a personality-rights decision even though the
copyright license is CC BY 4.0. Reference raster files use Git LFS.
