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
- R1 DONE `16556e8`: rig_glb_player.py v2 = 21-bone anatomical rig (added Neck + Toe L/R; joints at Loomis/Unity-Humanoid landmarks; elbow=0.45 / wrist=0.82 along shoulder->fingertip on the A-pose arm axis). minh_player_rigged.glb regenerated, vertex-colors kept. Gates green. AWAITING user turntable QA of joint placement before R2 (skin refine) — only do R2 if R1 turntable shows armpit/crotch bleed.
- Next repo step (PENDING APPROVAL — do not code yet): rig redesign per anatomy — calibrate joint placement (Loomis/Unity-Humanoid landmarks: shoulder line, elbow ~navel, wrist ~upper-thigh), add neck + foot ball, anatomical skinning (fix armpit/crotch bleed), proper rest pose + walk cycle (pelvis sway, foot roll, correct arm-swing axis), attach lantern to handR via BoneAttachment3D, skin/cloth material (or UV+texture gen since mesh is geometry-only). Then Phase B of C1 (widen the T). Then reflection rules, input/collision QA, audio/caption timing.
- Blocked on: none

## Shared path ownership
- none
