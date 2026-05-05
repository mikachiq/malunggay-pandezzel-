extends Area3D

var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not triggered:
		triggered = true
		var ui = get_tree().get_first_node_in_group("objective_ui")
		if ui:
			ui.complete_objective()
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://cutscenes/scenes/final_cutscene.tscn")
