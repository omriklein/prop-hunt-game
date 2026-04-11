extends Node

const SURVIVOR = preload("res://scenes/player/survivor.tscn")
const SUICIDER = preload("res://scenes/player/suicider.tscn")

const ROUND_TIME = 120.0

var respawn_position = Vector3(0, 2, 0)

var players = {}
var player_types = {}

var player_names = {}
var kills = {} # { player peer_id: int }

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var scores: Label = $"../InfoDisplay/Scores"
# Timer
@onready var round_timer: Timer = $"../RoundTimer"
@onready var sync_timer: Timer = $"../SyncTimer"
@onready var timer_label: Label = $"../InfoDisplay/TimerLabel"

# Crate Spawner
const ROCK_CRATE_SCENE = preload("res://scenes/props/rock_crate.tscn")
const ROCK_CRATE_TIMER = 10.0 # seconds until next spawn
@onready var crate_spawner: MultiplayerSpawner = $CrateSpawner
@onready var crates_spawn_points: Node3D = $"../CratesSpawnPoints"

func _ready():
	spawner.spawn_function = _spawn_player
	crate_spawner.spawn_function = _spawn_crate
	if multiplayer.is_server():
		_init_timers()
		_spawn_all_crates()

func _spawn_player(data) -> Node:
	var player: Node
	if data.type == "A":
		player = SURVIVOR.instantiate()
	else:
		player = SUICIDER.instantiate()
	player.name = str(data.id)
	player.set_multiplayer_authority(data.id)
	player.global_position = respawn_position
	players[data.id] = player
	player_types[data.id] = data.type
	return player

func spawn_player(id: int, type: String):
	spawner.spawn({"id": id, "type": type})

#region score\ kills
func add_kill(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if not kills.has(peer_id):
		kills[peer_id] = 0
	kills[peer_id] += 1
	sync_score.rpc(kills)

@rpc("authority", "call_local","reliable")
func sync_score(new_kills: Dictionary) -> void:
	kills = new_kills
	scores.text = _format_score()

func _format_score() -> String:
	var lines := []
	for id in kills:
		var player_name = player_names.get(id, str(id))
		lines.append("%s: %d" % [player_name, kills[id]])
	return "\n".join(lines)
#endregion

#region Timer functions
func _init_timers() -> void:
	round_timer.wait_time = ROUND_TIME
	round_timer.start()
	sync_timer.start()
	sync_time.rpc(ROUND_TIME)

func _on_sync_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	var round_time_left = round_timer.time_left
	sync_time.rpc(round_time_left)

func _on_round_timer_timeout() -> void:
	sync_timer.stop()
	end_round.rpc("survivors")

@rpc("authority", "call_local", "reliable")
func sync_time(time_left: float) -> void:
	var min = int(time_left) / 60
	var secs = int(time_left) % 60
	timer_label.text = "%d:%02d" % [min,secs]

@rpc("authority","call_local","reliable")
func end_round(winner: String) -> void:
	timer_label.text = winner + " Win!"
	# TODO: show results screen, return to lobby
#endregion

#region Crates spawner
func _spawn_all_crates() -> void:
	var spawn_index := 0
	for spawn_point in crates_spawn_points.get_children():
		crate_spawner.spawn({"index": spawn_index, "position": spawn_point.global_position})
		spawn_index += 1

func _spawn_crate(data: Dictionary) -> Node:
	var crate = ROCK_CRATE_SCENE.instantiate()
	crate.position = data.position
	crate.set_meta("spawn_index", data.index)
	return crate

@rpc("any_peer")
func schedule_crate_respawn(spawn_index: int) -> void:
	if not multiplayer.is_server():
		return
	await get_tree().create_timer(ROCK_CRATE_TIMER).timeout
	var spawn_point = crates_spawn_points.get_child(spawn_index)
	crate_spawner.spawn({"index": spawn_index, "position": spawn_point.global_position})
#endregion
		
@rpc("authority", "reliable")
func name_rejected(reason: String):
	print("name rejected!!")
	PlayerData.error = reason
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

@rpc("any_peer", "reliable")
func register_name(name: String, peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if player_names.values().has(name):
		print("name already taken")
		remove_player(peer_id)
		name_rejected.rpc_id(peer_id, "Name already taken")
		return
	player_names[peer_id] = name
	sync_player_names.rpc(player_names)

@rpc("authority", "call_local", "reliable")
func sync_player_names(names: Dictionary) -> void:
	player_names = names

func remove_player(id: int) -> void:
	if not multiplayer.is_server():
		return
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	player_types.erase(id)
	player_names.erase(id)
	kills.erase(id)
