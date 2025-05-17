extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	%Exit.pressed.connect(quit_game)

	Network.player_joined.connect(_on_player_joined)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

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
	if multiplayer.has_multiplayer_peer():
		print("Resetting previous connection before hosting...")
		multiplayer.multiplayer_peer.close()
		multiplayer.set_multiplayer_peer(null)
	
	Network.host()
	%StartGame.disabled = false


func _on_join_game_button_down() -> void:
	%StartGame.disabled = true
	Network.join(Address, port)

func _on_start_game_button_down() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		StartGame.rpc()
	elif multiplayer.has_multiplayer_peer():
		print("You're a client. Only the host can start the game.")
	else:
		print("You're not connected to a game.")

func _on_player_joined(id: int) -> void:
	if multiplayer.is_server():
		print("Player joined:", id)
		%StartGame.disabled = false

func _on_connected_to_server() -> void:
	print("Connected to server.")
	if !multiplayer.is_server():
		%StartGame.disabled = true

func _on_connection_failed() -> void:
	print("Connection failed")
	%StartGame.disabled = true
