extends CanvasLayer

func show_menu() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_menu() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed() -> void:
	hide_menu()

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
