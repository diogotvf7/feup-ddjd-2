extends Node3D

@export_enum("beer", "cereal", "slime", "ammoBox", "rpg") var collectable = "beer"

func _ready() -> void:
	
	match collectable:
		"beer":
			$Beer.visible = true
		"cereal":
			$Cereal.visible = true
		"slime":
			$Slime.visible = true
		"ammoBox":
			$AmmoBox.visible = true
		"rpg":
			$RPG.visible = true
