# Network.gd  (autoload)
extends Node

signal player_joined(id)
signal connection_failed_ui
signal connection_successful_ui
signal player_info_updated

var peer: ENetMultiplayerPeer
var _pending_player_name = null

const MAX_PLAYERS_TOTAL := 4

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
# ------------------
# Hosting / Joining 
# ------------------
func host(port:int, myName:String) -> void:
	_cleanup_network()
	var max_clients := MAX_PLAYERS_TOTAL - 1
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	if err != OK:
		push_error("Cannot host: %s" % err)
		
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Hosting on %d..." % port)
	var my_id := multiplayer.get_unique_id()
	_register_player(myName, my_id)

func join(address:String, port:int, name:String) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	_pending_player_name = name
	print("joined and registered player %s", name)

# -------------------
# Internal callbacks
# -------------------
func _on_peer_connected(id: int) -> void:
	if GameManager.Players.size() >= MAX_PLAYERS_TOTAL:
		print("Lobby full – disconnecting peer", id)
		peer.disconnect_peer(id, true)
		return
		
	emit_signal("player_joined", id)

func _on_peer_disconnected(id:int) -> void:
	print("Peer ", id, " disconnected")
	GameManager.Players.erase(id)
	
	# Broadcast updated player list to all clients
	if multiplayer.is_server():
		for p_id in GameManager.Players:
			send_player_information.rpc(GameManager.Players[p_id].name, p_id)

	emit_signal("player_info_updated")

	if id == 1 and !multiplayer.is_server():
		_return_to_main_menu()

func _on_connected_to_server() -> void:
	if !multiplayer.is_server():
		print("Connected to server")
		emit_signal("connection_successful_ui")
		if _pending_player_name != null:
			send_player_information.rpc_id(1, _pending_player_name, multiplayer.get_unique_id())
			print("Sent player info for", _pending_player_name)
			_pending_player_name = null

func _on_connection_failed() -> void:
	if !multiplayer.is_server():
		print("Connection failed")
		emit_signal("connection_failed_ui")

# --------------------------------------------------------------------------
# RPC function to exchange names between all peers connected, host included
# --------------------------------------------------------------------------
@rpc("any_peer")
func send_player_information(name:String, id:int) -> void:
	_register_player(name, id)
	if multiplayer.is_server():
		for p_id in GameManager.Players:
			send_player_information.rpc(GameManager.Players[p_id].name, p_id)
	
	print("Emitting player_info_updated signal")
	emit_signal("player_info_updated")

# -----------------
# Helper functions
# -----------------
func _cleanup_network() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.set_multiplayer_peer(null)

	GameManager.Players.clear()
	peer = null

func _register_player(name:String, id:int) -> void:
	GameManager.Players[id] = {"name":name, "id":id, "score":0}

@rpc("authority")
func force_clients_to_return():
	_return_to_main_menu()

@rpc("authority", "call_local")
func return_to_main_menu():
	_return_to_main_menu()

func _return_to_main_menu() -> void:
	if multiplayer.is_server():
		force_clients_to_return.rpc()

	_cleanup_network()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/menus/PlayMenu.tscn")
