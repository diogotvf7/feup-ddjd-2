extends CharacterBody3D

#region Constants
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const ACCELERATION = 15.0
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
const JUMP_IMPULSE = 10.0
const DEATH_Y = -30.0
const ROTATION_SPEED = 10.0
#endregion

#region Variables
var speed: float
var t_bob: float = 0.0
var _gravity: float = -30.0
var is_dead: bool = false
var syncPos: Vector3 = Vector3.ZERO
var is_paused: bool = false
var last_movement_direction: Vector3 = Vector3.BACK
var player_rotation_y: float = 0.0
#endregion

#region Camera System
class CameraController:
	var camera: Camera3D
	var camera_pivot: Node3D
	var owner_player: CharacterBody3D
	
	var input_direction: Vector2 = Vector2.ZERO
	var pitch: float = 0.0
	
	func _init(player: CharacterBody3D, cam: Camera3D, pivot: Node3D):
		owner_player = player
		camera = cam
		camera_pivot = pivot
	
	func setup_camera(overrides: Dictionary) -> void:
		# Apply FOV override if provided
		var fov_override = overrides.get("fov", 0.0)
		if fov_override > 0.0:
			camera.fov = fov_override
		
		print("Camera setup complete. FOV: ", camera.fov)
	
	func handle_input(event: InputEvent, sensitivity: float) -> void:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			input_direction = event.screen_relative * sensitivity
	
	func update_camera_and_player(delta: float) -> void:
		# Update player rotation based on camera input
		owner_player.player_rotation_y -= input_direction.x * delta
		owner_player.rotation.y = owner_player.player_rotation_y
		
		# Update camera pitch
		pitch += input_direction.y * delta
		pitch = clamp(pitch, -PI/4.0, PI/4.0)
		
		# Apply pitch to camera pivot
		camera_pivot.rotation.x = pitch
		
		# Clear input for next frame
		input_direction = Vector2.ZERO

var camera_controller: CameraController
#endregion

#region Node References
@onready var camera: Camera3D = %Camera3D
@onready var health_label: Label = $HealthLabel
@onready var health_component: Node = $HealthComponent
@onready var character: Node3D = %Character
@onready var animation_tree: AnimationTree = %Character/AnimationTree
@onready var camera_pivot: Node3D = %CameraPivot
#endregion

#region Export Variables
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.15
@export var override_camera_fov: float = 0.0
#endregion

#region Initialization
func _ready() -> void:
	_setup_input()
	_setup_multiplayer()
	_setup_camera()

func _setup_input() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_multiplayer() -> void:
	var owner_id = int(name)
	$MultiplayerSynchronizer.set_multiplayer_authority(owner_id)
	var is_local = multiplayer.get_unique_id() == owner_id
	
	camera.current = is_local
	
	if is_local:
		health_label.visible = true
	else:
		camera.process_mode = Node.PROCESS_MODE_DISABLED
		health_label.visible = false

func _setup_camera() -> void:
	camera_controller = CameraController.new(self, camera, camera_pivot)
	
	var overrides = {
		"fov": override_camera_fov
	}
	
	camera_controller.setup_camera(overrides)
#endregion

#region Input Handling
func _unhandled_input(event: InputEvent) -> void:
	if _should_ignore_input():
		return
	
	if _is_local_player():
		camera_controller.handle_input(event, mouse_sensitivity)

func _should_ignore_input() -> bool:
	return is_paused or is_dead

func _is_local_player() -> bool:
	return $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
#endregion

#region Physics and Movement
func _physics_process(delta: float) -> void:
	if _should_ignore_input():
		return
	
	if _check_death():
		return
	
	if _is_local_player():
		_handle_camera_and_rotation(delta)
		_handle_movement(delta)
		_handle_jump()
		move_and_slide()
		_update_character_animation()

func _check_death() -> bool:
	if global_position.y < DEATH_Y:
		die()
		return true
	return false

func _handle_camera_and_rotation(delta: float) -> void:
	camera_controller.update_camera_and_player(delta)

func _handle_movement(delta: float) -> void:
	var input_vector = Input.get_vector("left", "right", "up", "down")
	var movement_direction = _calculate_movement_direction(input_vector)
	
	var y_velocity = velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(movement_direction * WALK_SPEED, ACCELERATION * delta)
	velocity.y = y_velocity + _gravity * delta

func _calculate_movement_direction(input_vector: Vector2) -> Vector3:
	var forward = -global_basis.z
	var right = -global_basis.x
	var direction = forward * input_vector.y + right * input_vector.x
	direction.y = 0.0
	return direction.normalized()

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += JUMP_IMPULSE

func _update_character_animation() -> void:
	var was_jumping = Input.is_action_just_pressed("jump") and is_on_floor()
	
	if was_jumping:
		character.jump()
	elif is_on_floor():
		var ground_speed = velocity.length()
		if ground_speed > 0.0:
			character.run()
		else:
			character.idle()
#endregion

#region UI Updates
func _process(delta: float) -> void:
	_update_health_display()

func _update_health_display() -> void:
	health_label.text = str(health_component.health)
#endregion

#region Death and Game Management
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	print("Player died!")
	
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	restart_game()

func restart_game() -> void:
	get_tree().reload_current_scene()
#endregion
