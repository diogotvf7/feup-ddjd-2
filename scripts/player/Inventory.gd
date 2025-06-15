extends Control
 
@export var shotgun = false
@export var shotgun_bullets = 0
@export var pistol = true
@export var cereal = false
@export var beer = false
@export var slime = false

signal bullets_changed(new_bullets)

var inventory_updated = 0

func _process(delta: float) -> void:
	if inventory_updated > 0:
		if shotgun:
			$Shotgun.texture = load("res://assets/images/shotgun_bg.png")
		if cereal:
			$Shotgun.texture = load("res://assets/images/cereal_bg.png")
		if beer:
			$Shotgun.texture = load("res://assets/images/beer_bg.png")
		if slime:
			$Shotgun.texture = load("res://assets/images/slime_bg.png")
		inventory_updated -= 1
		
func decrease_bullets() -> void:
	if shotgun_bullets > 0:
		shotgun_bullets -= 1
		emit_signal("bullets_changed", shotgun_bullets)
