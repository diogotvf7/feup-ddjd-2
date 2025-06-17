extends Node

var Players = {}

# Character selection system
enum CharacterType { PATRICK, ALICE, RICHARD }

# Store character selections per player ID
var player_character_selections : Dictionary = {}

# Character scene paths
const CHARACTER_SCENES = {
	CharacterType.PATRICK: "res://scenes/player/Patrick/patrick.tscn",
	CharacterType.ALICE: "res://scenes/player/Alice/alice.tscn",
	CharacterType.RICHARD: "res://scenes/player/Richard/richard.tscn"
}

# Character display names
const CHARACTER_NAMES = {
	CharacterType.PATRICK: "Patrick",
	CharacterType.ALICE: "Alice", 
	CharacterType.RICHARD: "Richard"
}

# Get the scene path for a specific player's selected character
func get_player_character_scene(player_id: int) -> String:
	var character = player_character_selections.get(player_id, CharacterType.PATRICK)
	return CHARACTER_SCENES[character]

# Get the scene path for the local player's selected character
func get_selected_character_scene() -> String:
	var local_player_id = multiplayer.get_unique_id()
	return get_player_character_scene(local_player_id)

# Set the selected character for the local player
func set_selected_character(character: CharacterType) -> void:
	var local_player_id = multiplayer.get_unique_id()
	player_character_selections[local_player_id] = character
	print("Player ", local_player_id, " selected character: ", CHARACTER_NAMES[character])
	
	# Notify all other players about our character selection
	_sync_character_selection.rpc(local_player_id, character)

# RPC function to synchronize character selection across all clients
@rpc("any_peer", "call_remote", "reliable")
func _sync_character_selection(player_id: int, character: CharacterType) -> void:
	player_character_selections[player_id] = character
	print("Received character selection: Player ", player_id, " selected ", CHARACTER_NAMES[character])

# Get the selected character for a specific player
func get_player_character_selection(player_id: int) -> CharacterType:
	return player_character_selections.get(player_id, CharacterType.PATRICK)

# Get the selected character for the local player
func get_selected_character() -> CharacterType:
	var local_player_id = multiplayer.get_unique_id()
	return get_player_character_selection(local_player_id)

# Get all available characters
func get_available_characters() -> Array:
	return [CharacterType.PATRICK, CharacterType.ALICE, CharacterType.RICHARD]

func get_character_name(character: CharacterType) -> String:
	return CHARACTER_NAMES[character]

# Send all character selections to a newly connected player
func sync_all_character_selections_to_player(player_id: int) -> void:
	for pid in player_character_selections:
		_sync_character_selection.rpc_id(player_id, pid, player_character_selections[pid])

# Called when a new player connects (should be called from Network.gd)
func on_player_connected(player_id: int) -> void:
	# Send all existing character selections to the new player
	call_deferred("sync_all_character_selections_to_player", player_id)
