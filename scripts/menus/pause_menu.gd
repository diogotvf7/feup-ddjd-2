extends Control

@onready var pause_manager = get_tree().get_current_scene()

func _on_resume_pressed() -> void:
	get_tree().get_current_scene().resume_game()


func _on_settings_pressed() -> void:
	print("Settings button pressed – no functionality yet.")


func _on_leave_game_pressed() -> void:
	if Network.has_method("return_to_main_menu"):
		Network.return_to_main_menu()
	else:
		push_error("Network singleton is missing or return_to_main_menu() not found")
