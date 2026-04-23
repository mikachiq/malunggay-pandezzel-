extends OmniLight3D

@export var min_energy := 0.2
@export var max_energy := 1.5
@export var flicker_speed := 0.1

func _process(delta):
	if randf() < flicker_speed:
		light_energy = randf_range(min_energy, max_energy)
