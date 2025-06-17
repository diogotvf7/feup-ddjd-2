extends Node3D

@onready var animation_tree = $AnimationTree
var is_attacking = false
var is_dead = false
var attack_blend_speed = 5.0

func _ready():
	animation_tree.active = true

func _process(delta):
	if not is_attacking and not is_dead:
		var current_attack_blend = animation_tree.get("parameters/is_attacking/blend_amount")
		if current_attack_blend > 0.0:
			var new_blend = max(0.0, current_attack_blend - attack_blend_speed * delta)
			animation_tree.set("parameters/is_attacking/blend_amount", new_blend)

func idle():
	if is_dead:
		return
	is_attacking = false
	animation_tree.set("parameters/is_running/blend_amount", 0.0)

func run():
	if is_dead:
		return
	is_attacking = false
	animation_tree.set("parameters/is_running/blend_amount", 1.0)

func attack():
	if is_dead:
		return
	is_attacking = true
	animation_tree.set("parameters/is_attacking/blend_amount", 1.0)

func die():
	is_dead = true
	is_attacking = false
	animation_tree.set("parameters/is_dead/blend_amount", 1.0)
	animation_tree.set("parameters/is_running/blend_amount", 0.0)
	animation_tree.set("parameters/is_attacking/blend_amount", 0.0)
