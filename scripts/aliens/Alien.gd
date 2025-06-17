extends CharacterBody3D

@export var MoveSpeed: float = 2.0
@export var AttackReach: float = 1.5
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

var attack_cooldown: float = 2.0              # seconds between attacks
var time_since_last_attack: float = 0.0       # timer for attack cooldown

func _physics_process(delta: float) -> void:
	process_move(delta)

func process_move(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return

	var closest_player: CharacterBody3D = null
	var closest_distance: float = INF

	# Find the closest player
	for p in players:
		if not p or not p.is_inside_tree() or p.amDead:
			continue
		var distance = global_position.distance_to(p.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = p

	if closest_player == null:
		return

	# Set path to closest player
	navigation_agent_3d.set_target_position(closest_player.global_position)

	if navigation_agent_3d.is_navigation_finished():
		return

	var next_position: Vector3 = navigation_agent_3d.get_next_path_position()
	velocity = global_position.direction_to(next_position) * MoveSpeed

	# ⏱️ Handle attack cooldown and attack logic
	time_since_last_attack += delta
	if global_position.distance_to(closest_player.global_position) < AttackReach:
		if time_since_last_attack >= attack_cooldown:
			var attack: Attack = Attack.new(1.0, self)
			#closest_player.health_component.damage(attack)
			time_since_last_attack = 0.0  # Reset cooldown

	move_and_slide()

func on_death() -> void:
	queue_free()
