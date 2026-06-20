# Task: script-v3-cinematic-rebuild

## Target
- Workspace: hoa-hon-den-long
- Item: Script v3 cinematic 3D rebuild
- Desired outcome: Complete and verify an original 60-90 minute realistic cinematic game with lawful real-world references, production-quality 3D spaces, gradual psychological pressure, and independent QA.

## Scope (confirmed before editing)
- Repos:
  - hoa-hon-den-long-godot -> repos/hoa-hon-den-long-godot.md
- Allowed paths / out of scope: Whole game repo is in scope. Copying another game's story, unlicensed redistribution, and destructive replacement of pre-existing dirty work are out of scope.
- Cross-harness primary: this harness

## Rollup (derived, not proof)
- Status: in progress
- Summary: Scope confirmed; repo registration, audit, research, master planning, reference provenance tooling, narrative/checkpoint scaffolding, and executable QA gates are active.

## Progress
- Done:
  - User confirmed the narrative reference boundary and full end-to-end objective.
  - Current branch, remote, ahead/behind, and dirty working tree were verified.
  - Production planning docs were created for Script v3 rebuild, lawful asset pipeline, narrative direction, and QA acceptance.
  - A 16-image Chùa Cầu 2024 Commons reference set was acquired with manifest, attribution, coverage notes, hash validation, and LFS tracking.
  - Narrative state, checkpoint service, dialogue choice signal, and five-chapter smoke-flow gates were added and verified.
  - C5 boss-DPS progression was replaced with three held-color verification proofs that add explicit evidence/bonds and unlock the release ending in flow.
  - A `VoiceDirector` foundation was added; C1/C2 now have stateful remote-voice interventions and C2 well contradiction records evidence.
  - Player geometry shadow casting is disabled and covered by `test_player_shadow_policy.gd`; reflection exclusion is still missing.
- Next step: Build rendered reflection exclusion and real-input/collision QA; then replace text-only radio with audio/caption timing.
- Blocked on: none

## Open questions
- Exact lower-bound hardware profile will be finalized from current runtime evidence and production constraints.
- Public redistribution/use of the first reference set remains pending personality-rights review because identifiable people appear in the photos.

## Handoff note
- Preserve all pre-existing modified and untracked files. Verify git and runtime state again before relying on this card.
- Last verified gates on 2026-06-19: `tools/run_quality_gates.ps1` passed, including reference provenance, narrative state, checkpoint service, dialogue choice signal, voice director, player shadow policy, Godot import/script parse, and five-chapter `--flow` with outcome `release`.
