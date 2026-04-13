extends CharacterBody3D

const SPEED = 5.5
const GRAVITY = 9.8
const MOUSE_SENSITIVITY = 0.002

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var ray = $SpringArm3D/Camera3D/RayCast3D
@onready var ammo_label = $CanvasLayer/HUD/AmmoLabel
@onready var bread_label = $CanvasLayer/HUD/BreadLabel
@onready var mc_model = $mcrunning
@onready var anim = mc_model.find_child("AnimationPlayer", true, false)

var ammo = 15
var bread = 2
var health = 100
var can_shoot = true
var camera_pitch = 0.0
var run_anim_name = ""

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_hud()
	spring_arm.spring_length = 3.0
	spring_arm.position = Vector3(0.5, 1.5, 0)
	camera.fov = 70
	mc_model.position.y = -1.0
	var anims = anim.get_animation_list()
	if anims.size() > 0:
		run_anim_name = anims[0]

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
		camera_pitch = clamp(camera_pitch, -1.2, 1.0)
		spring_arm.rotation.x = camera_pitch

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_shoot:
			shoot()

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("reload"):
		reload()

func shoot():
	if ammo <= 0:
		ammo_label.text = "AMMO: EMPTY! Press R to reload"
		return

	can_shoot = false
	ammo -= 1
	update_hud()

	if ray.is_colliding():
		var hit = ray.get_collider()
		if hit.is_in_group("zombie"):
			hit.take_damage(25)
		elif hit.get_parent().is_in_group("zombie"):
			hit.get_parent().take_damage(25)

	await get_tree().create_timer(0.3).timeout
	can_shoot = true

func reload():
	if ammo == 15:
		return
	ammo = 15
	update_hud()
	print("Reloaded!")

func take_damage(amount):
	health -= amount
	if health <= 0:
		print("You died!")

func update_hud():
	ammo_label.text = "AMMO: " + str(ammo)
	bread_label.text = "🍞".repeat(bread)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

	# Always face the same direction as the camera
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
