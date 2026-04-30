extends CharacterBody3D
const SPEED = 3.0
const GRAVITY = 9.8
const MAX_HEALTH = 1
const DETECTION_RANGE = 25.0
const ATTACK_RANGE = 1.8
const ATTACK_COOLDOWN = 1.5
const GROWL_RANGE = 10.0
const GROWL_COOLDOWN_MIN = 4.0
const GROWL_COOLDOWN_MAX = 9.0

var health = MAX_HEALTH
var dead = false
var player = null
var idle_cooldown = 0.0
var idle_playing = false
var attack_cooldown = 0.0
var is_attacking = false
var growl_cooldown = 0.0

@onready var anim = $"Zombie Model/AnimationPlayer2"
@onready var growl_player = $GrowlPlayer

func _ready():
	add_to_group("zombie")
	collision_layer = 2
	collision_mask = 1
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	$"Zombie Model".rotation_degrees.y = 180
	$"Zombie Model/Skeleton3D".motion_scale = 0.01
	idle_cooldown = randf_range(3.0, 10.0)
	# Stagger each zombie's first growl so they don't all growl at once
	growl_cooldown = randf_range(0.0, GROWL_COOLDOWN_MAX)
	if anim:
		print("Available animations:")
		for anim_name in anim.get_animation_list():
			print("  - " + anim_name)
		var running_anim = anim.get_animation("Zombie Running/mixamo_com")
		if running_anim:
			running_anim.loop_mode = Animation.LOOP_LINEAR
		var idle_anim = anim.get_animation("Zombie Scratch Idle/mixamo_com")
		if idle_anim:
			idle_anim.loop_mode = Animation.LOOP_LINEAR
		var zombie_idle_anim = anim.get_animation("Zombie Idle/mixamo_com")
		if zombie_idle_anim:
			zombie_idle_anim.loop_mode = Animation.LOOP_LINEAR
		var attack_anim = anim.get_animation("Zombie Attack/mixamo_com")
		if attack_anim:
			attack_anim.loop_mode = Animation.LOOP_NONE
		anim.play("Zombie Idle/mixamo_com")

func _physics_process(delta):
	if dead:
		return

	var distance_to_player = player.global_position.distance_to(global_position) if player else INF

	_handle_growl(delta, distance_to_player)

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_attacking:
		if not anim.is_playing() or anim.current_animation != "Zombie Attack/mixamo_com":
			is_attacking = false

	if anim and not is_attacking:
		if distance_to_player <= ATTACK_RANGE and attack_cooldown <= 0.0:
			is_attacking = true
			attack_cooldown = ATTACK_COOLDOWN
			anim.play("Zombie Attack/mixamo_com")
			_deal_attack_damage()
		elif distance_to_player <= DETECTION_RANGE:
			idle_playing = false
			idle_cooldown = randf_range(3.0, 10.0)
			if not anim.is_playing() or anim.current_animation != "Zombie Running/mixamo_com":
				anim.play("Zombie Running/mixamo_com")
			elif anim.current_animation_position >= 0.9:
				anim.seek(0.0)
		else:
			if idle_playing:
				if anim.current_animation_position >= 0.9:
					idle_playing = false
					idle_cooldown = randf_range(5.0, 12.0)
					anim.play("Zombie Idle/mixamo_com")
			else:
				idle_cooldown -= delta
				if idle_cooldown <= 0.0:
					idle_playing = true
					anim.play("Zombie Scratch Idle/mixamo_com")
				elif anim.current_animation != "Zombie Idle/mixamo_com":
					anim.play("Zombie Idle/mixamo_com")

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if player != null:
		if distance_to_player <= DETECTION_RANGE and distance_to_player > ATTACK_RANGE:
			var dir = global_position.direction_to(player.global_position)
			dir.y = 0
			var separation = Vector3.ZERO
			for other in get_tree().get_nodes_in_group("zombie"):
				if other == self or other.dead:
					continue
				var dist = global_position.distance_to(other.global_position)
				if dist < 3.0 and dist > 0.01:
					var push = global_position.direction_to(other.global_position)
					push.y = 0
					separation -= push / dist
			dir = (dir + separation * 0.5).normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
			var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
			look_at(look_target, Vector3.UP)
		elif distance_to_player <= ATTACK_RANGE:
			velocity.x = 0
			velocity.z = 0
			var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
			look_at(look_target, Vector3.UP)
		else:
			velocity.x = 0
			velocity.z = 0

	move_and_slide()

func _handle_growl(delta, distance_to_player):
	if growl_player == null:
		return
	if distance_to_player <= GROWL_RANGE:
		if not growl_player.playing:
			growl_player.play()
	else:
		if growl_player.playing:
			growl_player.stop()

func _deal_attack_damage():
	if player and player.has_method("take_damage"):
		player.take_damage(1)

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	dead = true
	velocity = Vector3.ZERO
	if anim:
		anim.play("Zombie Dying/mixamo_com")
	await get_tree().create_timer(2.0).timeout
	queue_free()
