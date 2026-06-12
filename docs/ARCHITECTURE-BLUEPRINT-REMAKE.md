# Architecture blueprint remake pack

In this document, "remake" means: reconstruct from real-world Hoi An buildings
and translate that reconstruction into game assets. It does not mean remaking
the current in-game primitive models.

Purpose: use the blueprint pack as construction guidance for converting
real-world Hoi An architecture into game-ready landmarks.

## Reference layer stack (đọc theo thứ tự này)

| Layer | Files | Vai trò |
|---|---|---|
| **1. Reality reconstruction** | `ref-31..35` (chờ sinh) | Orthographic tái dựng từ thực tế — tỷ lệ, module, vật liệu; confidence-annotated |
| **2. Translation rules** | `docs/REALITY-TO-GAME-RULES.md` | Cái gì phải đúng, cái gì được simplify; ghi rõ lỗi hiện tại cần sửa |
| **3. Photo atmosphere** | `ref-12..18` | Màu sắc, vật liệu, độ phong hóa — áp lên sau khi khối đúng |
| **4. Build-spec V2** | `ref-26..30` | Checklist dựng hình game; module order, collision |
| **5. Blueprint overview** | `ref-19..25` | QA nhanh shape language; không đủ chi tiết để dựng |

Quy trình: đọc Layer 1 + 2 → ra khối đúng tỷ lệ → áp Layer 3 (màu) → kiểm
Layer 4 (checklist) → render houseview so Layer 5 → commit.

Important distinction:

- `Screenshots/ref-19.png` through `ref-25.png` are overview/QA sheets. They are
  useful for quick shape language and evidence requirements, but they are not
  detailed enough by themselves for final construction.
- `Screenshots/ref-26.png` through `ref-30.png` are the build-spec V2 sheets.
  Use these as the current reality-to-game translation checklist: footprint,
  elevation, section, module order, collision/path requirements, material
  identity, and screenshot proof.

These are not legal construction drawings and should not be treated as measured
survey documents. For a true real-world architectural dossier, the missing layer
is field measurement: survey plan, measured elevations, measured sections,
material sampling, and detail drawings based on actual dimensions.

## Research anchors

- Hoi An ancient town is a preserved trading-port urban fabric with timber
  houses, narrow tube-house lots, connected street facades, tile roofs, and
  mixed local/foreign architectural influence.
- The Japanese Covered Bridge should read as a stone-base and timber covered
  bridge: arched deck, heavy stone piers, curved tiled roof, inner shrine, and
  guardian animal statues at the entries.
- The Fujian Assembly Hall should read from far away through its red/pink
  triple gate, stacked roof tiers, upturned eaves, and ceramic ridge ornament.
- The Cantonese/Quang Dong hall should be separated visually from Fujian by an
  ochre/orange wall mass, green glazed roof language, courtyard axis, columns,
  and incense/plant detail.
- The market hall should not look like a temple. It needs a long, low,
  single-storey yellow arcade, repeated arches, roof clock/gable, and street
  stall/awning edge.

Useful source links for follow-up checks:

- UNESCO World Heritage Centre, Hoi An Ancient Town:
  https://whc.unesco.org/en/list/948/
- Vietnam Cultural Heritage Department, Hoi An ancient town monument:
  http://dsvh.gov.vn/di-tich-kien-truc-nghe-thuat-do-thi-co-hoi-an-2942
- Hoi An World Heritage official site:
  https://hoianworldheritage.org.vn/
- Hoi An tourism site, assembly halls and landmarks:
  https://hoiancreativecity.com/

## Blueprint files

