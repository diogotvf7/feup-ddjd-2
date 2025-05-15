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
	

func quit_game():
	get_tree().quit() 


# Gets called on the server and clients
func peer_connected(id):
	print("Player Connected " + str(id))

# Gets called on the server and clients

func peer_disconnected(id):
	print("Player Disconnected " + str(id))

# Called only from clients
func connected_to_server():
	print("Connected to Server")
	SendPlayerInformation.rpc_id(1, %LineEdit.text, multiplayer.get_unique_id())

# Called only from clients
func connection_failed():
	print("Couldnt Connect")

func _process(delta: float) -> void:
	pass

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)



@rpc("authority", "call_local")
func StartGame():
	var scene = load("res://testBox.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_create_game_button_down() -> void:
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	
	if error != OK:
		print("Cannot Host: " + error)
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")
	SendPlayerInformation(%LineEdit.text, multiplayer.get_unique_id())


func _on_join_game_button_down() -> void:
	
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
 

func _on_start_game_button_down() -> void:
	if multiplayer.is_server():
		StartGame.rpc()  # Only server should trigger the RPC
	else:
		print("Only the host can start the game.")
