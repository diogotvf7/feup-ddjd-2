extends Node

# Character selection system
enum CharacterType { PATRICK, ALICE, RICHARD }

# Store character selection as a single string (scene path)
var player_character_path : String = "res://scenes/player/Patrick/patrick.tscn"
var player_character_id : CharacterType = CharacterType.PATRICK
var player_character_name = "Patrick"

func set_selected_character(character_type: CharacterType) -> void:
	match character_type:
		CharacterType.PATRICK:
			player_character_path = "res://scenes/player/Patrick/patrick.tscn"
			player_character_id = CharacterType.PATRICK
			player_character_name = "Patrick"
		CharacterType.ALICE:
			player_character_path = "res://scenes/player/Alice/alice.tscn"
			player_character_id = CharacterType.ALICE
			player_character_name = "Alice"
		CharacterType.RICHARD:
			player_character_path = "res://scenes/player/Richard/richard.tscn"
			player_character_id = CharacterType.RICHARD
			player_character_name = "Richard"

# Get the selected character scene path
func get_selected_character_id() -> int:
	return player_character_id

func get_selected_character_path() -> String:
	return player_character_path
	
func get_selected_character_name() -> String:
	return player_character_name