| File | Use |
|---|---|
| `Screenshots/ref-19.png` | Chua Cau overall: side elevation, plan, modules, acceptance criteria |
| `Screenshots/ref-20.png` | Chua Cau entry/interior: gate, guardian statues, corridor cutaway |
| `Screenshots/ref-21.png` | Phuc Kien gate: red triple-arched tam quan and roof tiers |
| `Screenshots/ref-22.png` | Quang Dong hall: orange/green courtyard language |
| `Screenshots/ref-23.png` | Hoi An market hall: long arcade, roof gable, street awnings |
| `Screenshots/ref-24.png` | Ruin and river kit: broken shophouse, quay, steps, jetty |
| `Screenshots/ref-25.png` | General remake QA matrix: 360 capture naming and done bar |
| `Screenshots/ref-26.png` | Build-spec V2 Chua Cau: footprint, elevation, section, build order |
| `Screenshots/ref-27.png` | Build-spec V2 assembly halls: Phuc Kien vs Quang Dong separation |
| `Screenshots/ref-28.png` | Build-spec V2 Hoi An market: long arcade, street edge, module criteria |
| `Screenshots/ref-29.png` | Build-spec V2 ruin + river: pass-through ruin and embankment boundary |
| `Screenshots/ref-30.png` | Build-spec V2 acceptance: screenshot ring, fail states, scorecard |

Regenerate with:

```powershell
python .\scripts\generate_arch_blueprints.py
python .\scripts\generate_arch_build_specs.py
```

The generators refuse to overwrite existing target files. Delete or move a target
file deliberately before regenerating it.

## Remake success criteria

Use a three-level gate. A build is not done just because the scene compiles.

### 1. Silhouette gate

Pass when the landmark is recognizable as the target from gameplay distance.

- Chua Cau: low arched bridge body, sagging tiled roof, stone piers, mid-span
  shrine attachment, visible entry masses.
- Phuc Kien: red/pink triple gate, center bay taller, stacked roof tiers,
  upturned eaves.
- Quang Dong: orange/ochre wall, green roof, central courtyard axis.
- Market: long low yellow hall, repeated arcade bays, centered roof gable.
- Ruin: broken house still reads as a former Hoi An tube-house frontage.
- River: quay wall, steps, water plane, jetty, and boat silhouettes are separate.

Critical fail: the asset can be mistaken for a generic pagoda, generic house, or
random ruin from 20-30 meters away.

### 2. Module gate

Pass when landmark-specific modules are present, countable, and not hidden by
props or lighting.

- Geometry modules: roof tiers, entry bays, columns, railings, piers, arcade
  bays, stair steps, boat canopy, rubble beams.
- Material modules: yellow plaster, red/pink plaster, green glazed roof,
  weathered timber, grey stone, yin-yang clay tile, moss/water staining.
- Gameplay modules: walkable paths, collision boundaries, interact point, clear
  player scale, no decorative object blocking the intended route.

Critical fail: a required landmark module exists in code but is not visible in
the rendered camera views.

### 3. Evidence gate

Every remake needs a screenshot pack under:

```text
shots/remake/<asset-slug>/
```

Required captures:

- `360-00-north.png`
- `360-01-northeast.png`
- `360-02-east.png`
- `360-03-southeast.png`
- `360-04-south.png`
- `360-05-southwest.png`
- `360-06-west.png`
- `360-07-northwest.png`
- `top-down.png`
- `detail-roof.png`
- `detail-entry.png`
- `detail-materials.png`
- `player-scale.png`

For bridge/interior assets, add `walkthrough-start.png`,
`walkthrough-mid.png`, and `walkthrough-exit.png`.

Pass conditions:

- Same camera height and lens for all 8 compass screenshots.
- Landmark stays inside frame and is not cropped by the camera.
- Night lighting still preserves silhouette and material color identity.
- Top-down view proves footprint, path, and collision clearance.
- Detail shots show the parts named in the blueprint, not random decorative
  close-ups.

## Suggested scorecard

Use this during visual review:

| Area | Points | Pass bar |
|---|---:|---|
| Silhouette match | 30 | 24 |
| Landmark modules | 25 | 20 |
| Material/color identity | 15 | 12 |
| Gameplay readability/collision | 15 | 12 |
| Screenshot evidence completeness | 15 | 15 |

Overall pass: at least 83/100 and no critical fail.

## Practical remake order

1. Rebuild the silhouette in simple volumes only.
2. Take the 8 compass shots before adding detail.
3. Add required modules from the blueprint sheet.
4. Add materials and night lighting.
5. Re-take the full screenshot set.
6. Compare against `ref-12..18` photo refs and `ref-19..25` blueprint refs.
7. Fix the largest silhouette mismatch first; do not polish props before the
   primary massing passes.
