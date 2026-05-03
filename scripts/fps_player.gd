extends CharacterBody3D

const SPEED = 5.5
const GRAVITY = 9.8
const MOUSE_SENSITIVITY = 0.002

const INSPECT_START = 0.0
const INSPECT_END = 7.50
const SHOOT_START = 7.50
const SHOOT_END = 8.13
const RELOAD_START = 8.30
const RELOAD_END = 10.82

const FOOTSTEP_INTERVAL = 0.38

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var ray = $SpringArm3D/Camera3D/RayCast3D
@onready var ammo_label = $CanvasLayer/HUD/AmmoLabel
@onready var bread_label = $CanvasLayer/HUD/BreadLabel
@onready var distance_label = $CanvasLayer/HUD/DistanceLabel
@onready var health_label = $CanvasLayer/HUD/HealthLabel
@onready var mc_model = $mcrunning
@onready var anim = $mcrunning/AnimationPlayer
@onready var weapon_holder = $SpringArm3D/Camera3D/weaponholder
@onready var fpov = $SpringArm3D/Camera3D/weaponholder/FPOV
@onready var weapon_anim = $SpringArm3D/Camera3D/weaponholder/FPOV/AnimationPlayer
@onready var damage_overlay = $CanvasLayer/HUD/DamageOverlay
@onready var footstep_player = $FootstepPlayer

var gun_sound = null
var tween: Tween = null

var ammo = 15
var bread = 2
var health = 100
var can_shoot = true
var camera_pitch = 0.0
var run_anim_name = ""
var is_fps_mode = false
var is_reloading = false
var mc_mesh = null
var is_dead = false
var game_over_layer: CanvasLayer = null
var footstep_timer = 0.0

# --- Distance Tracker ---
var mc_house: Node3D = null

const TP_SPRING_LENGTH = 3.0
const TP_SPRING_POS = Vector3(0.5, 1.5, 0)
const FPS_SPRING_LENGTH = 0.0
const FPS_SPRING_POS = Vector3(0, 1, 0)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_hud()
	_apply_third_person()
	mc_model.position.y = -1.0

	var anims = anim.get_animation_list()
	for a in anims:
		if "run" in a.to_lower() or "walk" in a.to_lower():
			run_anim_name = a
			break
	if run_anim_name == "" and anims.size() > 0:
		run_anim_name = anims[0]

	weapon_holder.visible = false
	mc_mesh = mc_model.find_child("geometry_0", true, false)

	var light = OmniLight3D.new()
	light.light_energy = 2.0
	light.omni_range = 3.0
	light.position = Vector3(0, 0, -0.5)
	weapon_holder.add_child(light)

	if has_node("SpringArm3D/Camera3D/weaponholder/GunShotSound"):
		gun_sound = $SpringArm3D/Camera3D/weaponholder/GunShotSound
		gun_sound.max_polyphony = 4
		gun_sound.bus = "Master"

	if damage_overlay:
		damage_overlay.color = Color(1, 0, 0, 0.0)

	await get_tree().process_frame
	mc_house = get_tree().get_root().find_child("MC house", true, false)
	if mc_house == null:
		push_warning("Distance Tracker: 'MC house' node not found in scene!")

func show_mc_for_camera():
	if mc_mesh:
		mc_mesh.set_layer_mask_value(1, true)
		mc_mesh.set_layer_mask_value(2, false)
	camera.set_cull_mask_value(2, true)

func hide_mc_from_camera():
	if mc_mesh:
		mc_mesh.set_layer_mask_value(1, false)
		mc_mesh.set_layer_mask_value(2, true)
	camera.set_cull_mask_value(2, false)

func _apply_third_person():
	spring_arm.spring_length = TP_SPRING_LENGTH
	spring_arm.position = TP_SPRING_POS
	camera.fov = 70
	weapon_holder.visible = false
	show_mc_for_camera()

func _apply_fps():
	spring_arm.spring_length = FPS_SPRING_LENGTH
	spring_arm.position = FPS_SPRING_POS
	camera.fov = 75
	weapon_holder.visible = true
	hide_mc_from_camera()

func set_fps_mode():
	is_fps_mode = true
	_apply_fps()
	play_idle()

func set_third_person():
	is_fps_mode = false
	is_reloading = false
	can_shoot = true
	if weapon_anim:
		weapon_anim.stop()
	_apply_third_person()

func play_idle():
	if weapon_anim and is_fps_mode and not is_reloading:
		weapon_anim.play("Scene")
		weapon_anim.seek(INSPECT_START)

func play_section(start: float, end: float):
	if weapon_anim == null:
		return
	weapon_anim.play("Scene")
	weapon_anim.seek(start)
	weapon_anim.speed_scale = 1.0
	var duration = end - start
	await get_tree().create_timer(duration).timeout

func _input(event):
	if is_dead:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
		camera_pitch = clamp(camera_pitch, -1.2, 1.0)
		spring_arm.rotation.x = camera_pitch

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_fps_mode:
				set_third_person()
			else:
				set_fps_mode()
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_shoot and is_fps_mode and not is_reloading:
			shoot()

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("reload") and is_fps_mode and not is_reloading:
		reload()

