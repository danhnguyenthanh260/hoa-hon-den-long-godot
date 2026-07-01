# Repo State: hoa-hon-den-long-godot

## Scope
- Workspace: hoa-hon-den-long
- Task: script-v3-cinematic-rebuild
- Repo: hoa-hon-den-long-godot
- Allowed paths / out of scope: Whole game repo; no destructive reset, unlicensed asset inclusion, or copied third-party narrative.

## Branch / remote
- Claimed branch: master
- Claimed base: origin/master
- Remote: origin/master
- Current checkout verified: master via `git status --short --branch` on 2026-06-19
- Remote verified: origin/master fetched via `git fetch --prune origin` on 2026-06-18
- Ahead/behind verified: origin/master...master = 0 behind, 3 ahead on 2026-06-18

## Delivery state
- Pushed: no, 6 ahead of origin/master (HEAD `285c599`) — verified via `git rev-list --count origin/master..master` on 2026-06-20 (prior "3/4/5 ahead" notes were extrapolated from a stale 06-18 base; 6 is the real count).
- PR: none
- Gate: passing locally
- Gate evidence: full suite re-run on 2026-06-20 before commit `1de4511` — all gates PASS (reference provenance, narrative state, checkpoint service, dialogue choice signal, voice director, memory-stall UI, bird-stencil puzzle, C1 progression, player-shadow, import/parse, `--flow` outcome=release). ObjectDB-leak-at-exit is a benign Godot stderr warning; PowerShell wraps it as NativeCommandError (exit 1) but the gates themselves pass.

## Repo progress
- Done:
  - Target repository and remote verified.
  - Existing dirty work inventoried at status level and explicitly preserved.
  - Added production docs, reference-library provenance tooling, narrative/checkpoint scaffolding, and Godot test gates.
  - Added dialogue choice signal coverage so C4 decision persistence is directly tested.
  - Reworked C5 progression from boss-DPS to held-color proof verification that records evidence/bonds before ending.
  - Added `VoiceDirector` and stateful C1/C2 remote-voice interventions, including C2 well evidence recording.
  - Disabled player geometry shadow casting and added an executable player-shadow policy gate.
  - Committed C1 vertical slice `1de4511`: Chim Lac 3-part stencil puzzle, memory-stall inspect UI, Tran Phu street life (cat AI, knockable door, 6 lightable lamps, ruin/wall/river/bridge thought beats), main.gd wiring, and 3 new gates.
  - Committed C1 graphics PBR migration `c93fb6b` (Phase A of C1 upgrade, "do hoa truoc" per user): replaced flat `Build.mat(Color)` on all C1 architecture with shared `Build.pbr()` palette (Plaster001/WoodFloor043/PavingStones138/RoofingTiles013A, same sets+tints as world.gd). Emissive/organic props left flat. Verified import/parse, C1 gate, --flow release. Fresh screenshot NOT captured — autoplay bot needs an interactive render session that did not complete under automation.
- Committed player mesh body `d2c1ebc` ("Duong 2" per user — build to Meshy quality): new rig_glb_player.py (18-bone rig WITH arms, nearest-segment auto-skin, keeps Hunyuan vertex colors) rigs minh_apose_0.glb -> minh_player_rigged.glb; player.gd swaps primitive body for the mesh under USE_MESH_BODY flag (reversible), bone-driven walk + arm swing, pole/lantern/color/first-person preserved. Gates pass (import/parse, player-shadow, --flow release). VISUAL NOT verified — this env cannot render; awaiting user local run to tune MESH_YAW_OFFSET / scale / ARM_REST_DROP / pole-in-hand.
- Committed third-person camera `da53de8`: V cycles First -> Third(orbit) -> Follow; player.gd gains cam_relative+view_yaw.
- Committed QA turntable `285c599` (scenes/turntable.tscn + scripts/tools/turntable.gd): renders 360 + walk to shots/qa/. This env CANNOT render (no display/GPU) — user must run locally and send frames.
- Blueprint HHDL-RIG-001 APPROVED by user 2026-06-20 (docs/rig-blueprint.svg + .html). Phased R0-R5 underway, QA (turntable) between phases.
- R1 DONE `16556e8`: 21-bone anatomical rig (Neck+Toe). User QA'd 24-frame turntable: arms were "zombie/giua nguc" — A-pose arm-drop tore shoulders.
- ARM FIX `61c0f66`: re-rig source switched A-pose -> minh_shape_0.glb (arms already DOWN), removed _drop_arm entirely (rig_glb_player.py arm_down = vertical side column). Gates green.
- R4 lantern `3c3640d`: pole base follows handR global_position each frame -> lantern carried in RIGHT hand; LEFT arm swings on walk (1 tay cam den, 1 tay dung dua per user). NOTE: turntable QA loads mesh only (no pole) -> lantern must be verified IN-GAME (run game, press V to third-person).
- AWAITING: user re-runs cap360 (arms) + in-game check (lantern/arm-swing). Pending after arms OK: nón lá authenticity (mesh hat is generic cone -> regenerate or overlay procedural nón lá), walk "đi lùi" (MESH_YAW_OFFSET / leg phase, verify in-game), color R5 (vertex-color ~white).
- 2026-07-01 audit (this session) found the runtime C1-C5 code well ahead of this stale note (walk fix, lantern, C4/C5 rewrite already landed per git log) — the implementation matrix and this file had drifted from actual commits. Ran a fresh code audit against the user's new "Thao tác" interaction spec and closed 5 identified gaps via plan `docs/superpowers/plans/2026-07-01-close-c1-c5-gaps.md` (inline execution, TDD, one commit per task): (1) NarrativeState.contradictions ledger; (2) memorial_tablet_ui.gd — C3 bài vị that always refuses any inscribed name, wired through main.gd open/close plumbing; (3) reflection_pool.gd — shared SubViewport mirror-camera component, player excluded via a dedicated render layer bit, applied to C2's right well (8-frame delay) and C5's black puddle (no delay); (4) C1 tea-offering ritual gating the memory stall + evidence on both the tea ritual and the solved Chim Lạc puzzle; (5) C2 well-vs-radio contradiction now recorded in narrative.contradictions. Also fixed a stale `c1.intro_beat()` call in `_flow_test()` (function was renamed to `enter_beat()`; the dangling call inside an awaited coroutine is the likely real cause of the multi-minute `--flow` hangs seen in prior sessions — confirmed by reproducing an identical silent hang with a different missing-function call during this session's TDD red step). Added 3 new gates to `run_quality_gates.ps1` (memorial tablet UI, reflection pool, C2 well contradiction); full non-flow suite passes.
- Next repo step: user runs Task 10 of the plan above on a machine with a real GPU/display — full `--flow` (this env cannot finish it in reasonable time headless) plus eyeballing the 3 new interactive/visual mechanics in a live playthrough. After that: nón lá authenticity, walk "đi lùi" verify, color R5, then the previously-planned rig redesign (PENDING APPROVAL, unchanged from the note above), then reflection rules for C4's bronze mirror (out of scope of the 5-gap slice — different mechanic, light-beam puzzle not player-reflection).
- Blocked on: none

## Shared path ownership
- none
