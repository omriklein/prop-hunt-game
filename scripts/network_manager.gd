extends Node

const RELAY_URL := "ws://localhost:8787"
const PORT = 777
const MAX_PLAYERS = 8
var host_ip := ""
const GAME_SCENE = "res://scenes/maps/test_game.tscn"

func get_game_manager() -> Node:
	return get_tree().current_scene.get_node("GameManager")

func host_game_lan():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	LanDiscovery.start_host(PlayerData.player_name)

	for address in IP.get_local_addresses():
		if address.begins_with("192.168."):
			host_ip = address
			break
	print("found ip addresses", IP.get_local_addresses())
	print("Hosting game on ", host_ip)

	get_tree().change_scene_to_file(GAME_SCENE)
	await get_tree().scene_changed

	var id = multiplayer.get_unique_id()
	get_game_manager().spawn_player(id, "A")
	get_game_manager().register_name(PlayerData.player_name, id)

func join_game_lan(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_ok() -> void:
	print("Connected to server")
	get_tree().change_scene_to_file(GAME_SCENE)
	await get_tree().scene_changed
	get_game_manager().register_name.rpc_id(1, PlayerData.player_name, multiplayer.get_unique_id())
	LanDiscovery.stop_listening()

func _on_connection_failed() -> void:
	print("Failed to connect to server")

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func _on_player_connected(id):
	if multiplayer.get_unique_id() == 1:
		get_game_manager().spawn_player(id, "B")
	print("Player connected: ", id)

func _on_player_disconnected(id):
	if multiplayer.get_unique_id() == 1:
		get_game_manager().remove_player(id)
	print("Player disconnected: ", id)

var _internet_host_pending := false

func _process(_delta: float) -> void:
	if not _internet_host_pending:
		return
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_internet_host_pending = false
		_finish_internet_host()

func host_game_internet(code: String) -> void:
	var peer := WebSocketMultiplayerPeer.new()
	peer.create_client(RELAY_URL + "/" + code + "/host")
	multiplayer.multiplayer_peer = peer
	_internet_host_pending = true

func _finish_internet_host() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
	await get_tree().scene_changed
	var id := multiplayer.get_unique_id()
	get_game_manager().spawn_player(id, "A")
	get_game_manager().register_name(PlayerData.player_name, id)

func join_game_internet(code: String) -> void:
	var peer := WebSocketMultiplayerPeer.new()
	peer.create_client(RELAY_URL + "/" + code + "/join")
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
