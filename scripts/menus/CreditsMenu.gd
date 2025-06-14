extends Control

func _ready() -> void:
	$"../ShowMenu".show()
	$"../ShowMenu/AnimationPlayer".play("move")
	$"../ShowMenu".show()

func _on_hide_timer_timeout() -> void:
	get_tree().change_scene_to_packed(load("res://scenes/menus/MainMenu.tscn"))

func _on_back_pressed() -> void:
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")
