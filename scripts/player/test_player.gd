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

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand = $Head/Camera3D/Hand
@onready var health_label: Label = $HealthLabel
@onready var health_component: Node = $HealthComponent
@onready var inventory: Node = $Inventory/InventoryControl
@onready var healthEffects: Node = $HealthAndEffects/HealthAndEffectsControl

var syncPos = Vector3.ZERO
var is_paused := false
var selected_item = 2

var beerEffectFactor = 1
var cerealEffectFactor = 1

signal update_bullets

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
		
	self.update_bullets.connect(inventory.update_bullets)
	healthEffects.effect_done.connect(_clear_effect)
	

func _process(delta: float) -> void:
	#health_label.text = str(health_component.health)
	pass

func _unhandled_input(event: InputEvent) -> void:
	if is_paused:
		return

	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY * beerEffectFactor)
			camera.rotate_x(-event.relative.y * SENSITIVITY * beerEffectFactor)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta: float) -> void:
	if is_paused:
		return

	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("jump") and is_on_floor():
			$Jump.play()
			velocity.y = JUMP_VELOCITY * cerealEffectFactor

		if Input.is_action_pressed("sprint") and is_on_floor():
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED
			
		if Input.is_action_just_pressed("collect"):
			for body in $InteractArea.get_overlapping_bodies():
				if body.is_in_group("collectable"):
					match body.name:
						"Shotgun", "RPG", "Cereal", "Beer", "Slime":
							inventory.set(body.name.to_lower(), true)
							inventory.inventory_updated += 1
						"AmmoBox":
							inventory.shotgun_bullets += 10
							emit_signal("update_bullets")
					body.queue_free()

		if Input.is_action_just_pressed("shoot"):
			match selected_item:
				1: # Shotgun
					if inventory.shotgun and inventory.shotgun_bullets > 0:
						inventory.shotgun_bullets -= 1
						emit_signal("update_bullets")
						
						$Shotgun.play()
						# Add shooting logic here
				2: # Pistol
					if inventory.pistol:
						$Pistol.play()
						# Add pistol shooting logic here
						pass
				3: # Beer
					if inventory.cereal:
						inventory.cereal = false
						inventory.inventory_updated += 1
						
						healthEffects.consume(1)
						beerEffectFactor = -1
						selected_item = 2
						_update_hand_display()
				4: # Cereal
					if inventory.beer:
						inventory.beer = false
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
		if Input.is_action_just_pressed("inventory_item_1"):
			if inventory.shotgun:
				selected_item = 1
				_update_hand_display()
		if Input.is_action_just_pressed("inventory_item_2"):
			if inventory.pistol:
				selected_item = 2
				_update_hand_display()
		if Input.is_action_just_pressed("inventory_item_3"):
			if inventory.cereal:
				selected_item = 3
				_update_hand_display()
		if Input.is_action_just_pressed("inventory_item_4"):
			if inventory.beer:
				selected_item = 4
				_update_hand_display()
		if Input.is_action_just_pressed("inventory_item_5"):
			if inventory.slime:
				selected_item = 5
				_update_hand_display()
		#if Input.is_action_just_pressed("inventory_item_6"):
		#	if inventory.rpg:
		#		selected_item = 6
		#		_update_hand_display()
			
		var input_dir := Input.get_vector("left", "right", "up", "down")
		var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if is_on_floor():
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

		syncPos = global_position

		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
		#$Hand.global_rotation = $Head/Camera3D.global_rotation

		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

		move_and_slide()
	else:
		global_position = global_position.lerp(syncPos, 0.5)

func _update_hand_display() -> void:
	for i in hand.get_child_count():
		hand.get_child(i).visible = (i == selected_item - 1)

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

func on_death() -> void:
	get_tree().quit()
