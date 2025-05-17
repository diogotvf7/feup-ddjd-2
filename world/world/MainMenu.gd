extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

func _ready() -> void:
	
	# Main Menu Buttons Connections
	%Exit.pressed.connect(quit_game)

func quit_game():
	get_tree().quit() 

func _process(delta: float) -> void:
	pass

@rpc("authority", "call_local")
func StartGame():
	var scene = load("res://GameScene.tscn")
	get_tree().change_scene_to_packed(scene)

func _on_create_game_button_down() -> void:
	Network.host() 


func _on_join_game_button_down() -> void:
	Network.join(Address, port)
 

func _on_start_game_button_down() -> void:
	if multiplayer.is_server():
		StartGame.rpc()
	else:
		print("Only the host can start the game.")
