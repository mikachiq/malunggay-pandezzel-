extends Node3D
@onready var dialogue_ui    = $DialogueUI
@onready var dialogue_box   = $DialogueUI/DialogueBox
@onready var speaker_label  = $DialogueUI/DialogueBox/SpeakerName
@onready var dialogue_label = $DialogueUI/DialogueBox/DialogueText
@onready var anim_player    = $AnimationPlayer
@onready var fade_overlay   = $DialogueUI/FadeOverlay

var typing_tween : Tween
var fade_tween   : Tween
var scene_tween  : Tween
var is_typing := false
var full_text_to_show := ""

func _ready():
	fade_overlay.color.a  = 1.0
	dialogue_box.modulate.a = 0.0
	dialogue_ui.visible   = true

	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	scene_tween.tween_callback(func(): anim_player.play("office_scene"))  # ← plays first

	anim_player.animation_finished.connect(_on_animation_finished)  # ← renamed

# ---- DIALOGUE FUNCTIONS ----
func show_dialogue(speaker: String, text: String):
	speaker_label.text = speaker
	dialogue_label.text = ""
	if fade_tween:  fade_tween.kill()
	if typing_tween: typing_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.4)
	fade_tween.tween_callback(func(): _start_typing(text))

func _start_typing(full_text: String):
	typing_tween = create_tween()
	var current_text = ""
	for i in range(full_text.length()):
		var ch = full_text[i]
		current_text += ch
		var captured = current_text
		var delay = 0.04
		if ch in [".", "!", "?", ","]:
			delay = 0.18
		typing_tween.tween_callback(
			func(): dialogue_label.text = captured
		).set_delay(delay)

func hide_dialogue():
	if fade_tween:  fade_tween.kill()
	if typing_tween: typing_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.4)

# ---- SCENE SEQUENCING ----
func _on_animation_finished(anim_name: String):
	if anim_name == "office_scene":
		# Fade out → swap to hallway → fade back in
		hide_dialogue()
		scene_tween = create_tween()
		scene_tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)  # fade to black
		scene_tween.tween_callback(func(): anim_player.play("hallway_scene"))  # play second
		scene_tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)  # fade back in

	elif anim_name == "hallway_scene":
		# Both scenes done — fade out and finish
		hide_dialogue()
		scene_tween = create_tween()
		scene_tween.tween_property(fade_overlay, "color:a", 1.0, 1.5)
		scene_tween.tween_callback(func():
			print("Ready to load Part 3!")
			# get_tree().change_scene_to_file("res://part_3.tscn")
		)
