extends Node3D
@onready var animation_tree = $AnimationTree
var is_jumping = false
var jump_blend_speed = 3.0  

func _ready():
	animation_tree.active = true

func _process(delta):
	if not is_jumping:
		var current_jump_blend = animation_tree.get("parameters/is_jumping/blend_amount")
		if current_jump_blend > 0.0:
			var new_blend = max(0.0, current_jump_blend - jump_blend_speed * delta)
			animation_tree.set("parameters/is_jumping/blend_amount", new_blend)

func idle():
	is_jumping = false
	animation_tree.set("parameters/is_running/blend_amount", 0.0)
	animation_tree.set("parameters/is_running_back/blend_amount", 0.0)

func run():
	is_jumping = false
	animation_tree.set("parameters/is_running/blend_amount", 1.0)
	animation_tree.set("parameters/is_running_back/blend_amount", 0.0)

func jump():
	is_jumping = true
	animation_tree.set("parameters/is_jumping/blend_amount", 1.0)
