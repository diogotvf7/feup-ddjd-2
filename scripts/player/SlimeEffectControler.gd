extends Control

var hue := 0.0

func _process(delta):
	hue += delta * 0.2 # Adjust speed as desired
	if hue > 1.0:
		hue -= 1.0
	$ColorRect.color = Color.from_hsv(hue, 1.0, 1.0, 0.2)
