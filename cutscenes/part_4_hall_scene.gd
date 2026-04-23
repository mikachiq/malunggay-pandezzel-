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

# ---- SCENE LIST (edit this to add/remove/reorder scenes) ----
var scene_queue : Array[String] = ["office_scene", "hallway_scene"]
var current_scene_index := 0

# ---------------------------------------------------------------

func _ready():
	fade_overlay.color.a    = 1.0
	dialogue_box.modulate.a = 0.0
	dialogue_ui.visible     = true

	anim_player.animation_finished.connect(_on_animation_finished)

	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	scene_tween.tween_callback(_play_current_scene)


# ---- SCENE PLAYBACK ----

func _play_current_scene():
	if current_scene_index < scene_queue.size():
		anim_player.play(scene_queue[current_scene_index])
	else:
		_on_all_scenes_finished()


func _on_animation_finished(_anim_name: String):
	print("Animation finished: ", _anim_name)  # ← ADD THIS
	hide_dialogue()
	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	scene_tween.tween_callback(_advance_to_next_scene)


func _advance_to_next_scene():
	current_scene_index += 1
	if current_scene_index < scene_queue.size():
		_play_current_scene()
		scene_tween = create_tween()
		scene_tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	else:
		_on_all_scenes_finished()


func _on_all_scenes_finished():
	# Disconnect signal first to prevent any further firing
	anim_player.animation_finished.disconnect(_on_animation_finished)
	anim_player.stop()  # hard stop the animation player
	
	print("All cutscenes finished!")
	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 1.0, 1.5)
	scene_tween.tween_callback(func(): print("Done — ready to change scene"))
	# get_tree().change_scene_to_file("res://your_next_scene.tscn")


# ---- DIALOGUE FUNCTIONS ----  ← THIS ENTIRE SECTION WAS MISSING

func show_dialogue(speaker: String, text: String):
	speaker_label.text  = speaker
	dialogue_label.text = ""

	if fade_tween:  fade_tween.kill()
	if typing_tween: typing_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.4)
	fade_tween.tween_callback(func(): _start_typing(text))


func _start_typing(full_text: String):
	typing_tween = create_tween()
	var current_text := ""

	for i in range(full_text.length()):
		var ch = full_text[i]
		current_text += ch
		var captured = current_text
		var delay := 0.04

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
