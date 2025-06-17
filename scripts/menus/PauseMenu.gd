extends Control

@onready var pause_manager = get_tree().get_current_scene()

func _on_resume_pressed() -> void:
	get_tree().get_current_scene().resume_game()
	
	var player = get_parent().get_node("PlayerTest")
	if player:
		var inventory_ui = player.get_node_or_null("Inventory/InventoryControl")
		if inventory_ui:
			inventory_ui.visible = true

func _on_leave_game_pressed() -> void:
	$HideMenu.show()
	$HideMenu/HideMenuTimer.start()
	$HideMenu/AnimationPlayer.play("move")

func _on_hide_menu_timer_timeout() -> void:
	get_tree().change_scene_to_packed(load("res://scenes/menus/MainMenu.tscn"))
