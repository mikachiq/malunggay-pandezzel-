extends Node3D

@onready var dialogue_ui    = $DialogueUI
@onready var dialogue_box   = $DialogueUI/DialogueBox
@onready var speaker_label  = $DialogueUI/DialogueBox/SpeakerName
@onready var dialogue_label = $DialogueUI/DialogueBox/DialogueText
@onready var anim_player    = $AnimationPlayer

var typing_tween : Tween
var fade_tween   : Tween

func _ready():
	dialogue_ui.visible = true
	dialogue_box.modulate.a = 0.0  # start fully invisible
	anim_player.play("city_animations")
	anim_player.animation_finished.connect(_on_cutscene_finished)

# Called by AnimationPlayer — fades IN the box then types the text
func show_dialogue(speaker: String, text: String):
	speaker_label.text = speaker
	dialogue_label.text = ""       # clear old text first

	# Kill any previous tweens so they don't overlap
	if fade_tween:
		fade_tween.kill()
	if typing_tween:
		typing_tween.kill()

	# Fade the box IN over 0.4 seconds
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.4)

	# After the fade finishes, start typing
	fade_tween.tween_callback(func(): _start_typing(text))

# Types out the text letter by letter
func _start_typing(full_text: String):
	typing_tween = create_tween()
	var total_chars = full_text.length()

	for i in range(total_chars):
		# Every 0.04 seconds, add one more character
		typing_tween.tween_callback(
			func(): dialogue_label.text = full_text.substr(0, dialogue_label.text.length() + 1)
		).set_delay(0.04)

# Called by AnimationPlayer — fades OUT the box
func hide_dialogue():
	if fade_tween:
		fade_tween.kill()
	if typing_tween:
		typing_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.4)

func _on_cutscene_finished(_anim_name: String):
	hide_dialogue()
	get_tree().change_scene_to_file("res://part_1_family_warning.tscn");
	print("Cutscene finished!")
