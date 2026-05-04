extends Node3D

@onready var dialogue_ui       = $DialogueUI
@onready var dialogue_box      = $DialogueUI/DialogueBox
@onready var speaker_label     = $DialogueUI/DialogueBox/SpeakerName
@onready var dialogue_label    = $DialogueUI/DialogueBox/DialogueText
@onready var press_space_label = $DialogueUI/DialogueBox/"PressSpace"  # ← quoted
@onready var anim_player       = $AnimationPlayer
@onready var fade_overlay      = $DialogueUI/FadeOverlay

var typing_tween : Tween
var fade_tween   : Tween
var scene_tween  : Tween

var is_typing         := false
var waiting_input     := false
var full_text_to_show := ""

var dialogue_queue    : Array = []
var cutscene_finished := false

func _ready():
	fade_overlay.color.a      = 1.0
	dialogue_box.modulate.a   = 0.0
	dialogue_ui.visible       = true
	press_space_label.visible = false

	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	scene_tween.tween_callback(func(): anim_player.play("part1_cutscenes"))
	anim_player.animation_finished.connect(_on_cutscene_finished)

# ---- INPUT ----
func _unhandled_input(event: InputEvent):
	if not waiting_input:
		return

	var confirmed = (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	) or (
		event is InputEventKey and
		event.pressed and
		event.keycode in [KEY_SPACE, KEY_ENTER]
	)

	if confirmed:
		waiting_input             = false
		press_space_label.visible = false
		anim_player.play()
		get_viewport().set_input_as_handled()
		_advance_dialogue()

# ---- DIALOGUE QUEUE ----
func queue_dialogue(speaker: String, text: String):
	dialogue_queue.append({ "speaker": speaker, "text": text })
	if not is_typing and not waiting_input:
		_show_next_in_queue()

func _advance_dialogue():
	if dialogue_queue.size() > 0:
		_show_next_in_queue()
	else:
		hide_dialogue()
		if cutscene_finished:
			_do_scene_end()

func _show_next_in_queue():
	var entry = dialogue_queue.pop_front()
	_show_dialogue_internal(entry["speaker"], entry["text"])

# ---- DIALOGUE FUNCTIONS ----
func _show_dialogue_internal(speaker: String, text: String):
	speaker_label.text        = speaker
	dialogue_label.text       = ""
	is_typing                 = true
	waiting_input             = false
	press_space_label.visible = false

	if fade_tween:   fade_tween.kill()
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

	typing_tween.tween_callback(func():
		is_typing                 = false
		waiting_input             = true
		press_space_label.visible = true
		anim_player.pause()
	)

func hide_dialogue():
	if fade_tween:   fade_tween.kill()
	if typing_tween: typing_tween.kill()
	press_space_label.visible = false
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.4)

# ---- SCENE END ----
func _on_cutscene_finished(_anim_name: String):
	if dialogue_queue.size() == 0 and not is_typing and not waiting_input:
		_do_scene_end()
	else:
		cutscene_finished = true

func _do_scene_end():
	hide_dialogue()
	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 1.0, 1.5)
	scene_tween.tween_callback(func():
		print("Ready to load Part 2!")
		get_tree().change_scene_to_file("res://cutscenes/scenes/part_2_walk_to_internship.tscn")
	)
