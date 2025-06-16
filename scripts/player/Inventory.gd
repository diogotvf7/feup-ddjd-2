extends Control
 
@export var rpg = false
@export var shotgun = true
@export var shotgun_bullets: int = 1
@export var pistol = true
@export var cereal = true
@export var beer = true
@export var slime = true

signal bullets_changed(new_bullets)

var inventory_updated = 0

func _ready() -> void:
	if shotgun:
		$Shotgun.texture = load("res://assets/images/shotgun_bg.png")
		
	if cereal:
		$Cereal.texture = load("res://assets/images/cereal_bg.png")
	else:
		$Cereal.texture = load("res://assets/images/cereal_no_bg.png")
		
	if beer:
		$Beer.texture = load("res://assets/images/beer_bg.png")
	else:
		$Beer.texture = load("res://assets/images/beer_no_bg.png")
		
	if slime:
		$Slime.texture = load("res://assets/images/slime_bg.png")
	else:
		$Slime.texture = load("res://assets/images/slime_no_bg.png")

func _process(delta: float) -> void:
	if inventory_updated > 0:
		if shotgun:
			$Shotgun.texture = load("res://assets/images/shotgun_bg.png")
			
		if cereal:
			$Cereal.texture = load("res://assets/images/cereal_bg.png")
		else:
			$Cereal.texture = load("res://assets/images/cereal_no_bg.png")
			
		if beer:
			$Beer.texture = load("res://assets/images/beer_bg.png")
		else:
			$Beer.texture = load("res://assets/images/beer_no_bg.png")
			
		if slime:
			$Slime.texture = load("res://assets/images/slime_bg.png")
		else:
			$Slime.texture = load("res://assets/images/slime_no_bg.png")
		inventory_updated -= 1
		
func update_bullets() -> void:
	emit_signal("bullets_changed", shotgun_bullets)
