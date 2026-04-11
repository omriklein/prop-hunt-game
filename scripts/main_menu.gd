extends Node2D

@onready var ip_text: TextEdit = $IPText
@onready var name_input: LineEdit = $NameInput
@onready var error_label: Label = $ErrorLabel

func _ready() -> void:
	if PlayerData.error != "":
		error_label.text = PlayerData.error
		PlayerData.error = "" # TODO: check this workflow and verify

func _on_host_button_pressed() -> void:
	if _can_player_enter():
		NetworkManager.host_game()

func _on_join_button_pressed() -> void:
	if _can_player_enter():
		NetworkManager.join_game(ip_text.text)

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
