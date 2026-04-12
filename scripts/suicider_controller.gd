extends CharacterBody3D

const SPEED = 5.0
const SPRINT_SPEED = 2 * SPEED
const JUMP_VELOCITY = 4.5
const EXPLOSION_SCENE = preload("res://scenes/props/explosion.tscn")

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var explosion_area: Area3D = $ExplosionArea
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var mesh: Node3D = $"House plant"


@onready var pause_menu: CanvasLayer = $PauseMenu
var paused := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Disable cursor
	if not is_multiplayer_authority():
		set_physics_process(false)
	else:
		camera.make_current()
	add_to_group("suiciders")
	
	
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.002)
		spring_arm.rotate_x(-event.relative.y * 0.002)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/3, PI/6)
	
	if event.is_action_pressed("explode"):
		_explode()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_cancel"):
		paused = !paused
		if paused:
			pause_menu.show_menu()
		else:
			pause_menu.hide_menu()
			

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwords")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var curr_speed = SPEED
	if Input.is_action_pressed("sprint"):
		curr_speed = SPRINT_SPEED
	if direction:
		velocity.x = direction.x * curr_speed
		velocity.z = direction.z * curr_speed
	else:
		velocity.x = move_toward(velocity.x, 0, curr_speed)
		velocity.z = move_toward(velocity.z, 0, curr_speed)
	move_and_slide()
	
func _explode() -> void:
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("survivors"):
			_report_kill.rpc_id(1, get_multiplayer_authority())
			body.die.rpc()
	_destory.rpc()
	
@rpc("any_peer","call_local")
func _destory() -> void:
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.position = global_position
	get_tree().current_scene.add_child(explosion)
	die()

@rpc("any_peer", "call_local")
func die() -> void:
	mesh.visible = false
	set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	global_position = Vector3(0, 2, 0)
	mesh.visible = true
	set_physics_process(is_multiplayer_authority())
	
@rpc("any_peer")
func _report_kill(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var gam_manager = get_tree().current_scene.get_node("GameManager")
	gam_manager.add_kill(peer_id)
