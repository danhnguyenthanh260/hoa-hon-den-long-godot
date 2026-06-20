# Họa Hồn Đèn Lồng — Production Plan V3

Status: active production contract
Target: original 60–90 minute cinematic 3D game in Godot 4.5
Primary story sources: `SCRIPT-v3.md`, `SCRIPT-v3-EXPERIENCE.md`,
`SCRIPT-v3-PHAN-CANH.md`

## 1. Current truth

The current build is a working five-chapter procedural prototype, not a nearly
finished production game.

- The headless flow reaches the ending, but it calls handlers and positions
  directly; it is a smoke check, not proof of playable input, collision, pacing,
  saves, or narrative consequences.
- The world, player, NPCs, and hero landmarks are mostly runtime primitives.
- Script v3 is not implemented consistently. Speaker naming, rituals,
  reflection rules, consequential state, two/three ending logic, and the final
  reveal are incomplete or contradicted by current dialogue.
- Audio is synthetic placeholder output; there is no final voice, field Foley,
  cinematic mix, or caption contract.
- Existing reference images do not provide a measured, licensed, multi-view
  production dossier.
- There is no export preset, CI, save/checkpoint system, accessibility menu,
  performance benchmark, or independent visual regression gate.

Observed baseline on 2026-06-18:

- Godot 4.5 editor import: pass.
- Five-chapter headless flow: pass in 70.8 seconds.
- Autoplay capture: pass, 18 images.
- Visual review: prototype-grade silhouette and lighting; insufficient
  architectural detail, material response, character fidelity, framing, and
  readable threat staging.
- Honest completion estimate against this contract: 20–30%.

## 2. Product pillars

1. **Familiar reality first.** Hội An must read as a lived place before it
   becomes impossible.
2. **Pressure, not immediate fright.** C1–C3 use uncertainty and conflicting
   explanations. Panic is reserved for late C4 and the final refusal in C5.
3. **The player verifies truth.** No character delivers the complete answer.
   The player uses learned ritual verbs and environmental evidence.
4. **Constrained agency with visible consequence.** Few choices are acceptable;
   consequences must be observable within 90 seconds and return later.
5. **Cultural fiction stays labeled.** Sourced practice, architectural evidence,
   and invented supernatural rules are not silently mixed.
6. **Reality is measured.** Hero architecture is built from lawful photographs,
   dimensions, joins, and materials. AI is not a substitute for missing facts.
7. **Independent completion proof.** Builders do not approve their own final
   work.

`Do You Copy?` is a reference only for pacing, distant voice interaction,
information asymmetry, and helplessness. Plot, characters, dialogue, encounter
structure, locations, and distinctive assets remain original.

## 3. Definition of done

The project is complete only when all rows pass with current evidence.

| Area | Required evidence |
|---|---|
| Story | Blind run lasts 60–90 minutes; every v3/v4 beat has entry, player verb, evidence, exit, and recovery behavior. |
| Slow burn | No forced scare in the opening; pressure rises across chapters with at least two authored release valleys. |
| Deception | Every actionable lie is mostly true, has a discoverable contradiction, and never relies on a distorted "evil voice" tell. |
| Agency | Important choices produce local feedback and later callbacks; save/load preserves consequences. |
| Architecture | Every hero asset has a rights-approved dossier, measured scale, structure/join spec, four-side plus diagonal coverage, and 360-degree review. |
| 3D quality | No non-manifold production mesh, flipped normal, visible gameplay-distance seam, collision leak, floating join, or unreviewed hidden face. |
| Character | Final protagonist and close NPCs have corrected anatomy, rig deformation, facial/hand review, material breakup, and 360-degree approval. |
| Audio | Final Vietnamese performances, field Foley/ambience, radio/world routing, captions, loudness review, and no heartbeat-as-radar behavior. |
| Gameplay | Real input completes every chapter without direct handler calls; checkpoint recovery and failure fallback never deadlock. |
| Accessibility | Rebindable input, subtitle controls, audio/visual alternatives, no color-only or sound-only mandatory puzzle. |
| Build | Versioned Windows export launches on a clean machine and passes smoke, save migration, and asset-license checks. |
| Performance | 1080p/60 target; worst-case p95 CPU and GPU each at or below 13.5 ms on the agreed mid-range profile, leaving frame headroom. |
| QA | Independent blind and spec reviews pass; unresolved severity-1/2 defects are zero. |

