extends Area3D

func _on_body_entered(body: Node3D) -> void:
	# only survivors can pick it up
	if not body.is_in_group("survivors"):
		return
	# prevent other triggers from the network
	if not body.is_multiplayer_authority():
		return
	body.add_rocks(10)
	var gm = get_tree().current_scene.get_node("GameManager")
	
	# Server calls spawn directly, client calls via rpc
	var idx = get_meta("spawn_index")
	if multiplayer.is_server():
		gm.schedule_crate_respawn(idx)
	else:
		gm.schedule_crate_respawn.rpc_id(1, idx)
	
	remove_crate.rpc()

@rpc("authority","call_local")
func remove_crate():
	queue_free()
