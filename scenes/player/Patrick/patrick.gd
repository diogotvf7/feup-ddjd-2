extends Node3D

@onready var animation_tree = $AnimationTree

func _ready():
	animation_tree.active = true

func idle():
	# Set blend parameters to show idle animation
	animation_tree.set("parameters/is_running/blend_amount", 0.0)  
	animation_tree.set("parameters/is_jumping/blend_amount", 0.0) 

func run():
	animation_tree.set("parameters/is_running/blend_amount", 1.0)  
	
func jump():
	pass
