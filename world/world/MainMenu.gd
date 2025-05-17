extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	%Exit.pressed.connect(quit_game)

	# Connect network signals
	Network.player_joined.connect(_on_player_joined)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	%StartGame.disabled = true

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
	%StartGame.disabled = false



func _on_join_game_button_down() -> void:
	Network.join(Address, port)
 

func _on_start_game_button_down() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		StartGame.rpc()
	elif multiplayer.has_multiplayer_peer():
		print("You're a client. Only the host can start the game.")
	else:
		print("You're not connected to a game.")

func _on_player_joined(id: int) -> void:
	# Only enable start if you're the host and you're ready
	if multiplayer.is_server():
		print("Player joined:", id)
		%StartGame.disabled = false

func _on_connected_to_server() -> void:
	print("Connected to server.")
	# Clients do not enable the Start button
	# You can update UI or show lobby, etc., here if desired