## 4. Target architecture

### Runtime systems

- `NarrativeDirector`: beat graph, trust, evidence, pressure, callbacks,
  choices, endings, and serializable state.
- `VoiceDirector`: radio/world channels, speaker mask, claim ID, subtitle identity,
  spatial routing, and voice ducking.
- `PressureDirector`: authored envelope and cooldown; randomness is limited to
  non-critical micro-events.
- `EvidenceResource`: claim support/refutation and the player verb used to
  verify it.
- `RitualController`: call-three-directions, effigy, grave, memorial tablet,
  and five-color verification verbs.
- `CheckpointService`: chapter/beat/state restore and migration.
- `SettingsService`: input, subtitle, audio, graphics, and accessibility.
- `BuildDiagnostics`: deterministic flow, real-input replay, performance trace,
  screenshot, turntable, and provenance reports.

### Content structure

- The current single runtime-built scene remains only during migration.
- Production environments move to authored chapter scenes and reusable measured
  modules. Procedural builders remain for repeated clutter where they provide a
  verified performance benefit.
- Hero objects use imported GLB with explicit collision, LOD, pivots, snap
  points, and evidence IDs.
- Major story beats are data-backed instead of being spread across hardcoded
  dialogue arrays.

## 5. Dependency-ordered execution

### M0 — Preserve and lock truth

Deliverables:

- Workspace registry, task state, current git/remote proof.
- Production contract and current baseline captures.
- Script v3 requirement matrix with `implemented`, `contradicted`, `missing`, or
  `unverified` status.

Exit gate: all pre-existing dirty work remains preserved and attributable.

### M1 — Evidence and asset infrastructure

Deliverables:

- `reference-library/` excluded from Godot import.
- Per-file source/license/hash manifests.
- Automated provenance validator.
- Capture dossier template, coverage matrix, scale/measurement record.
- Blender export convention and Godot import preset.
- Asset review stage that renders 36-frame turntables plus fixed canonical
  angles, wireframe, collision, and material passes.

Exit gate: one hero asset dossier passes rights and coverage; missing measured
dimensions are reported as a blocker, not guessed.

### M2 — Narrative and save foundation

Deliverables:

- Narrative/voice/pressure state model.
- Stable speaker identity rule: `NGƯỜI GIỮ ĐÈN` until the name event.
- Consequential choice state, evidence counters, refusal state, and three
  outcome tiers.
- Checkpoint and settings skeleton.
- Narrative state tests and deterministic debug overlay.

Exit gate: save/reload at every chapter restores the same beat, evidence, voice
trust, and ending eligibility.

### M3 — C1/C2 vertical slice

Build to final quality before scaling production:

- C1 begins in recognizable, calm Hội An. The waterline, impossible repetition,
  and voice inconsistency arrive gradually; no faceless reveal at minute one.
- The remote voice earns trust with three correct, useful interventions before
  its first suspicious claim.
- C2 implements delayed/misaligned reflection before full absence, the broken
  effigy ritual, three-direction calling, and a fair contradiction.
- Real-input completion, checkpoint restore, captions, final-quality room tone,
  representative character material, and one measured environment module.

Exit gate: blind testers experience uncertainty rather than immediate certainty
about death/monster identity; all technical gates pass on the slice.

### M4 — C3 production

- Interior larger than exterior without visible teleport tricks.
- Workshop evidence connects Minh to the effigies.
- Voice cadence starts matching the master without explicit supernatural FX.
- Memorial-tablet input accepts focus and keystrokes but cannot inscribe the
  name; failure is authored, accessible, and checkpoint-safe.
- Lighting/detail reveal communicates lost memory without flattening the whole
  scene.

Exit gate: at least two plausible interpretations remain after C3.

### M5 — C4 production

