# It Gazes Back

> It Gazes Back is a 2D top-down survival horror game that focuses on stealth, psychological tension, and narrative choice. Players take on the role of Quinn, a space engineer trapped on a derelict vessel after a catastrophic event unleashes monstrous entities. With no means to fight back, the player must navigate the claustrophobic corridors and dark ventilation shafts of the ship, relying on sound, environmental cues, and sheer nerve to survive. The core experience revolves around avoiding direct visual contact with the creatures, managing Quinn's deteriorating sanity and claustrophobia, and uncovering the truth behind the disaster while trying to reach the escape docks.

---

## High‑Level Game Design Snapshot (Condensed GDD)

| Pillar | Summary | Player Impact |
|--------|---------|---------------|
| Perceptual Horror | Looking at certain entities penalizes sanity (Gaze Aversion core loop – planned). | Forces indirect observation via sound & peripheral inference. |
| Psychological Pressure | Sanity + Claustrophobia/Anxiety affect visuals, audio, control reliability (partially implemented via UI hooks). | Escalating tension; misdirection & hallucinations (future). |
| Helplessness & Ingenuity | No combat. Movement states, hiding, noise discipline. | Players strategize around evasion and timing. |
| Environmental Narrative | Level layout + interactables + audio/text logs (planned). | Discovery & branching progression. |
| Dynamic Space | Ventilation, tight passages, light & shadow (partial; flickering lights implemented). | Spatial risk/reward & pacing modulation. |

### Current Implementation Status Overview

| System | Status |
|--------|--------|
| Player movement & animation state machine (idle/walk/run/crouch/crouch-run/hidden/damaged) | Implemented |
| Crouch restrictions via level flags (force crouch) | Implemented |
| Damage / HitBox / HurtBox architecture | Implemented (basic) |
| Basic enemy (Corrupted Crew) AI (Idle → Wander → Chase) | Implemented |
| Enemy vision cone (directional rotation) | Implemented |
| Hiding spots & vent transitions (Interactable base + variants) | Implemented |
| Level transition retention of player instance | Implemented |
| Sanity / Anxiety numeric values + HUD shader feedback | Implemented (mechanics not yet driving changes beyond shaders) |
| Scene transition fade system | Implemented |
| Modular Interactable system | Implemented |
| Mental state deeper effects (hallucinations, control distortion) | Planned |
| Gaze Aversion (sanity drain on looking) | Planned |
| Noise / sound‑attraction system | Planned |
| Creature advanced stalking AI | Planned |
| Save / Load & persistence | Planned |
| Dialogue / Log data resource system | Planned |

---

## Repository Structure (Key Folders)

```
Scenes/
  player.tscn
  Levels/
    level.gd               (Level root logic)
    Addons/
      hiding_vent.tscn / .gd
      level_transition.tscn / .gd
      wall_light.tscn / .gd
  Enemies/
    CorruptedCrew/
      corrupted_crew1.tscn
  SceneTransition/
Scripts/
  Player/
    player.gd
    player_state_machine.gd
    state.gd (base)
    States/ (all concrete player states)
  Enemies/
    enemy.gd
    enemy_state_machine.gd
    EnemyStates/ (Idle/Wander/Chase)
    vision_area.gd
  GeneralNodes/
    interactions.gd
    HitBox/ + HurtBox/
    Interactables/
      interactable.gd (base)
  Globals/
    level_manager.gd
    player_manager.gd
  GeneralNodes/
    level_tilemap.gd
    (and helpers)
GUI/
  player_hud.tscn / .gd
  interaction_prompt.tscn / .gd
Assets/ (art, tiles, UI, shaders)  (Not fully documented here)
```

---

## Global Singletons (Autoload Assumptions)

