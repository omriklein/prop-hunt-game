extends Node2D

@onready var name_input: LineEdit = $NameInput
@onready var error_label: Label = $ErrorLabel
@onready var host_list: ItemList = $HostList

func _ready() -> void:
	LanDiscovery.start_listening()
	if PlayerData.error != "":
		error_label.text = PlayerData.error
		PlayerData.error = "" # TODO: check this workflow and verify

func _process(delta: float) -> void:
	var selected_ip := ""
	var selected := host_list.get_selected_items()
	if not selected.is_empty() and selected[0] < LanDiscovery.discovered_hosts.size():
		selected_ip =  LanDiscovery.discovered_hosts[selected[0]]["ip"]
	
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

func _can_player_enter() -> bool:
	var name = _get_validated_name();
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
