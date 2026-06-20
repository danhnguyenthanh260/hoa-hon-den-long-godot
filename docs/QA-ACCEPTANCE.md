# QA and Acceptance Contract

## 1. Independence

The implementing agent cannot be the sole final reviewer. Each milestone has a
blind review first and a spec review second.

| Reviewer role | Scope | Must not rely on |
|---|---|---|
| Narrative blind reviewer | pacing, trust, ambiguity, agency, comprehension | intended answer or debug state |
| Architecture/provenance reviewer | rights, coverage, dimensions, joins, historical/restoration state | visual plausibility alone |
| Visual asset reviewer | 360, silhouette, topology, UV, PBR, LOD, collision | builder screenshots only |
| Gameplay/accessibility reviewer | real input, prompts, alternatives, checkpoint/failure recovery | direct handler/autoplay flow |
| Build/performance reviewer | clean export, hardware profile, frame/VRAM traces, save migration | editor run alone |

## 2. Severity

- S1: data loss, crash, unfinishable critical path, unlicensed distributable
  asset, or severe cultural misrepresentation.
- S2: broken chapter state, wrong ending, major collision/visual defect, failed
  performance target, inaccessible mandatory puzzle, or misleading evidence.
- S3: localized visual/audio/pacing defect with a workaround.
- S4: polish issue without gameplay or compliance impact.

Release requires zero open S1/S2.

## 3. Evidence packs

### Per asset

- source and license manifest;
- coverage/measurement dossier;
- topology/material/collision report;
- 36-frame turntable and eight fixed views;
- reference overlays;
- player-scale and worst-light screenshots;
- triangle, texture-memory, draw-call and LOD report;
- independent reviewer decision.

### Per chapter

- beat/state matrix;
- real-input capture;
- checkpoint restore at each beat boundary;
- branch/callback evidence;
- subtitle and audio-routing capture;
- visual captures from required cameras;
- p50/p95/p99 CPU/GPU and VRAM trace;
- defects and retest results.

### Per release candidate

- clean-machine install and launch;
- full critical path and all endings;
- save upgrade/corruption recovery;
- settings/rebind persistence;
- license/attribution output;
- hash/version/build metadata;
- requirement-to-evidence completion matrix.

## 4. Test ladder

1. Script parse and import.
2. Unit/state tests.
3. Handler flow smoke test.
4. Real-input deterministic replay.
5. Rendered visual regression.
6. Independent blind playthrough.
7. Spec review and edge cases.
8. Performance and clean export.
9. Full completion audit.

A lower rung never proves a higher rung.

## 5. Current baseline limitations

- `--flow` directly invokes handlers and always chooses the first branch.
- `--autoplay` produces useful screenshots but does not prove input or collision.
- Current shots are not an approved visual baseline because they contain known
  prototype geometry and lighting.
- There is no export preset or clean-machine package yet.

These checks remain useful as smoke tests while stronger evidence is added.
