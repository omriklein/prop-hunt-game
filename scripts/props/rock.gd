extends RigidBody3D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("suiciders"):
		body.die.rpc()
		var thrower_id = get_meta("thrower_id", 1)
		var game_manager = get_tree().current_scene.get_node("GameManager")
		game_manager.add_kill(thrower_id)
	remove_rock.rpc()

@rpc("authority", "call_local")
func remove_rock() -> void:
	queue_free()
