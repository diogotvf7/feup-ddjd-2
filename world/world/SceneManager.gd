extends Node3D

@export var PlayerScene: PackedScene

func _ready() -> void:
	# Connect the signal so disconnected players are removed
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


func _on_player_left(id: int) -> void:
	print("Player", id, "left the game")
	var player := get_node_or_null(str(id))  # assumes player nodes are named as their ID
	if player:
		player.queue_free()
	else:
		print("Could not find node for player", id)