func shoot():
	if ammo <= 0:
		ammo_label.text = "AMMO: EMPTY! Press R to reload"
		return
	can_shoot = false
	ammo -= 1
	update_hud()
	if gun_sound:
		gun_sound.play(0.1)
	if weapon_anim:
		weapon_anim.play("Scene")
		weapon_anim.seek(SHOOT_START)
	if ray.is_colliding():
		var hit = ray.get_collider()
		if hit != null:
			if hit.is_in_group("zombie"):
				hit.take_damage(25)
			elif hit.get_parent() != null and hit.get_parent().is_in_group("zombie"):
				hit.get_parent().take_damage(25)
	await get_tree().create_timer(SHOOT_END - SHOOT_START).timeout
	can_shoot = true
	play_idle()

func reload():
	if ammo == 15:
		return
	is_reloading = true
	can_shoot = false
	if weapon_anim:
		weapon_anim.play("Scene")
		weapon_anim.seek(RELOAD_START)
	await get_tree().create_timer(RELOAD_END - RELOAD_START).timeout
	ammo = 15
	is_reloading = false
	can_shoot = true
	update_hud()
	play_idle()

func take_damage(amount):
	if is_dead:
		return
	health -= amount
	_flash_damage()
	_update_health_display()
	if health <= 0:
		health = 0
		_update_health_display()
		_show_game_over()

func _show_game_over():
	is_dead = true
	can_shoot = false
	is_reloading = false

	if tween:
		tween.kill()

	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	game_over_layer = CanvasLayer.new()
	game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_over_layer)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_layer.add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -220
	vbox.offset_right = 220
	vbox.offset_top = -150
	vbox.offset_bottom = 150
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	game_over_layer.add_child(vbox)

	var title = Label.new()
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.9, 0.05, 0.05))
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "The zombies got you."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(sub)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var btn = Button.new()
	btn.text = "▶  Play Again"
	btn.custom_minimum_size = Vector2(220, 58)
	btn.add_theme_font_size_override("font_size", 24)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn)

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _flash_damage():
	if damage_overlay == null:
		return
	if tween:
		tween.kill()
	damage_overlay.color = Color(1, 0, 0, 0.45)
	tween = create_tween()
	tween.tween_property(damage_overlay, "color", Color(1, 0, 0, 0.0), 0.6) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func update_hud():
	ammo_label.text = "AMMO: " + str(ammo)
	bread_label.text = "🍞".repeat(bread)
	_update_health_display()

func _update_health_display():
	if health_label == null:
		return
	health_label.text = "❤️ " + str(health) + " HP"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_label.add_theme_font_size_override("font_size", 22)
	var color: Color
	if health > 60:
		color = Color(0.2, 1.0, 0.2)
	elif health > 30:
		color = Color(1.0, 0.75, 0.0)
	else:
		color = Color(1.0, 0.15, 0.15)
	health_label.add_theme_color_override("font_color", color)

func _update_distance_display():
	if distance_label == null:
		return
	if mc_house == null:
		distance_label.text = "📡 Signal lost..."
		distance_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
		return

	var dist = global_position.distance_to(mc_house.global_position)

	var color: Color
	var hint: String

	if dist < 20.0:
		hint = "🔴 YOU'RE RIGHT THERE"
		color = Color(1.0, 0.1, 0.1)
	elif dist < 80.0:
		hint = "🟠 Very close"
		color = Color(1.0, 0.5, 0.0)
	elif dist < 100.0:
		hint = "🟡 Getting warmer"
		color = Color(1.0, 0.9, 0.0)
	elif dist < 130.0:
		hint = "🟢 Somewhere nearby"
		color = Color(0.3, 1.0, 0.3)
	else:
		hint = "🔵 Far away..."
		color = Color(0.4, 0.7, 1.0)

	distance_label.text = "%.1f m\n%s" % [dist, hint]
	distance_label.add_theme_color_override("font_color", color)

func _process(delta):
	if is_dead:
		return
	if is_fps_mode and weapon_holder:
		var sway = sin(Time.get_ticks_msec() * 0.001) * 0.002
		weapon_holder.position.y = sway
	_update_distance_display()

func _physics_process(delta):
	if is_dead:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

	mc_model.rotation.y = PI

	if run_anim_name == "":
		return

	if input != Vector2.ZERO and is_on_floor():
		if anim.current_animation != run_anim_name:
			anim.play(run_anim_name)
		anim.speed_scale = 0.7
		mc_model.position = Vector3(0, -1.0, 0)

		# Footsteps
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_timer = FOOTSTEP_INTERVAL
			if footstep_player and not footstep_player.playing:
				footstep_player.play()
	else:
		if anim.is_playing():
			anim.stop()
		mc_model.position = Vector3(0, -1.0, 0)
		anim.speed_scale = 1.0

		# Stop footsteps
		footstep_timer = 0.0
		if footstep_player and footstep_player.playing:
			footstep_player.stop()
