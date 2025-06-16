extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const ACCELERATION = 15.0
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0
var ROTATION_SPEED = 10.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
const JUMP_IMPULSE = 10.0

var _gravity := -30.0

@onready var camera: Camera3D = %Camera3D

@onready var health_label: Label = $HealthLabel
@onready var health_component: Node = $HealthComponent

@onready var character: Node3D = %Character
@onready var animation_tree: AnimationTree = %Character/AnimationTree

var syncPos = Vector3.ZERO
var is_paused := false

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.15

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
@onready var camera_pivot: Node3D = %CameraPivot

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var owner_id := int(name)
	$MultiplayerSynchronizer.set_multiplayer_authority(owner_id)

	var is_local := multiplayer.get_unique_id() == owner_id

	camera.current = is_local
	if !is_local:
		camera.process_mode = Node.PROCESS_MODE_DISABLED
		health_label.visible = false
	else:
		health_label.visible = true



func _process(delta: float) -> void:
	health_label.text = str(health_component.health)

func _unhandled_input(event: InputEvent) -> void:
	if is_paused:
		return

	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		var is_camera_motion := (
			event is InputEventMouseMotion and 
			Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		)
		if is_camera_motion:
			_camera_input_direction = event.screen_relative * mouse_sensitivity
			
			


func _physics_process(delta: float) -> void:
	if is_paused:
		return

	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		camera_pivot.rotation.x += _camera_input_direction.y * delta
		camera_pivot.rotation.x = clamp(camera.rotation.x, -PI/6.0, PI/3.0)
		camera_pivot.rotation.y -= _camera_input_direction.x * delta
		
		_camera_input_direction = Vector2.ZERO
		
		var raw_input := Input.get_vector("left", "right", "up", "down")
		var 	forward := camera.global_basis.z
		var right := camera.global_basis.x

		var move_direction := forward * raw_input.y + right * raw_input.x

		move_direction.y = 0.0
		move_direction = move_direction.normalized()
		
		var y_velocity := velocity.y
		velocity.y = 0.0
		velocity = velocity.move_toward(move_direction * WALK_SPEED, ACCELERATION * delta)
		velocity.y = y_velocity + _gravity * delta
		
		var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
		if is_starting_jump:
			velocity.y += JUMP_IMPULSE
			
		move_and_slide()
		
		if move_direction.length() > 0.2:
			_last_movement_direction = move_direction
		
		var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
		character.global_rotation.y = lerp_angle(character.rotation.y, target_angle, ROTATION_SPEED * delta)
		
		if is_starting_jump:
			character.jump()
		elif is_on_floor():
			var ground_speed := velocity.length()
			if ground_speed > 0.0:
				character.run()
			else:
				character.idle()

		
		
