# Script V3 Implementation Matrix

Status checked: 2026-06-19 after narrative-state, reference-provenance, voice-director, player-shadow policy, and C5 verification-flow foundation.

`pass` means current runtime evidence covers the requirement. `partial` means a
piece exists but the full player-visible behavior is unproven. `missing` and
`contradicted` are not completion.

## Global experience mechanisms

| ID | Requirement | Status | Current evidence / gap |
|---|---|---|---|
| CC1 | Minh has no reflection or shadow | partial | Player geometry disables shadow casting (`test_player_shadow_policy.gd`). C2's right well and C5's black puddle now render a real mirrored `SubViewport` reflection via `reflection_pool.gd`, with the player excluded through a dedicated render layer (`test_reflection_pool.gd`). C4's bronze mirror still uses a separate light-beam puzzle mechanic, not player-reflection, and is out of this slice's scope. Visual correctness (2026-07-01 change) is not yet confirmed on a GPU machine. |
| CC2 | Lantern restores lost detail/truth | missing | Dynamic light exists; no face/text/detail reveal material contract. |
| CC3 | Player performs rituals | missing | Current chapters complete rituals through dialogue callbacks; no three-direction call, effigy, grave, or tablet interaction. |
| CC4 | NPC asks what player understands; Minh deflects | partial | `VoiceDirector` now records pressure/trust/evidence and C1/C2 have first remote-voice interventions. Full audio/radio mechanics and consistent contradiction beats are still incomplete. |
| CC5 | Cut at death threshold, no death flashback | partial | C5 no longer gates completion through boss DPS; it uses three held-color verification proofs and stateful evidence. The death-threshold cut/audio-only beat is still not authored. |
| CC6 | Hide name until the naming event | partial | `dialogue_ui.gd` remaps speaker labels to `NGƯỜI GIỮ ĐÈN`; C5 premature name text was removed. A full voice/name event is not built. |
| CC7 | Visible repetition proves the loop | partial | Repeated spaces and flow exist; stable callback props and authored continuity comparisons are incomplete. |
| CC8 | Minh's lantern reacts to truth | partial | Lantern and blackout beats exist; response is not driven by narrative evidence/pressure state. |

## Global visual/UI rules

| ID | Requirement | Status | Current evidence / gap |
|---|---|---|---|
| G1 | Dynamic speaker label | pass at UI layer | All `Minh` speaker labels are concealed until `reveal_player_name()`. Text/voice scripts still require content review. |
| G2 | No reflection/shadow anywhere | partial | Player mesh shadow casting is disabled and tested. Render-layer/reflection tests for water, mirror, bronze, and puddles are still missing. |
| G3 | Minh's lantern is the only persistent flame | partial | Main light exists; all secondary lights and blackout beats are not centrally governed. |
| G4 | Darkness removes detail; lantern reveals it | missing | No shared reveal shader or evidence-linked material state. |
| G5 | Five-color UI names the Five Ladies | missing | Existing palette is functional but cultural naming/color decision is not implemented. |
| G6 | Chapter-specific title/palette | partial | Titles exist; final palette and transition art are not production-ready. |

## Chapter matrix

| Chapter | Narrative | Interaction | Environment/asset | Current gate |
|---|---|---|---|---|
| C1 | First remote-voice trust hook exists; opening still has early fear cues | Shadow puzzle works; ritual missing | Procedural street; no measured hero module | partial |
| C2 | Remote voice now gives a questionable shortcut; well contradiction records evidence | Reverse movement/tiles work; effigy and call ritual missing | Wells/yard procedural; reflection still text-only, not rendered | partial |
| C3 | Memory-house clues partial | Memorial-tablet typing failure now implemented (`memorial_tablet_ui.gd`, always refuses any inscribed name, records `c3_tablet_refuses_name` evidence) | Interior procedural; workshop evidence incomplete | partial |
| C4 | Crossing-price choice now records `name_kept` | Mirror/mud prototype works; evidence comparison missing | River/boat procedural | partial |
| C5 | Direct death exposition reduced; proof dialogue now records evidence | Three held-color verification proofs replaced boss-DPS progression; final death-threshold cut still missing | Bridge/boss procedural; lawful reference dossier started | partial |
| Endings | Eligibility model has release/costly-hope/loop | Runtime ending cards branch from state | Final scenes and coda missing | partial |

## Infrastructure

| Requirement | Status | Evidence / next gate |
|---|---|---|
| Narrative/voice state | partial | Unique evidence, trust, bonds, choice, three reachable ending states, checkpoint save/load service, dialogue choice signal, voice-director, and save round-trip tests pass. Evidence is no longer granted by chapter transitions; C2/C5 proofs add it explicitly. |
| Real-reference library | partial | 16 CC BY 4.0 Chùa Cầu images with per-file hash/attribution/revision metadata and structured coverage roles. Coverage explicitly fails four-side and measurement gates; public redistribution remains pending personality-rights review. |
| Provenance validator | pass for current batch | `tools/validate_reference_library.ps1 -RequireReviewed` passes file integrity, review status, coverage-role, and rights metadata checks. |
| 360 asset QA | missing | Turntable stage and pass render automation not built. |
| Real-input regression | missing | Current `--flow` calls handlers directly. |
| Export/build | missing | No `export_presets.cfg` or clean-machine package. |
| Performance benchmark | missing | No frame/VRAM capture contract implemented. |
| Independent QA | partial | Initial code, narrative, and asset QA assigned; high-severity issues were converted into gates or documented gaps. Final production QA still requires real-input playthrough, visual 360, and build/export evidence. |

## Next acceptance slice

The next production slice is C1/C2 plus the remote-voice system, not more world breadth:

1. central pressure/voice state and captions;
2. calm opening and three truthful voice interventions;
3. rendered delayed reflection plus global shadow exclusion;
4. three-direction ritual and effigy/grave interaction;
5. one measured architectural module with 360 evidence;
6. real-input replay, checkpoint restore UI, audio and visual review.

This slice must pass before broad asset expansion.
