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
- Pushed: no, current local commits are 6 ahead of origin/master (HEAD `d2c1ebc`)
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
- Next repo step: (1) iterate player mesh visuals from user screenshots (orientation, arm rest pose, attach pole to handR via BoneAttachment3D, possibly texture/UV gen since current mesh is geometry-only). (2) Phase B of C1: widen pre-light_up playable area beyond the T while keeping gated-linear pacing ("gated nhung giau hon"). Then reflection rendering rules, real-input/collision QA, audio/caption timing.
- Blocked on: none

## Shared path ownership
- none
