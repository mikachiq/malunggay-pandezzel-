extends Control

const HOVER_COLOR := Color(1.0, 0.86, 0.35, 1.0)
const NORMAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)

@onready var _hover_sound: AudioStreamPlayer = $HoverSound
@onready var _buttons: Array[Button] = [
	$PlayBtn,
	$CreditsBtn,
	$QuitBtn,
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for btn in _buttons:
		btn.add_theme_color_override("font_color", NORMAL_COLOR)
		btn.add_theme_color_override("font_color_hover", NORMAL_COLOR)
		btn.mouse_entered.connect(_on_button_hovered.bind(btn))
		btn.mouse_exited.connect(_on_button_unhovered.bind(btn))


func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Intro.tscn");


func _on_credits_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().quit();

func _on_button_hovered(btn: Button) -> void:
	btn.add_theme_color_override("font_color_hover", HOVER_COLOR)
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

func _on_button_unhovered(btn: Button) -> void:
	btn.add_theme_color_override("font_color", NORMAL_COLOR)
	btn.add_theme_color_override("font_color_hover", NORMAL_COLOR)


func _on_setting_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://settings.tscn");
