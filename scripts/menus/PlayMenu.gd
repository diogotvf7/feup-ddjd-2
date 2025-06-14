extends Control

var peer

var button_type = "";
var hostGame = true;
var modeSwitched = false;

func _ready() -> void:
	$"../ShowMenu".show()
	$"../ShowMenu/AnimationPlayer".play("move")
	$"../ShowMenu".show()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	Network.connection_failed_ui.connect(_on_connection_failed_ui)
	Network.connection_successful_ui.connect(_on_connection_successful_ui)
	Network.player_info_updated.connect(_on_player_info_updated)

	%StartGame.disabled = true

func _process(delta: float) -> void:
	pass

@rpc("authority", "call_local")
func StartGame():
	var scene = load("res://scenes/world/GameScene.tscn")
	get_tree().change_scene_to_packed(scene)

# ------------------------------------
# Functions related to hosting a game
# ------------------------------------
func _on_create_game_button_down() -> void:
	var port_text = %HostPort.text
	var name = $HostStuff/HostName.text

	if name == "" or not port_text.is_valid_int():
		print("Invalid name or port")
		$HostStuff/FailedHost.visible = true
		$HostStuff/FailedHost/FailedHostTimer.start(4.0)
		
		$HostStuff/HostName.text = ""
		%HostPort.text = ""
		return
		
	var port = int(%HostPort.text)
	if port < 1 or port > 65535:
		print("Port out of range")
		$HostStuff/FailedHost.visible = true
		$HostStuff/FailedHost/FailedHostTimer.start(4.0)
		
		$HostStuff/HostName.text = ""
		%HostPort.text = ""
		return

	if multiplayer.has_multiplayer_peer():
		print("Resetting previous connection before hosting...")
		multiplayer.multiplayer_peer.close()
		multiplayer.set_multiplayer_peer(null)
	
	Network.host(port, name)
	
	%StartGame.disabled = false
	$HostStuff/Lobby.visible  = true
	$"HostStuff/Create Game".disabled = true
	$HostStuff/HostName.text = ""
	%HostPort.text = ""
	
	update_lobby_ui()

func _on_start_game_button_down() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		StartGame.rpc()
	elif multiplayer.has_multiplayer_peer():
		print("You're a client. Only the host can start the game.")
	else:
		print("You're not connected to a game.")

func _on_host_game_pressed() -> void:
	$JoinStuff.visible = false
	$HostStuff.visible = true

func _on_close_lobby_pressed() -> void:
	if multiplayer.is_server():
		Network.force_clients_to_return()
	
	$"HostStuff/Create Game".disabled = false
	
	Network._cleanup_network()
	
	$"HostStuff/Create Game".disabled = false
	%StartGame.disabled = true
	$HostStuff/Lobby.visible = false

# ------------------------------------
# Functions related to joining a game
# ------------------------------------
func _on_join_game_button_down() -> void:
	var ip = %JoinIP.text
	var port_text = %JoinPort.text
	var name = $JoinStuff/JoinName.text
	
	var ip_regex = RegEx.new()
	ip_regex.compile(r"^(\d{1,3}\.){3}\d{1,3}$")
	var ip_valid = ip_regex.search(ip) != null
	
	if ip == "" or name == "" or not port_text.is_valid_int() or not ip_valid:
		print("Invalid ip, name or port")
		$JoinStuff/FailedJoin.visible = true
		$JoinStuff/FailedJoin/FailedJoinTimer.start(4.0)
		
		%JoinIP.text = ""
		%JoinPort.text = ""
		$JoinStuff/JoinName.text = ""
		return
		
	var port = int(%JoinPort.text)
	if port < 1 or port > 65535:
		print("Port out of range")
		$HostStuff/FailedHost.visible = true
		$HostStuff/FailedHost/FailedHostTimer.start(4.0)
		
		%JoinIP.text = ""
		%JoinPort.text = ""
		$JoinStuff/JoinName.text = ""
		return
	
	Network.join(ip, port, name)
	
	$"JoinStuff/Join Game".disabled = true
	%JoinIP.text = ""
	%JoinPort.text = ""
	$JoinStuff/JoinName.text = ""
	
func _on_join_game_pressed() -> void:
	$HostStuff.visible = false
	$JoinStuff.visible = true

func _on_leave_game_pressed() -> void:
	if multiplayer.has_multiplayer_peer():
		Network.return_to_main_menu.rpc_id(1) # Ask server to remove this client
		Network._cleanup_network()
		
		$"JoinStuff/Join Game".disabled = true
		$JoinStuff/Success.visible = false
		$JoinStuff/Failure.visible = false

# ---------------
# Misc functions
# ---------------
func update_lobby_ui():
	var player_slots = [
		$HostStuff/Lobby/Players/Player1,
		$HostStuff/Lobby/Players/Player2,
		$HostStuff/Lobby/Players/Player3,
		$HostStuff/Lobby/Players/Player4
	]

	var players = GameManager.Players.values()

	for i in range(player_slots.size()):
		var slot = player_slots[i]
		var bg = slot.get_node("Background")
		var label = slot.get_node("Label")
		if i < players.size():
			bg.color = Color(0.282, 0.447, 0.223) # green
			label.text = "%s - Ready" % players[i].name
			print("%s - Ready" % players[i].name)
		else:
			bg.color = Color(0.643, 0.196, 0.086) # red
			label.text = "Player not connected"

func _on_player_info_updated():
	update_lobby_ui()

func _on_back_pressed() -> void:
	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			_on_close_lobby_pressed()
		else:
			_on_leave_game_pressed()

	$"../HideMenu".show()
	$"../HideMenu/HideTimer".start()
	$"../HideMenu/AnimationPlayer".play("move")

func _on_hide_timer_timeout() -> void:
	get_tree().change_scene_to_packed(load("res://scenes/menus/MainMenu.tscn"))

func _on_hide_timout_timeout() -> void:
	var failure = $JoinStuff.get_node_or_null("Failure")
	if failure:
		failure.visible = false

func _on_failed_host_timer_timeout() -> void:
	var failed_host = $HostStuff.get_node_or_null("FailedHost")
	if failed_host:
		failed_host.visible = false

func _on_failed_join_timer_timeout() -> void:
	var failed_join = $JoinStuff.get_node_or_null("FailedJoin")
	if failed_join:
		failed_join.visible = false

func _on_connection_failed_ui() -> void:
	$JoinStuff/Failure.visible = true
	$JoinStuff/Failure/HideTimout.start(4.0)
	
func _on_connection_successful_ui() -> void:
	$JoinStuff/Success.visible = true
