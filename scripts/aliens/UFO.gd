extends Node3D

var ufo_rotation_factor_x := 0.0
var cow_rotation_factor_x := 0.0
var cow_rotation_factor_y := 0.0
var cow_rotation_factor_z := 0.0


func _ready() -> void:
	ufo_rotation_factor_x = randf_range(-1.0, 1.0)

	cow_rotation_factor_x = randf_range(-1.0, 1.0)
	cow_rotation_factor_y = randf_range(-1.0, 1.0)
	cow_rotation_factor_z = randf_range(-1.0, 1.0)

func _process(delta: float) -> void:
	$UFO_0422110228_texture.rotate_y(ufo_rotation_factor_x * delta)
	$UFO_0422110228_texture.rotate_x(0.0001 * cos(delta))
	$UFO_0422110228_texture.rotate_z(0.0001 * sin(delta))
	
	$Cow_0422082433_texture.rotate_y(cow_rotation_factor_y * delta)
	$Cow_0422082433_texture.rotate_x(cow_rotation_factor_x * delta)
	$Cow_0422082433_texture.rotate_z(cow_rotation_factor_z * delta)
