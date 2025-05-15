extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

func _ready() -> void:
	
	# Main Menu Buttons Connections
	%Exit.pressed.connect(quit_game)
	
	
	# Multiplayer Logic
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	

# Gets called on the server and clients
func peer_connected(id):
	print("Player Connected " + id)

# Gets called on the server and clients

func peer_disconnected(id):
	print("Player Disconnected " + id)

# Called only from clients
func connected_to_server():
	print("Connected to Server")

# Called only from clients
func connection_failed():
	print("Couldnt Connect")

func _process(delta: float) -> void:
	pass

func quit_game():
	get_tree().quit() 


func _on_create_game_button_down() -> void:
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	
	if error != OK:
		print("Cannot Host: " + error)
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")
	
	
	pass # Replace with function body.


func _on_join_game_button_down() -> void:
	pass # Replace with function body.


func _on_start_game_button_down() -> void:
	pass # Replace with function body.
