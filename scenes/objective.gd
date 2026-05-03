# objective_ui.gd
extends CanvasLayer

@onready var objective_label = $"VBoxContainer/Objective"
@onready var objective_container = $VBoxContainer

func _ready():
	show_objective("Get Home")

func show_objective(text: String):
	objective_label.text = text
	objective_container.visible = true

func complete_objective():
	objective_label.text = "✔ You made it home!"
	await get_tree().create_timer(3.0).timeout
	objective_container.visible = false
