extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const THROW_SPEED = 20.0
const ROCK_SCENE = preload("res://scenes/props/rock.tscn")

@onready var camera: Camera3D = $Camera3D
@onready var mesh: Node3D = $Casual_2
@onready var animation_tree: AnimationTree = $AnimationTree
# Sounds
@onready var pickup_sound: AudioStreamPlayer3D = $PickupSound
@onready var throw_sound: AudioStreamPlayer3D = $ThrowSound
@onready var footstep_sound: AudioStreamPlayer3D = $FootstepSound
var is_stepping := false


var rock_count := 0

@onready var pause_menu: CanvasLayer = $PauseMenu
var paused := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Disable cursor
	if not is_multiplayer_authority():
		set_physics_process(false)
	else:
		camera.make_current()
	add_to_group("survivors")

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.002)
		camera.rotate_x(-event.relative.y * 0.002)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("throw"):
		if rock_count > 0:
			rock_count -= 1
			throw_rock.rpc(multiplayer.get_unique_id())

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
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	var playback = animation_tree.get("parameters/playback")
	if Input.is_action_just_pressed("throw"):
		playback.travel("Gun_Shoot")
	elif velocity.length() > 0.1:
		playback.travel("Walk")
	else:
		playback.travel("Idle_Neutral")
	move_and_slide()
	var should_step = is_on_floor() and velocity.length() > 0.1
	if should_step and not is_stepping:
		is_stepping = true
		start_footsteps.rpc()
	elif not should_step and is_stepping:
		is_stepping = false
		stop_footsteps.rpc()
	
@rpc("any_peer", "call_local")
func die():
	rock_count = 0
	set_physics_process(false)
	mesh.visible = false
	await get_tree().create_timer(2).timeout
	global_position = Vector3(0, 2, 0)
	mesh.visible = true
	set_physics_process(is_multiplayer_authority())
	
func add_rocks(amount: int = 1) -> void:
	rock_count += amount
	pickup_sound.play()
	print("Rocks: ", rock_count)

@rpc("any_peer", "call_local")
func throw_rock(thrower_id) -> void:
	throw_sound.play()
	var rock = ROCK_SCENE.instantiate()
	rock.set_meta("thrower_id", thrower_id) # store who threw it
	get_tree().current_scene.add_child(rock)
	# throwing the rock calculations
	rock.global_position = camera.global_position + camera.global_basis.z * -1.0
	rock.linear_velocity = -camera.global_basis.z *  THROW_SPEED

@rpc("any_peer", "call_local")
func start_footsteps() -> void:
	footstep_sound.play()
	
@rpc("any_peer", "call_local")
func stop_footsteps() -> void:
	footstep_sound.stop()
