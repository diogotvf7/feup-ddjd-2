extends Control

var nextScene = 0

func _ready() -> void:
	pass
	$"../ShowMenu".show()
	$"../ShowMenu/AnimationPlayer".play("move")
	$"../ShowMenu".show()

func _on_play_pressed() -> void:
	nextScene = 1
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")

func _on_help_pressed() -> void:
	nextScene = 2
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")
	
func _on_credits_pressed() -> void:
	nextScene = 3
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")

func _on_hide_timer_timeout() -> void:
	if nextScene == 1:
		get_tree().change_scene_to_packed(load("res://scenes/menus/PlayMenu.tscn"))
	elif nextScene == 2:
		get_tree().change_scene_to_packed(load("res://scenes/menus/HelpMenu.tscn"))
	elif nextScene == 3:
		get_tree().change_scene_to_packed(load("res://scenes/menus/CreditsMenu.tscn"))

func _on_exit_pressed() -> void:
	get_tree().quit() 
