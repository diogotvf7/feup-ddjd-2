extends Node3D

@export var PlayerScene: PackedScene

@onready var pauseMenu = $PauseMenu
var paused = false

func _ready() -> void:
	Network.player_left.connect(_on_player_left)

	# Spawn all current players
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		add_child(currentPlayer)

		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position

		index += 1

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_menu()

func pause_menu():
	if paused:
		pauseMenu.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		pauseMenu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var local_player := get_node_or_null(str(multiplayer.get_unique_id()))
	if local_player:
		local_player.is_paused = !paused

	paused = !paused

func resume_game():
	if paused:
		pause_menu()

func _on_player_left(id: int) -> void:
	print("Player", id, "left the game")
	var player := get_node_or_null(str(id))
	if player:
		player.queue_free()
	else:
		print("Could not find node for player", id)