| Singleton | Role | Key Signals | Notes |
|-----------|------|-------------|-------|
| `PlayerManager` | Owns persistent player instance, mental stats, cross‑level flags (crouch memory, spawn hidden). | `sanity_changed`, `anxiety_changed`, `interact_pressed` | Player is unparented during scene changes then reinserted. |
| `LevelManager` | Scene transitions, tilemap bounds broadcast for camera limits, fade sequencing. | `TilemapBoundsChanged`, `level_load_started`, `level_loaded` | Works with `SceneTransition` (fade) & reparent. |
| `SceneTransition` | Fade in/out animations gating level load (AnimationPlayer). | (No global custom signals) | Called via `await SceneTransition.fade_out()` / `fade_in()`. |
| `PlayerHud` | Stores the player HUD CanvasLayer scene|

> Ensure these are registered in Project Settings → Autoload with names matching code references.

---

## Core Player Architecture

| Component | Description |
|-----------|-------------|
| `player.gd` | CharacterBody2D; holds state machine, animation resolution, crouch/hidden flags, damage intake, interaction prompt management. |
| `player_state_machine.gd` | Lightweight orchestrator: calls `process`, `physics`, `handle_input` on current state. |
| `state.gd` | Base class for states (Player). States extend `State`; each has `enter`, `exit`, `process`, `physics`, `update_animation`. |
| States | Idle, Walk, Run, Crouch, CrouchRun, Hidden, Damaged. Separation allows future additions (e.g., Panic, HallucinationStagger). |
| Interaction Prompt | Instantiated per player; updated by Interactable overlap events (Area2D). |
| Hit / Hurt | Player has HitBox (receives damage) & enemies expose HurtBox (applies damage). |

### Player Signals
- `player_damaged(damage_amount)`
- `damaged(hurtbox)` (emits the actual HurtBox source)
- `direction_changed(new_direction)`
- `crouch_toggled(is_crouched)`

### Movement & Animation Direction
Both Player and Enemy share direction logic that maps a normalized vector to animation name suffixes (`down`, `up_left`, etc.). Reuse this for any new animated entity.

---

## Enemy (Corrupted Crew) Architecture

| Script | Role |
|--------|------|
| `enemy.gd` | CharacterBody2D; handles direction tracking & animation updating. |
| `enemy_state_machine.gd` | Mirrors player FSM pattern (Initialize -> states). |
| State Scripts | `enemy_state_idle.gd`, `enemy_state_wander.gd`, `enemy_state_chase.gd` – all inherit from `enemy_state.gd`. |
| `vision_area.gd` | Rotates based on enemy facing; emits `player_entered` / `player_exited`. |
| HurtBox / HitBox | Same system as player for collision & damage bridging. |

Chase state uses smoothing (`lerp`) for direction turning and respects hidden player (won’t chase if player `is_hidden`).

---

## Interaction System

| Element | Description |
|---------|-------------|
| `Interactable` (base) | Area2D with signals `player_entered`, `player_exited`. Override `on_interact` & `on_hidden_interact`. Provides prompt text functions. |
| `HidingVent` | Two‑stage behavior: first interact → enter Hidden state; while hidden interact → exit. |
| `LevelTransition` | Can optionally double as hiding spot: hidden → second interact transitions level while preserving hidden status (spawns hidden on arrival). Supports parametric size & orientation in editor. |
| Prompt Flow | Player caches current available interactable; shows/hides prompt per overlap validity each frame (defensive recheck). |

---

## Mental State & UI

| Variable (PlayerManager) | Meaning | Current Effects | Planned Extensions |
|--------------------------|---------|-----------------|--------------------|
| `sanity` | Psychological stability | Brain HUD glitch shader intensifies | Visual hallucinations, auditory events, input distortion |
| `anxiety` (mapped from claustrophobia concept) | Short‑term physiological tension | Lungs shader breathing speed, scale, red tint | Movement jitter, sound emission increase, panic states |
| `spawn_hidden` | Flag to spawn player already hidden after transition | Used by LevelTransition | Could interact with creature suspicion meter |
| `level_forces_crouch` | Level property gating standing | Forces crouch states/blocks stand | Dynamic zone-based toggling |

