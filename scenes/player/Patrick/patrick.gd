extends Node3D
@onready var animation_tree = $AnimationTree
var is_jumping = false
var jump_blend_speed = 3.0  # Adjust this for faster/slower transitions

func _ready():
	animation_tree.active = true

func _process(delta):
	# Gradually blend out of jump animation
	if not is_jumping:
		var current_jump_blend = animation_tree.get("parameters/is_jumping/blend_amount")
		if current_jump_blend > 0.0:
			var new_blend = max(0.0, current_jump_blend - jump_blend_speed * delta)
			animation_tree.set("parameters/is_jumping/blend_amount", new_blend)

func idle():
	is_jumping = false
	animation_tree.set("parameters/is_running/blend_amount", 0.0)
	# Don't instantly set jump to 0, let _process handle the gradual transition

func run():
	is_jumping = false
	animation_tree.set("parameters/is_running/blend_amount", 1.0)
	# Don't instantly set jump to 0, let _process handle the gradual transition

func jump():
	is_jumping = true
	animation_tree.set("parameters/is_running/blend_amount", 0.0)
	animation_tree.set("parameters/is_jumping/blend_amount", 1.0)
