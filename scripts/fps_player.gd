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

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var ray = $SpringArm3D/Camera3D/RayCast3D
@onready var ammo_label = $CanvasLayer/HUD/AmmoLabel
@onready var bread_label = $CanvasLayer/HUD/BreadLabel
@onready var mc_model = $mcrunning
@onready var anim = $mcrunning/AnimationPlayer
@onready var weapon_holder = $SpringArm3D/Camera3D/weaponholder
@onready var fpov = $SpringArm3D/Camera3D/weaponholder/FPOV
@onready var weapon_anim = $SpringArm3D/Camera3D/weaponholder/FPOV/AnimationPlayer
@onready var damage_overlay = $CanvasLayer/HUD/DamageOverlay

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

const TP_SPRING_LENGTH = 3.0
const TP_SPRING_POS = Vector3(0.5, 1.5, 0)
const FPS_SPRING_LENGTH = 0.0
const FPS_SPRING_POS = Vector3(0, 1, 0)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_hud()
	_apply_third_person()
	mc_model.position.y = -1.0
	# Get run animation name
	var anims = anim.get_animation_list()
	for a in anims:
		if "run" in a.to_lower() or "walk" in a.to_lower():
			run_anim_name = a
			break
	if run_anim_name == "" and anims.size() > 0:
		run_anim_name = anims[0]
	weapon_holder.visible = false
	# Store mesh reference for layer switching
	mc_mesh = mc_model.find_child("geometry_0", true, false)
	# Add light to weapon
	var light = OmniLight3D.new()
	light.light_energy = 2.0
	light.omni_range = 3.0
	light.position = Vector3(0, 0, -0.5)
	weapon_holder.add_child(light)
	# Safely get gun sound if node exists
	if has_node("SpringArm3D/Camera3D/weaponholder/GunShotSound"):
		gun_sound = $SpringArm3D/Camera3D/weaponholder/GunShotSound
		gun_sound.max_polyphony = 4
		gun_sound.bus = "Master"
	# Make sure overlay starts invisible
	if damage_overlay:
		damage_overlay.color = Color(1, 0, 0, 0.0)

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
	health -= amount
	_flash_damage()
	if health <= 0:
		print("You died!")

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

func _process(delta):
	if is_fps_mode and weapon_holder:
		var sway = sin(Time.get_ticks_msec() * 0.001) * 0.002
		weapon_holder.position.y = sway

func _physics_process(delta):
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

	if input != Vector2.ZERO:
		if anim.current_animation != run_anim_name:
			anim.play(run_anim_name)
		anim.speed_scale = 0.7
		mc_model.position = Vector3(0, -1.0, 0)
	else:
		if anim.is_playing():
			anim.stop()
		mc_model.position = Vector3(0, -1.0, 0)
		anim.speed_scale = 1.0