HUD updates on value changes via signals. Shader parameters are linearly interpolated mapping 0 → calm, 1 → max effect.

---

## Scene Transition & Persistence

Sequence inside `LevelManager.load_new_level()`:
1. Pause tree, capture target transition name.
2. Unparent player (preserves instance/state).
3. Fade out.
4. Emit `level_load_started`.
5. `change_scene_to_file(...)`.
6. Fade in.
7. Unpause, emit `level_loaded` (and level script may enforce crouch flags).
8. Level uses `level.gd` to reparent player, optionally force crouch.

---

## Tilemap Bounds & Camera

`LevelTilemap` or `LevelGeometry` aggregates used rect(s) → sends bounds via `LevelManager.TilemapBoundsChanged`.  
`PlayerCamera` listens and applies `limit_*` values preventing camera overscroll.

---

## Signals Catalog (Reference)

| Signal | Emitter | Purpose |
|--------|---------|---------|
| `TilemapBoundsChanged(bounds:Array[Vector2])` | LevelManager | Camera bounding |
| `level_load_started`, `level_loaded` | LevelManager | Transition control hooks |
| `sanity_changed(int)` / `anxiety_changed(int)` | PlayerManager | UI / mental effect reactions |
| `player_damaged(damage)` | Player | UI / SFX hooks |
| `damaged(damage,hurtbox)` | HitBox | Communicates source to listeners |
| `direction_changed(Vector2)` | Player / Enemy | Orientation-dependent systems (vision, interaction host alignment) |
| `player_entered(interactable)` / `player_exited(interactable)` | Interactable | Player prompt system |
| `player_entered()` / `player_exited()` | VisionArea | Enemy chase acquisition |
| `crouch_toggled(is_crouched)` | Player | Future: adjust collider, noise radius |
| `damaged(damage,hurtbox)` | HitBox | External reaction modules |

---

## Coding & Style Conventions (MANDATORY)

| Rule | Rationale |
|------|-----------|
| Modular FSM states | Encourages single responsibility & low merge conflict surfaces |
| Signals > direct node lookups | Decoupling & testability |
| Avoid wide monolithic scripts | Facilitates feature gating and AI model comprehension |
| Use exported properties for tuning | Enables designer iteration |
| Resource types for data (future) | Data‑driven narrative & items (extensible) |
| Thorough but concise single‑line commentary | Maintains clarity without clutter |
| Avoid modifying multiple scripts for a new feature if a single extension point exists | Minimizes regression risk |

---

## 12. Extending the Project (How‑To Guides)

### Adding a New Player State (e.g., Panic)
1. Create script `state_panic.gd` in `Scripts/Player/States/` extending `State`.
2. Attach as a child node under `Player/StateMachine` in `player.tscn`.
3. Implement:
   - `enter`: set animation, modify movement speed, maybe trigger shader.
   - `process`: condition to exit back to Idle / Crouch.
4. Transition logic: add checks in existing states (Walk/Run/Crouch) to return `panic_state` when anxiety threshold passes.
5. Never modify base `State` unless supplying generic hooks; prefer local code.

### Adding an Enemy State (Search)
1. Copy pattern from `enemy_state_wander.gd`.
2. Add node under `EnemyStateMachine` in enemy scene.
3. Implement timer & last known player position logic (store in chase).
4. In `enemy_state_chase.gd`, when losing sight, return `Search` instead of `next_state`.

### Creating a New Interactable
1. Inherit from `Interactable`.
2. Override `get_prompt_text()` / `on_interact()` / `on_hidden_interact()` (if two‑stage).
3. Add Area2D scene with CollisionShape2D; ensure `collision_layer/mask` allow Player detection (Player body layer must match mask).
4. (Optional) Provide AnimatedSprite2D child with “Open” / “Close” animations.

