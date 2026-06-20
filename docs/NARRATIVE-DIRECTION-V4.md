# Narrative Direction V4 — Slow-burn deception

This is a production companion to Script v3, not a replacement for its cultural
research or original theme.

## 1. Intended feeling

The player first recognizes a real place and a useful human voice. Pressure
then grows through small contradictions. Fear becomes panic only after the
player has trusted, acted, and become unable to distinguish:

- a survivor from a recording;
- a dead person from a living voice;
- a monster from a memory system;
- a changed world from Minh's damaged perception.

The threat is not a creature that appears early. It is the possibility that
every helpful action keeps the loop alive.

## 2. Remote voice

Working device: an emergency/flood communication receiver. Its exact year,
hardware, operating procedure, and visual design are blocked from final art
until historically verified for the selected flood era.

The voice calls itself `Trạm Bốn` and has three simultaneously plausible
explanations:

1. a real flood watcher trapped at another time;
2. the final recording from the disaster;
3. the loop using dead voices and Minh's professional memory.

Fair-deception rules:

- It can imitate only a voice Minh has heard.
- It does not invent a new physical fact; it changes source or causality.
- Every actionable lie has an available verification path.
- A useful lie is about 80% true.
- It wants the ritual to continue because the loop is its existence; simple
  murder is not its goal.
- It earns trust through three correct interventions before the first suspect
  claim.
- No distortion, subtitle color, or "demon voice" reveals truth status.

## 3. State model

```text
trust_voice: 0..100
verify_count: integer
bond_ba: 0..2
bond_child: 0..2
heard_boatman: boolean
name_kept: boolean
refusal_count: integer (times the player explicitly refuses or defers a remote-voice directive)
evidence: set of claim IDs
pressure: authored 0..1 envelope
current_beat: stable ID
```

Every beat declares:

```text
entry_condition
player_verb
claim
verification
local_consequence
callback
exit_condition
fallback_timeout_or_recovery
checkpoint_policy
```

## 4. 60–90 minute beat line

| Time | Beat | Player action and pressure |
|---:|---|---|
| 0–6 | Familiar street | Close shop, light lamps, test receiver. No stinger, heartbeat, faceless NPC, or visible shadow entity. |
| 6–11 | Trạm Bốn | The voice helps repair a lamp and predicts weather correctly. Trust begins. |
| 11–18 | C1 water stall | Hat and shadow obscure the woman naturally. The voice advises not to answer the incense question. |
| 18–23 | First displacement | A gate returns Minh to the same place. Fog and fatigue remain plausible. |
| 23–30 | C2 child | The voice says a child fell into the well; wet tracks point toward the river. Player may listen, inspect, or defer. |
| 30–34 | First ritual | Reflection is delayed/misaligned, not instantly absent. Receiver plays a child's phrase before the child says it. |
| 34–41 | C3 memory house | Voice cadence approaches the master's. It says an unextinguished lantern proves Minh is alive. |
| 41–47 | Memorial tablet | Player focuses and types, but no name is accepted. The voice nearly speaks one syllable before signal loss. |
| 47–54 | C4 two accusations | Boatman says the receiver carries only dead voices; the voice says he capsized the boat. Evidence partly refutes both. |
| 54–62 | Single panic peak | Water rises; the same voice comes from receiver and behind. Landmarks move only when unseen. No monster reveal. |
| 62–66 | Crossing price | Choose mother's face or own name with consequences explained before commitment. |
| 66–71 | C5 false rescue | Voice promises all victims will live if Minh completes one last ritual. |
| 71–77 | Verification climax | Earth holds space, Metal restores source audio, Water reflects impossible absence, Fire/Wood recover erased traces. |
| 77–82 | Final verb | Put the lantern down and stop performing rites, allowing other souls to call Minh. |
| 82–85 | Present-day coda | A visitor finds the lantern bearing a name. No final jumpscare or monster teaser. |

Speedrun target: about 60 minutes. Blind critical path: 75–85. Complete
exploration: under 90.

## 5. Five colors become verification verbs

- Fire reveals heat, ash, and a recently erased trace.
- Water reflects what cannot see itself.
- Wood repairs fiber, paper, writing, and decayed shape.
- Metal conducts sound, rings bells, and restores original voice layers.
- Earth stabilizes a space that changes when unobserved.

C5 is not a conventional three-phase boss fight. It is a three-step proof using
verbs learned in play. No reliable character explains the answer.

## 6. Outcomes

- **Release:** keep the name, verify enough evidence, build human bonds; the
  other souls call Minh and the street remains lit.
- **Costly hope:** lose the name but verify enough; the boatman returns what was
  given up, with a visible cost.
- **Loop:** trust the voice completely and refuse verification; the ritual
  restarts, with fair evidence for replay.

No "true" ending is locked behind one ambiguous dialogue choice. Endings derive
from a pattern of observed behavior.

## 7. Audio contract

- Radio voice is non-spatial 2D; imitated world voice is spatial 3D.
- Final performances use Vietnamese actors; AI voice is temporary prototype.
- `VoiceRadio`, `VoiceWorld`, and `Ambience` are separate buses.
- Voice ducks ambience 6–9 dB.
- Rising/looming sound appears only in the C4 panic and final lantern refusal.
- Heartbeat is not a monster-distance radar.
- Music fully drops during verification and the first spoken name.
- Captions preserve uncertainty and do not identify a hidden speaker.

## 8. Narrative QA

| Gate | Pass criterion |
|---|---|
| Slow burn | Before minute 25, median fear <=5/10; first major peak is C4 or later. |
| Pressure | Average tension rises C1 to C4 with at least two clear release valleys. |
| Mystery | After C2, fewer than 70% of blind players are certain Minh is dead. |
| Fair deception | At least 80% can identify two earlier verifiable clues after reveal. |
| Ambiguity | At end C3, at least two theories each attract >=20% of testers. |
| Clarity | After ending, >=80% explain the theme and cite three pieces of evidence. |
| Agency | >=80% recall two choices with observable consequences. |
| Cheap-scare ban | No forced camera snap, behind-player spawn, or unexplained loudness spike. |
| Accessibility | No mandatory color-only/audio-only clue; captions do not leak identity. |
| Runtime | Blind critical path 60–90 minutes; no deadlock; checkpoint restores exact state. |

## 9. Research basis

- Sustained uncertain threat versus immediate fear: [Grillon 2008](https://doi.org/10.1007/s00213-007-1019-1)
- Looming sound as collision warning: [Neuhoff 2016](https://doi.org/10.1186/s41235-016-0017-4)
- Truth-default theory: [Levine 2014](https://doi.org/10.1177/0261927X14535916)
- Lie-detection accuracy limits: [Bond and DePaulo 2006](https://doi.org/10.1207/s15327957pspr1003_2)
- Environmental storytelling: [Jenkins](https://web.mit.edu/~21fms/People/henry3/games&narrative.html)
- Meaningful gameplay layers: [Frictional Games](https://frictionalgames.blogspot.com/2014/04/4-layers-narrative-design-approach.html)
- Authored intensity peaks and recovery: [Valve](https://cdn.akamai.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
