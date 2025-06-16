extends Label

func _ready() -> void:
	text = str($"..".shotgun_bullets)
	$"..".bullets_changed.connect(_on_bullet_change)

func _on_bullet_change(new_bullets: int) -> void:
	text = str(int(new_bullets))
