extends CharacterBody3D

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

var speed: float
var t_bob: float = 0.0
var _gravity: float = -30.0
var is_dead: bool = false
var syncPos: Vector3 = Vector3.ZERO
var is_paused: bool = false
var last_movement_direction: Vector3 = Vector3.BACK
var player_rotation_y: float = 0.0
var character: Node3D = null
var animation_tree: AnimationTree = null

var camera_controller: CameraController

@onready var camera: Camera3D = %Camera3D
@onready var health_label: Label = $HealthLabel
@onready var health_component: Node = $HealthComponent
@onready var character_container: Node3D = %CharacterContainer
@onready var camera_pivot: Node3D = %CameraPivot

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.15
@export var override_camera_fov: float = 0.0

@onready var inventory: Node = $Inventory/InventoryControl
@onready var healthEffects: Node = $HealthAndEffects/HealthAndEffectsControl

@onready var hand: Node
@onready var instantiatedPlayer: Node

# Tutorials
var collectableHelpShowing = false

# Inventory and powerups
var selected_item = 2
var beerEffectFactor = 1
var cerealEffectFactor = 1

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
		var fov_override = overrides.get("fov", 0.0)
		if fov_override > 0.0:
			camera.fov = fov_override

	func handle_input(event: InputEvent, sensitivity: float) -> void:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			input_direction = event.screen_relative * sensitivity * owner_player.beerEffectFactor

	func update_camera_and_player(delta: float) -> void:
		owner_player.player_rotation_y -= input_direction.x * delta
		owner_player.rotation.y = owner_player.player_rotation_y

		pitch += input_direction.y * delta
		pitch = clamp(pitch, -PI/4.0, PI/4.0)

		camera_pivot.rotation.x = pitch

		input_direction = Vector2.ZERO

signal update_bullets

func _ready() -> void:
	_setup_input()
	_setup_camera()
	_load_selected_character()
		
	self.update_bullets.connect(inventory.update_bullets)
	healthEffects.effect_done.connect(_clear_effect)

func _setup_input() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if is_paused:
		return

	camera_controller.handle_input(event, mouse_sensitivity)

func _setup_camera() -> void:
	camera.process_mode = Node.PROCESS_MODE_DISABLED
	camera_controller = CameraController.new(self, camera, camera_pivot)
	
	var overrides = {
		"fov": override_camera_fov
	}
	
	camera_controller.setup_camera(overrides)

func _load_selected_character() -> void:
	# Get the selected character scene path for this specific player
	var character_scene_path = GameManager.get_selected_character_path()
	
	print(character_scene_path)
	# Load and instantiate the character scene
	var character_scene = load(character_scene_path)
	if character_scene:
		instantiatedPlayer = character_scene.instantiate()
		hand = instantiatedPlayer.get_node("Skeleton").get_node("Hand")
		character = instantiatedPlayer
		character_container.add_child(character)

		# Try to get the animation tree from the character
		animation_tree = character.get_node_or_null("AnimationTree")
		if not animation_tree:
		# Try alternative paths where AnimationTree might be located
			for child in character.get_children():
				if child is AnimationTree:
					animation_tree = child
					break

		if animation_tree:
			print("Animation tree found and connected")
		else:
			print("Warning: No AnimationTree found")
	else:
		print("Error: Could not load character scene: ", character_scene_path)

