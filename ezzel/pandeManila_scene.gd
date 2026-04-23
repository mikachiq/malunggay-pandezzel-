extends Node3D

@onready var dialogue_ui       = $DialogueUI
@onready var dialogue_box      = $DialogueUI/DialogueBox
@onready var speaker_label     = $DialogueUI/DialogueBox/SpeakerName
@onready var dialogue_label    = $DialogueUI/DialogueBox/DialogueText
@onready var anim_player       = $AnimationPlayer
@onready var fade_overlay      = $DialogueUI/FadeOverlay
@onready var press_enter_label = $DialogueUI/DialogueBox/PressEnterLabel
@onready var camera            = $Camera3D  # NEW

var typing_tween  : Tween
var fade_tween    : Tween
var scene_tween   : Tween
var blink_tween   : Tween
var shake_tween   : Tween  # NEW

var is_waiting    := false
var is_typing     := false
var _full_text    := ""

var _camera_origin := Vector3.ZERO  # NEW

func _ready():
	fade_overlay.color.a       = 1.0
	dialogue_box.modulate.a    = 0.0
	dialogue_ui.visible        = true
	press_enter_label.visible  = false

	scene_tween = create_tween()
	scene_tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	scene_tween.tween_callback(func(): anim_player.play("panDeManila_scene"))
	anim_player.animation_finished.connect(_on_cutscene_finished)

# ---- CAMERA SHAKE ----
func camera_shake(duration := 0.6, strength := 0.15, speed := 25.0):
	_camera_origin = camera.position

	if shake_tween: shake_tween.kill()
	shake_tween = create_tween()

	var steps = int(duration * speed)
	for i in range(steps):
		var t      = float(i) / float(steps)
		var dampen = 1.0 - t
		var offset = Vector3(
			randf_range(-strength, strength) * dampen,
			randf_range(-strength, strength) * dampen,
			0.0
		)
		shake_tween.tween_callback(
			func(): camera.position = _camera_origin + offset
		).set_delay(1.0 / speed)

	# Snap back to original position when done
	shake_tween.tween_callback(func(): camera.position = _camera_origin)

# ---- INPUT HANDLING ----
func _input(event):
	if not event.is_action_pressed("ui_accept"):
		return

	if is_typing:
		if typing_tween: typing_tween.kill()
		dialogue_label.text       = _full_text
		is_typing                 = false
		press_enter_label.visible = true
		_blink_prompt()
		print("Typing skipped. Press Enter again to continue...")
		return

	if is_waiting:
		is_waiting = false
		_stop_blink()
		press_enter_label.visible = false
		hide_dialogue()
		await get_tree().create_timer(0.45).timeout
		anim_player.play()
		print("Resuming scene...")

# ---- BLINK PROMPT ----
func _blink_prompt():
	if blink_tween: blink_tween.kill()
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(press_enter_label, "modulate:a", 0.0, 0.4)
	blink_tween.tween_property(press_enter_label, "modulate:a", 1.0, 0.4)

func _stop_blink():
	if blink_tween: blink_tween.kill()
	press_enter_label.modulate.a = 1.0

# ---- ANIMATION TRACK FUNCTIONS ----
func show_dialogue(speaker: String, text: String):
	anim_player.pause()
	is_waiting  = true
	is_typing   = true
	_full_text  = text
	print("Dialogue triggered. Timeline paused.")

	speaker_label.text        = speaker
	dialogue_label.text       = ""
	press_enter_label.visible = false

	if fade_tween:   fade_tween.kill()
	if typing_tween: typing_tween.kill()
	if blink_tween:  blink_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.4)
	fade_tween.tween_callback(func(): _start_typing(text))

func _start_typing(full_text: String):
	if typing_tween: typing_tween.kill()
	typing_tween = create_tween()

	for i in range(full_text.length()):
		var ch         = full_text[i]
		var captured   = full_text.left(i + 1)
		var char_delay = 0.18 if ch in [".", "!", "?", ","] else 0.04
		typing_tween.tween_callback(
			func(): dialogue_label.text = captured
		).set_delay(char_delay)

	typing_tween.tween_callback(func():
		is_typing                 = false
		press_enter_label.visible = true
		_blink_prompt()
		print("Typing done. Press Enter to continue...")
	)

func hide_dialogue():
	if fade_tween:   fade_tween.kill()
	if typing_tween: typing_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.4)

# ---- SCENE END ----
func _on_cutscene_finished(_anim_name: String):
	if _anim_name == "panDeManila_scene":
		hide_dialogue()
		_stop_blink()
		press_enter_label.visible = false

		scene_tween = create_tween()
		scene_tween.tween_property(fade_overlay, "color:a", 1.0, 1.5)
		scene_tween.tween_callback(func():
			get_tree().change_scene_to_file("res://part_2_walk_to_internship.tscn")
		)
