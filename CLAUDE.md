# Prop Hunt Game — Dev Context

## How to Collaborate
**Do NOT make code changes.** Act as a Godot expert advisor only.
- Explain what to do, step by step, in plain language
- Reference specific nodes, scene paths, script names, and GDScript snippets the user should write themselves
- If asked to implement something, describe the implementation clearly instead of writing the files



Godot 4 multiplayer prop-hunt game. Survivors (FPS) try to survive against Suiciders (3rd-person) who explode to kill them.

## Current State
- Multiplayer networking via ENet (network_manager.gd, game_manager.gd)
- Survivor: FPS CharacterBody3D, basic movement/jump, die/respawn via RPC
- Suicider: 3rd-person CharacterBody3D, explosion mechanic kills nearby survivors, respawns
- Scenes: map.tscn, test_game.tscn, main_menu.tscn, explosion.tscn, wall.tscn
- Suicider uses house_plant.glb model; Survivor uses Casual_2 model with AnimationTree
- Rock collection and throwing working; scoring working (kills tracked by name, shown in UI)
- Round timer working; pause menu working; player names working (validated, synced, duplicate rejection)
- Rock crates spawn at round start via MultiplayerSpawner, respawn after 10s cooldown
- Survivor sounds: footsteps (looping, 3D, RPC), rock pickup, rock throw — all wired
- Suicider sounds: explosion (AudioStreamPlayer3D in explosion.tscn, autoplay), sprint lalalala (logic done, awaiting audio file)

## Game Design
- Suiciders run at survivors and self-destruct (AOE kill)
- Survivors collect rocks from crates and throw them to kill suiciders (instant kill on hit)
- Rounds are time-limited; survivors win by surviving the timer, suiciders win by killing all survivors

---

## TODO List

### 1. Game Map
- [ ] Design a real map layout in `scenes/maps/map.tscn` with walls, cover objects, corridors, and open areas
- [ ] Set proper spawn points (Node3D markers) for both teams
- [ ] Add lighting (DirectionalLight3D + ambient)

### 2. Suicider Model ✅
- [x] Import or create a 3D model for the suicider (e.g. a simple humanoid or creature mesh)
- [x] Replace the placeholder MeshInstance3D in `scenes/player/suicider.tscn`
- [x] No animations — suicider is a prop (house plant), animations N/A

### 3. Survivor Model + Animations ✅
- [x] Import or create a 3D model for the survivor (humanoid, FPS arms or full body)
- [x] Replace the placeholder MeshInstance3D in `scenes/player/survivor.tscn`
- [x] Add AnimationPlayer/AnimationTree with states: idle, walk, throw (Gun_Shoot)
- [x] Wire animations to movement velocity in `scripts/survivor_controller.gd`

### 4. Sounds
- [x] Suicider: explosion blast — AudioStreamPlayer3D in explosion.tscn, autoplay ON
- [x] Suicider: "lalalala" sound — plays once on sprint start, full playback guaranteed; lalalala.mp3 assigned to SprintSound in suicider.tscn
- [x] Survivor: footsteps — looping AudioStreamPlayer3D, RPC start/stop, heard by all players
- [x] Survivor: rock pickup — AudioStreamPlayer3D in survivor.tscn, plays in add_rocks()
- [x] Survivor: rock throw — AudioStreamPlayer3D in survivor.tscn, plays inside throw_rock RPC (heard by all)
- [ ] Add ambient/background music to the game scene
- [x] Import .ogg or .wav audio files into `assets/sounds/`

### 5. Rock Collection (Survivor) ✅
- [x] Create `scenes/props/rock_crate.tscn` — Area3D crate, gives +10 rocks, networked removal
- [x] In `scripts/survivor_controller.gd`: `rock_count` variable, pick up on contact, RPC synced

### 6. Rock Throwing (Survivor kills Suicider) ✅
- [x] Create `scenes/props/rock.tscn` — RigidBody3D projectile
- [x] `scripts/props/rock.gd` — kills suicider on hit, disappears on any collision
- [x] Throw on left click, launched from camera direction, decrement rock_count

### 7. Scoring ✅
- [x] `kills` dictionary in `game_manager.gd` (keyed by peer ID)
- [x] Suicider scores +1 per survivor killed by explosion
- [x] Survivor scores +1 when rock kills a suicider
- [x] Synced via `@rpc` and displayed in `Scores` label in InfoDisplay

### 8. Round Timer ✅
- [x] `RoundTimer` (120s, one-shot) + `SyncTimer` (1s, repeating) in test_game.tscn
- [x] Server broadcasts time via `sync_time.rpc` every second
- [x] On timer end: `end_round.rpc("survivors")` shows "survivors Win!" on all peers

### 9. In-Game Menu (Pause Menu) ✅
- [x] Create `scenes/ui/pause_menu.tscn` — CanvasLayer with resume, exit buttons
- [x] In survivor/suicider controllers: toggle pause menu on [Escape]; release mouse capture while open
- [x] Pause menu does NOT pause physics (multiplayer-safe)

### 10. Rock Crate Spawning ✅
- [x] Spawn points (Node3D markers) defined in test_game.tscn under CratesSpawnPoints
- [x] Spawn rock crates at round start via MultiplayerSpawner (CrateSpawner under GameManager)
- [x] After a crate is looted, respawns after 10s cooldown via schedule_crate_respawn RPC

### 12. Suicider Sprint ✅
- [x] Add sprint mechanic to suicider only (not survivor)
- [x] Hold Shift to sprint: increase move speed (2x base speed)
- [x] Wire sprint state in `scripts/suicider_controller.gd`

### 11. Player Names ✅
- [x] Name input field on main menu; validated (min 2 chars, trimmed), stored in PlayerData autoload
- [x] Name passed to game_manager.gd, stored in player_names dict, duplicate rejection with error feedback
- [x] Scoreboard displays names; synced to all peers via sync_all_names RPC
