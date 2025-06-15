extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5


@onready var camera: Camera3D = %Camera3D

@onready var health_label: Label = $HealthLabel
@onready var health_component: Node = $HealthComponent

var syncPos = Vector3.ZERO
var is_paused := false

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.15

var _camera_input_direction := Vector2.ZERO
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
		#if not is_on_floor():
			#velocity += get_gravity() * delta
#
		#if Input.is_action_just_pressed("jump") and is_on_floor():
			#velocity.y = JUMP_VELOCITY
#
		#if Input.is_action_pressed("sprint") and is_on_floor():
			#speed = SPRINT_SPEED
		#else:
			#speed = WALK_SPEED
			#
		#var input_dir := Input.get_vector("left", "right", "up", "down")
		##var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
#
		##if is_on_floor():
			##if direction:
				##velocity.x = direction.x * speed
				##velocity.z = direction.z * speed
			##else:
				##velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
				##velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		##else:
			##velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
			##velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
#
		#syncPos = global_position
#
		#t_bob += delta * velocity.length() * float(is_on_floor())
		#camera.transform.origin = _headbob(t_bob)
#
		#var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		#var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
		#camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
#
		#move_and_slide()
	#else:
		#global_position = global_position.lerp(syncPos, 0.5)


#func _headbob(time) -> Vector3:
	#var pos = Vector3.ZERO
	#pos.y = sin(time * BOB_FREQ) * BOB_AMP
	#pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	#return pos
#
#func on_death() -> void:
	#get_tree().quit()
