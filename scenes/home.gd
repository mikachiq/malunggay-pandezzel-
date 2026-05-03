# home_trigger.gd
extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var ui = get_tree().get_first_node_in_group("objective_ui")
		if ui:
			ui.complete_objective()
		print("Player reached home!")
