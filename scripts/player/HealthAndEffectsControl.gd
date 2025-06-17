extends Control

@export var MaxHealth: int = 100

signal effect_done(effect:int)

var health: int = MaxHealth

func damage(attack: Attack) -> void:
	health -= attack.damage
	update_health_bar()
	
	var parent: Node3D = get_parent()
	if parent.has_method("on_damage"):
		parent.on_damage(attack)
	
	if health <= 0:
		health = 0
		get_parent().killPlayer()

func consume(item:int) -> void:
	match item:
		1:
			$BeerEffect.texture = load("res://assets/images/beer_effect_bg.png")
			$BeerEffect/BeerTimer.start()
			if health + 10 > 100:
				health = 100
			else:
				health += 10
		2:
			$CerealEffect.texture = load("res://assets/images/cereal_effect_bg.png")
			$CerealEffect/CerealTimer.start()
			if health + 15 > 100:
				health = 100
			else:
				health += 15
		3:
			$SlimeEffect.texture = load("res://assets/images/slime_effect_bg.png")
			$SlimeEffect/SlimeTimer.start()
			if health + 5 > 100:
				health = 100
			else:
				health += 5
	
	update_health_bar()
	
func revive() -> void:
	health = 20
	update_health_bar()

func _on_beer_timer_timeout() -> void:
	$BeerEffect.texture = load("res://assets/images/beer_effect_no_bg.png")
	emit_signal("effect_done", 1)

func _on_cereal_timer_timeout() -> void:
	$CerealEffect.texture = load("res://assets/images/cereal_effect_no_bg.png")
	emit_signal("effect_done", 2)

func _on_slime_timer_timeout() -> void:
	$SlimeEffect.texture = load("res://assets/images/slime_effect_no_bg.png")
	emit_signal("effect_done", 3)

func update_health_bar():
	var health_ratio = float(health) / float(MaxHealth)
	var new_x = -457 * (1.0 - health_ratio)
	$HealthBar/HealthLevel.position.x = new_x