func _process(delta: float) -> void:
	if is_paused:
		pass
		
	# See if tutorial for collectables needs to be shown
	if $CollectableArea.get_overlapping_areas() and not collectableHelpShowing:
		collectableHelpShowing = true
		$Tutorials/CollectableHelp.visible = true
	
	# Hide that same tutorial
	elif not $CollectableArea.get_overlapping_areas() and collectableHelpShowing:
		collectableHelpShowing = false
		$Tutorials/CollectableHelp.visible = false

	if Input.is_action_just_pressed("collect"):
		for area in $CollectableArea.get_overlapping_areas():
			var collectable_node = area.get_parent()
			match collectable_node.collectable:
				"beer":
					if not inventory.beer:
						inventory.beer = true
						inventory.inventory_updated += 1
						collectable_node.queue_free()
				"cereal":
					if not inventory.cereal:
						inventory.cereal = true
						inventory.inventory_updated += 1
						collectable_node.queue_free()
				"slime":
					if not inventory.slime:
						inventory.slime = true
						inventory.inventory_updated += 1
						collectable_node.queue_free()
				"ammoBox":
					inventory.shotgun_bullets += 10
					collectable_node.queue_free()
				"rpg":
					if not inventory.rpg:
						inventory.rpg = true
						inventory.inventory_updated += 1
						collectable_node.queue_free()

	if Input.is_action_just_pressed("shoot"):
		match selected_item:
			1: # Shotgun
				if inventory.shotgun and inventory.shotgun_bullets > 0:
					inventory.shotgun_bullets -= 1
					emit_signal("update_bullets")

					$Shotgun.play()
					hand.get_node("Shotgun").get_node("MuzzleFlash").visible = true
					hand.get_node("Shotgun").get_node("MuzzleFlash").get_node("ShotgunTimer").start()

					shoot_gun(8)
			2: # Pistol
				if inventory.pistol:
					$Pistol.play()
					hand.get_node("Pistol").get_node("MuzzleFlash").visible = true
					hand.get_node("Pistol").get_node("MuzzleFlash").get_node("PistolTimer").start()
					
					shoot_gun(4)
			3: # Beer
				if inventory.beer:
					inventory.beer = false
					inventory.inventory_updated += 1
					
					healthEffects.consume(1)
					beerEffectFactor = -1
					selected_item = 2
					_update_hand_display()
			4: # Cereal
				if inventory.cereal:
					inventory.cereal = false
					inventory.inventory_updated += 1
					
					healthEffects.consume(2)
					cerealEffectFactor = 1.5
					selected_item = 2
					_update_hand_display()
			5: # Slime
				if inventory.slime:
					inventory.slime = false
					inventory.inventory_updated += 1
					
					healthEffects.consume(3)
					$SlimeEffect.visible = true
					selected_item = 2
					_update_hand_display()
			6: # RPG
				if inventory.rpg:
					$RPG.play()
					hand.get_node("RPG").get_node("MuzzleFlash").visible = true
					hand.get_node("RPG").get_node("MuzzleFlash").get_node("RPGTimer").start()
					shoot_gun(50)
					
					inventory.rpg = false
					inventory.inventory_updated += 1
					
					selected_item = 2
					_update_hand_display()
	if Input.is_action_just_pressed("inventory_item_1"):
		if inventory.shotgun:
			selected_item = 1
			_update_hand_display()
	if Input.is_action_just_pressed("inventory_item_2"):
		if inventory.pistol:
			selected_item = 2
			_update_hand_display()
	if Input.is_action_just_pressed("inventory_item_3"):
		if inventory.beer:
			selected_item = 3
			_update_hand_display()
	if Input.is_action_just_pressed("inventory_item_4"):
		if inventory.cereal:
			selected_item = 4
			_update_hand_display()
	if Input.is_action_just_pressed("inventory_item_5"):
		if inventory.slime:
			selected_item = 5
			_update_hand_display()
	if Input.is_action_just_pressed("inventory_item_6"):
		if inventory.rpg:
			selected_item = 6
			_update_hand_display()

func _physics_process(delta: float) -> void:
	if is_paused:
		return    

	_handle_camera_and_rotation(delta)
	_handle_movement(delta)
	_handle_jump()
	move_and_slide()
	_update_character_animation()

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
		velocity.y += JUMP_IMPULSE * cerealEffectFactor

func _update_character_animation() -> void:
	if not character:
		return

	# Try to call animation methods if the character has them
	if not is_on_floor():
		if character.has_method("jump"):
			character.jump()
	else:
		var ground_speed = velocity.length()
		if ground_speed > 0.0:
			if character.has_method("run"):
				character.run()
		else:
			if character.has_method("idle"):
				character.idle()

func _update_hand_display() -> void:
	for i in hand.get_child_count():
		hand.get_child(i).visible = (i == selected_item - 1)
		pass

func _clear_effect(effect:int) ->void:
	match effect:
		1:
			beerEffectFactor = 1
		2: 
			cerealEffectFactor = 1
		3:
			$SlimeEffect.visible = false

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	
func shoot_gun(damage: int) -> void:
	var camera = self.camera

	# Get screen center
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2

	# Use camera to get ray from center of screen
	var from = camera.project_ray_origin(screen_center)
	var direction = camera.project_ray_normal(screen_center)
	var to = from + direction * 2000

	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.exclude = [self]
	query.collision_mask = 0xFFFFFFFF # Assuming layer 4 is for aliens
	
	draw_debug_line(from, to)

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	print(result)

	if result and result.collider and result.collider.is_in_group("alien"):
		print("alien shot")
		result.collider.take_damage(damage)

func draw_debug_line(from: Vector3, to: Vector3, duration := 0.1):
	var line = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	line.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mesh.surface_set_material(0, mat)

	get_tree().current_scene.add_child(line)

	await get_tree().create_timer(duration).timeout
	line.queue_free()
