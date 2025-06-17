extends CharacterBody3D

@export var MoveSpeed: float = 2.0
@export var AttackReach: float = 1.5
@export var MinAttackDistance: float = 0.8  # Minimum distance to maintain from player
@export var RotationSpeed: float = 8.0  # How fast the alien rotates to face direction
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var alien_character: Node3D = $Alien

var attack_cooldown: float = 1.5              # seconds between attacks
var time_since_last_attack: float = 0.0       # timer for attack cooldown
var is_dead: bool = false
var was_moving_last_frame: bool = false
var is_currently_attacking: bool = false

var health = 50

func _physics_process(delta: float) -> void:
	if not is_dead:
		process_move(delta)

func process_move(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		if was_moving_last_frame:
			alien_character.idle()
			was_moving_last_frame = false
		return

	var closest_player: CharacterBody3D = null
	var closest_distance: float = INF

	# Find the closest player
	for p in players:
		if not p or not p.is_inside_tree():
			continue
		var distance = global_position.distance_to(p.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = p

	if closest_player == null:
		if was_moving_last_frame:
			alien_character.idle()
			was_moving_last_frame = false
		return

	# ⏱️ Handle attack cooldown and attack logic
	time_since_last_attack += delta
	var distance_to_player = global_position.distance_to(closest_player.global_position)
	
	if distance_to_player < AttackReach:
		# Close enough to attack - face the player directly and stop moving
		var direction_to_player = global_position.direction_to(closest_player.global_position)
		rotate_towards_direction(direction_to_player, delta)
		
		# Stop movement when in attack range
		velocity = Vector3.ZERO
		
		if was_moving_last_frame:
			alien_character.idle()
			was_moving_last_frame = false
		
		# If too close, back away slightly
		if distance_to_player < MinAttackDistance:
			var pushback_direction = closest_player.global_position.direction_to(global_position)
			velocity = pushback_direction * MoveSpeed * 0.5  # Move away at half speed
		
		if time_since_last_attack >= attack_cooldown:
			is_currently_attacking = true
			alien_character.attack()
			var attack: Attack = Attack.new(1.0, self)
			#closest_player.health_component.damage(attack)
			time_since_last_attack = 0.0  # Reset cooldown
			
			# Brief pause during attack animation
			await get_tree().create_timer(0.5).timeout
			is_currently_attacking = false
	else:
		# Not in attack range - move towards player
		if not is_currently_attacking:
			# Set path to closest player
			navigation_agent_3d.set_target_position(closest_player.global_position)

			if navigation_agent_3d.is_navigation_finished():
				if was_moving_last_frame:
					alien_character.idle()
					was_moving_last_frame = false
				return

			var next_position: Vector3 = navigation_agent_3d.get_next_path_position()
			var direction = global_position.direction_to(next_position)
			velocity = direction * MoveSpeed

			# Moving towards player - face movement direction
			rotate_towards_direction(direction, delta)
			
			if not was_moving_last_frame:
				alien_character.run()
				was_moving_last_frame = true

	move_and_slide()

func rotate_towards_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.1:  # Only rotate if there's a significant direction
		var target_rotation = atan2(direction.x, direction.z)
		var current_rotation = rotation.y
		
		# Calculate the shortest angular distance
		var angle_diff = target_rotation - current_rotation
		while angle_diff > PI:
			angle_diff -= 2 * PI
		while angle_diff < -PI:
			angle_diff += 2 * PI
		
		# Smoothly rotate towards target
		var rotation_step = RotationSpeed * delta
		if abs(angle_diff) < rotation_step:
			rotation.y = target_rotation
		else:
			rotation.y += sign(angle_diff) * rotation_step

func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		on_death()

func on_death() -> void:
	if not is_dead:
		is_dead = true
		alien_character.die()
		# Wait a bit before destroying to let death animation play
		await get_tree().create_timer(3.9).timeout
		
		# Spawn collectable of type slime
		#var collectable_scene = preload("res://scenes/consumables/Collectable.tscn")
		#var collectable_instance = collectable_scene.instantiate()
		#collectable_instance.collectable = "slime"
		#collectable_instance.global_transform = global_transform

		# Add to the 'collectables' node (parent of parent of this node)
		#var collectables_node = get_parent().get_parent().get_node("collectables")
		#collectables_node.add_child(collectable_instance)

		queue_free()