### Implementing Gaze Aversion (Planned Hook)
Suggested minimal intrusion:
- Add `GazeSensor` Area2D to Player pointing forward (FOV wedge).
- Add a tag/metadata or group (“GazeEntity”) for creatures that should not be looked at.
- On `area_entered`:
  - Start a timer; after buffer, decrement `PlayerManager.sanity`.
- On `area_exited`:
  - Stop / reverse recovery over time.
Use dedicated script so only one new file + a small addition in Player scene.

### Noise System (Planned)
- Create `NoiseEmitter` (component) that emits signal `noise_emitted(strength, position)`.
- Player states (Run, Panic) call `emit_noise(strength)`.
- Enemies subscribe globally & move towards weighted recent noise positions.
Keep emission logic in one script to avoid editing every state.

### Hallucination Visual Layer (Planned - low level priority)
- Add `HallucinationManager` (singleton or node under UI):
  - Listens to `sanity_changed`.
  - Spawns ephemeral sprites / shader overlays.
No changes required in Player logic beyond existing signals.

---

## Planned Data Resource Types (Not Yet Implemented)

| Resource Type | Fields (Draft) | Use |
|---------------|----------------|-----|
| `LogEntryResource` | `title`, `body`, `audio_stream`, `sanity_effect` | Environmental storytelling |
| `DialogueNodeResource` | `id`, `text`, `choices: Array[DialogueChoiceResource]` | Branching narrative |
| `NoiseProfileResource` | `base_strength`, `variance`, `cooldown` | Reusable definitions for emitters |
| `CreatureBehaviorConfig` | `stalk_distance`, `idle_wait_range`, `sanity_aura_strength` | Tuning AI without code edits |

---

## Known Technical Gaps / TODO Seeds

| Gap | Suggested Minimal Patch |
|-----|--------------------------|
| No `Creature` advanced AI | Introduce separate scene w/ pathfinding grid & noise subscription. |
| No saving/loading | Add `SaveManager` with JSON describing: player stats, level name, spawn transition, mental state, flags. |
| Hidden vs Vision interplay static | Add “hearing” radius so hidden but noisy player still triggers search. |
| Damage state re-entry edge cases | Possibly queue damage if already invulnerable for knockback stacking (design decision). |

---

## Debugging Tips

| Issue | Checklist |
|-------|-----------|
| Interactable not triggering | Collision layers/masks, `monitoring = true`, body type (Player has correct layer?), check debug prints in `interactable.gd`. |
| Camera not bounded | Ensure a tilemap triggers `ChangeTilemapBounds` (LevelGeometry or LevelTilemap ready). |
| Player spawns unhidden after hidden transition | Verify `PlayerManager.spawn_hidden` set before `LevelManager.load_new_level` (LevelTransition does this). |
| Enemy not chasing | Confirm `vision_area` node paths exported, player not `is_hidden`. |
| Prompt persists after leaving | `_is_still_overlapping` guards; verify interactable has physics monitoring active. |

---

## Glossary

| Term | Meaning |
|------|--------|
| Gaze Aversion | Mechanic penalizing direct viewing of an entity (planned). |
| Hidden State | Player invisibility to basic vision systems (still physically present). |
| Claustrophobia / Anxiety | Mental pressure variable; anxiety UI currently mapped. |
| Spawn Hidden | Transition behavior where player emerges already inside hiding node. |
| Persistent Player | Player instance not recreated between level scenes; reparented. |

---

## Quick Reference Snippets

### Fade Usage
```gdscript
await SceneTransition.fade_out()
# change scene or perform logic
await SceneTransition.fade_in()
```

### Player State Transition (From Another State)
```gdscript
if PlayerManager.anxiety > 8:
	return panic_state
```

### Interactable Pattern
```gdscript
extends Interactable

func get_prompt_text() -> String: return "Inspect"
func on_interact(player: Player) -> void:
	print("You inspect the panel.")
```