- Boatman and remote voice each provide a partly false accusation.
- Evidence can refute part of both accounts.
- Reverse river, unfinished wind graves, and moving landmarks are authored
  continuity changes rather than random effects.
- The only major panic sequence uses rising water, conflicting spatial voice,
  and changed geography; no visible monster is required.
- Choice consequences are explained before commitment and stored immediately.

Exit gate: panic peaks late, remains playable, and recovers into a deliberate
choice rather than another chase.

### M6 — C5 verification climax

Replace exposition-heavy boss combat with learned verification verbs:

1. Earth stabilizes the bridge long enough to read the flood record.
2. Metal restores original audio and exposes the repeated recording.
3. Water shows the lantern reflection while Minh is absent.
4. Fire and Wood recover erased traces and the incomplete name.

No reliable character says "Minh is dead" as the answer. The player proves the
event and chooses whether to put down the lantern and let others call him.

Exit gate: players can cite three pieces of evidence after the reveal; the
ending follows state, not a hardcoded sequence.

### M7 — World and asset completion

Per chapter:

- measured modular architecture;
- real PBR material families;
- hero landmarks and ritual props;
- collision, occlusion, LOD, lightmap, and navigation;
- final characters, animation, cloth/prop interaction;
- canonical-view and 360-degree evidence pack.

Exit gate: no placeholder primitive appears inside normal gameplay framing
unless explicitly approved as an invisible helper or distant LOD.

### M8 — Audio, voice, and cinematic polish

- Cast and record Vietnamese performers; AI voice is prototype-only.
- Field-record or lawfully license room tone, river, rain, wood, tile, cloth,
  market, footsteps, doors, and ritual objects.
- Mix `VoiceRadio`, `VoiceWorld`, `Ambience`, `Music`, `Foley`, and `UI` buses.
- Voice ducks ambience 6–9 dB; captions never expose a hidden speaker identity.
- Music fully withdraws during evidence verification and the first naming.

Exit gate: important dialogue intelligibility at least 95% in representative
playtests; audio-only cues have visual/caption alternatives.

### M9 — Production build and accessibility

- Export presets and version metadata.
- Clean-machine Windows package.
- Settings, rebinds, subtitle size/background, audio range, graphics presets,
  safe-area and photosensitivity options.
- Save compatibility and corruption recovery.

Exit gate: clean install and full critical path on the minimum profile.

### M10 — Independent QA and release audit

Independent reviewers run:

1. blind narrative playthrough;
2. architecture/provenance audit;
3. 360 visual/material/collision audit;
4. real-input gameplay and accessibility regression;
5. performance, export, clean-install, and save audit.

Exit gate: the requirement-to-evidence matrix has no missing or indirect proof.

## 6. Work rules

- A pass in one gate never substitutes for another. A build does not prove art;
  a screenshot does not prove gameplay; an autoplay handler does not prove real
  input.
- No asset enters a distributable build with unknown rights.
- No AI-generated output is accepted because it "looks plausible". It must pass
  the same topology, geometry, scale, material, collision, and review gates.
- Unknown geometry remains unknown. Do not mirror or invent a hidden side of a
  heritage structure without evidence.
- Every meaningful milestone updates `.state/` with the command, result, and
  remaining blockers.

## 7. Research basis

- Threat uncertainty and sustained anxiety: [Grillon 2008](https://doi.org/10.1007/s00213-007-1019-1)
- Truth-default and deception: [Levine 2014](https://doi.org/10.1177/0261927X14535916)
- Human lie-detection limits: [Bond and DePaulo 2006](https://doi.org/10.1207/s15327957pspr1003_2)
- Environmental narrative architecture: [Henry Jenkins](https://web.mit.edu/~21fms/People/henry3/games&narrative.html)
- Narrative/gameplay layers: [Frictional Games](https://frictionalgames.blogspot.com/2014/04/4-layers-narrative-design-approach.html)
- Tension peaks and release: [Valve AI Systems of Left 4 Dead](https://cdn.akamai.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- Technical art and capture sources are maintained in `REAL-ASSET-PIPELINE.md`.
