extends Control

var next_scene: int = 0  # 0 = back to main, 1 = continue to play

func _ready() -> void:
	$"../ShowMenu".show()
	$"../ShowMenu/AnimationPlayer".play("move")
	$"../ShowMenu".show()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Initialize character selection UI
	_update_character_selection_ui()

func _update_character_selection_ui():
	var patrick_indicator = %PatrickIndicator
	var alice_indicator = %AliceIndicator
	
	# Show/hide indicators based on current local player's selection
	var current_selection = GameManager.get_selected_character()
	patrick_indicator.visible = (current_selection == GameManager.CharacterType.PATRICK)
	alice_indicator.visible = (current_selection == GameManager.CharacterType.ALICE)

func _on_patrick_button_pressed() -> void:
	GameManager.set_selected_character(GameManager.CharacterType.PATRICK)
	_update_character_selection_ui()

func _on_alice_button_pressed() -> void:
	GameManager.set_selected_character(GameManager.CharacterType.ALICE)
	_update_character_selection_ui()

func _on_continue_button_pressed() -> void:
	next_scene = 1
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")

func _on_back_button_pressed() -> void:
	next_scene = 0
	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")

func _on_hide_timer_timeout() -> void:
	if next_scene == 1:
		# Go to PlayMenu if Continue was pressed
		get_tree().change_scene_to_packed(load("res://scenes/menus/PlayMenu.tscn"))
	else:
		# Go back to MainMenu if Back was pressed
		get_tree().change_scene_to_packed(load("res://scenes/menus/MainMenu.tscn")) 