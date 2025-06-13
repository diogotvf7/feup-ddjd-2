extends Control

func _ready() -> void:
	$"../ShowMenu".show()
	$"../ShowMenu/AnimationPlayer".play("move")
	$"../ShowMenu".show()
	
func quit_game():
	get_tree().quit() 

func _on_play_pressed() -> void:
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")

func _on_hide_timer_timeout() -> void:
	get_tree().change_scene_to_packed(load("res://scenes/menus/PlayMenu.tscn"))

func _on_exit_pressed() -> void:
	get_tree().quit() 
