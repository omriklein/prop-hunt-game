extends Node2D

@onready var name_input: LineEdit = $NameInput
@onready var error_label: Label = $ErrorLabel
@onready var host_list: ItemList = $HostList
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var code_input: LineEdit = $CodeInput
@onready var room_code_label: Label = $RoomCodeLabel
@onready var start_internet_button: Button = $StartInternetButton

var _pending_room_code := ""

func _ready() -> void:
	LanDiscovery.start_listening()
	if PlayerData.error != "":
		error_label.text = PlayerData.error
		PlayerData.error = ""

func _process(_delta: float) -> void:
	var selected_ip := ""
	var selected := host_list.get_selected_items()
	if not selected.is_empty() and selected[0] < LanDiscovery.discovered_hosts.size():
		selected_ip = LanDiscovery.discovered_hosts[selected[0]]["ip"]

	host_list.clear()
	for entry in LanDiscovery.discovered_hosts:
		host_list.add_item(entry["name"] + " (LAN)")

	  # Restore selection
		if selected_ip != "":
			for i in LanDiscovery.discovered_hosts.size():
				if LanDiscovery.discovered_hosts[i]["ip"] == selected_ip:
					host_list.select(i)
					break

func _on_host_button_pressed() -> void:
	if not _can_player_enter():
		return
	LanDiscovery.stop_listening()
	NetworkManager.host_game_lan()

func _on_join_button_pressed() -> void:
	if not _can_player_enter():
		return
	var selected := host_list.get_selected_items()
	if selected.is_empty():
		error_label.text = "Select a game from the list or host a new game"
		return
	var idx: int = selected[0]
	var entry: Dictionary = LanDiscovery.discovered_hosts[idx]
	NetworkManager.join_game_lan(entry["ip"])

func _on_host_internet_pressed() -> void:
	if not _can_player_enter():
		return
	LanDiscovery.stop_listening()
	room_code_label.text = "Getting room code..."
	var relay_http := NetworkManager.RELAY_URL.replace("ws://", "http://").replace("wss://", "https://")
	http_request.request(relay_http + "/new")

func _on_http_request_completed(_result, _code, _headers, body: PackedByteArray) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json.has("code"):
		room_code_label.text = "Failed to get room code"
		return
	_pending_room_code = json["code"]
	room_code_label.text = "Room Code: " + _pending_room_code
	start_internet_button.visible = true

func _on_start_internet_pressed() -> void:
	NetworkManager.host_game_internet(_pending_room_code)
	start_internet_button.visible = false

func _on_join_internet_pressed() -> void:
	if not _can_player_enter():
		return
	var code := code_input.text.strip_edges().to_upper()
	if code.length() < 4:
		error_label.text = "Enter a valid room code"
		return
	LanDiscovery.stop_listening()
	NetworkManager.join_game_internet(code)

func _can_player_enter() -> bool:
	var name = _get_validated_name()
	if name == "":
		return false
	PlayerData.player_name = name
	return true

func _get_validated_name() -> String:
	var name = name_input.text.strip_edges()
	if name.length() < 2:
		error_label.text = "Player name must be at least 2 characters"
		return ""
	return name
