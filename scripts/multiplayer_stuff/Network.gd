# Network.gd  (autoload)
extends Node

signal player_joined(id)
signal player_left(id)

var peer: ENetMultiplayerPeer

const DEFAULT_PORT := 8910
const MAX_PLAYERS_TOTAL := 4

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# ---------- Hosting / Joining ----------

func host(port:int = DEFAULT_PORT) -> void:
	_cleanup_network()

	var max_clients := MAX_PLAYERS_TOTAL - 1
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	if err != OK:
		push_error("Cannot host: %s" % err)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Hosting on port %d..." % port)

	var my_id := multiplayer.get_unique_id()
	_register_player(GameManager.Players.get(my_id, {"name":"Host"}), my_id)


func join(address:String, port:int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

# ---------- Internal callbacks ----------


func _on_peer_connected(id: int) -> void:
	if GameManager.Players.size() >= MAX_PLAYERS_TOTAL:
		print("Lobby full – disconnecting peer", id)
		peer.disconnect_peer(id, true)
		return

	_register_player({"name": "Player %d" % id}, id)
	emit_signal("player_joined", id)


func _on_peer_disconnected(id:int) -> void:
	print("Peer ", id, " disconnected")
	GameManager.Players.erase(id)
	emit_signal("player_left", id)

	if id == 1 and !multiplayer.is_server():
		_return_to_main_menu()


func _on_connected_to_server() -> void:
	print("Connected to server")
	send_player_information.rpc_id(1, "Client %d" % multiplayer.get_unique_id(), multiplayer.get_unique_id())

func _on_connection_failed() -> void:
	print("Connection failed")
	_return_to_main_menu()


# ---------- RPC to exchange names ----------

@rpc("any_peer")
func send_player_information(name:String, id:int) -> void:
	_register_player({"name":name}, id)
	if multiplayer.is_server():
		for p_id in GameManager.Players:
			send_player_information.rpc(GameManager.Players[p_id].name, p_id)

# ---------- Helper ----------

func _cleanup_network() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.set_multiplayer_peer(null)

	GameManager.Players.clear()
	peer = null


func _register_player(info:Dictionary, id:int) -> void:
	GameManager.Players[id] = {"name":info.name, "id":id, "score":0}

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
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
