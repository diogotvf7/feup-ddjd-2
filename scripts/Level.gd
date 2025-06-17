extends Node3D

@onready var pauseMenu = $PauseMenu
@onready var player = $PlayerTest

var paused = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_menu()

func pause_menu():
	if paused:
		pauseMenu.hide()
		
		if player:
			var inventory_ui = player.get_node_or_null("Inventory")
			if inventory_ui:
				inventory_ui.visible = true
			
			var health_ui = player.get_node_or_null("HealthAndEffects")
			if health_ui:
				health_ui.visible = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		pauseMenu.show()
		
		if player:
			var inventory_ui = player.get_node_or_null("Inventory")
			if inventory_ui:
				inventory_ui.visible = false
				
			var health_ui = player.get_node_or_null("HealthAndEffects")
			if health_ui:
				health_ui.visible = false
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var local_player := get_node_or_null(str(multiplayer.get_unique_id()))
	if local_player:
		local_player.is_paused = !paused

	paused = !paused

func resume_game():
	if paused:
		pause_menu()
