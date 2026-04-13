extends Node3D

@export var zombie_scene: PackedScene
@export var spawn_count: int = 10
@export var spawn_radius: float = 25.0
@export var respawn: bool = false
@export var respawn_delay: float = 5.0

func _ready():
	if zombie_scene == null:
		print("ERROR: No zombie scene assigned to spawner!")
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	for i in spawn_count:
		# Evenly space zombies in a circle
		var angle = (float(i) / spawn_count) * TAU
		var distance = randf_range(spawn_radius * 0.7, spawn_radius)
		var spawn_pos = global_position + Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		spawn_zombie(spawn_pos)

func spawn_zombie(pos: Vector3 = Vector3.ZERO):
	var zombie = zombie_scene.instantiate()
	get_parent().add_child(zombie)
	
	if pos == Vector3.ZERO:
		# Random position for respawns
		var angle = randf() * TAU
		var distance = randf_range(spawn_radius * 0.7, spawn_radius)
		pos = global_position + Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
	
	zombie.global_position = pos
	print("Zombie spawned at: ", pos)
	
	if respawn:
		zombie.tree_exited.connect(_on_zombie_died)

func _on_zombie_died():
	await get_tree().create_timer(respawn_delay).timeout
	spawn_zombie()
