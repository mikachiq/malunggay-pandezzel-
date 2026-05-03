extends CharacterBody3D

const MAX_SPEED = 5.5
const MIN_SPEED = 4.5
const GRAVITY = 50.0
const MAX_HEALTH = 1
const DETECTION_RANGE = 30.0
const ATTACK_RANGE = 1.8
const ATTACK_COOLDOWN = 1.5
const GROWL_RANGE = 10.0
const GROWL_COOLDOWN_MAX = 9.0
const IDLE_COOLDOWN = 5.0

var speed = MAX_SPEED
var health = MAX_HEALTH
var dead = false
var player = null
var attack_cooldown = 0.0
var is_attacking = false
var is_idle_playing = false
var idle_cooldown = 0.0
var anim_run = ""
var anim_attack = ""
var anim_die = ""
var anim_idles = []

@onready var anim = $"Zombie Model/AnimationPlayer2"
@onready var growl_player = $GrowlPlayer

func _find_anim(keyword: String) -> String:
	for anim_name in anim.get_animation_list():
		if anim_name.to_lower().contains(keyword.to_lower()):
			return anim_name
	return ""

func _find_all_anims(keyword: String) -> Array:
	var results = []
	for anim_name in anim.get_animation_list():
		if anim_name.to_lower().contains(keyword.to_lower()):
			results.append(anim_name)
	return results

func _ready():
	add_to_group("zombie")
	collision_layer = 2
	collision_mask = 0xFFFFFFFF
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	$"Zombie Model".rotation_degrees.y = 180

	speed = randf_range(MIN_SPEED, MAX_SPEED)

	if anim:
		anim_run = _find_anim("Running")
		anim_attack = _find_anim("Attack")
		anim_die = _find_anim("Dying")

		var thriller_anims = _find_all_anims("Thriller")
		var scratch_anims = _find_all_anims("Scratch Idle")
		var turn_anims = _find_all_anims("Turn")
		anim_idles = thriller_anims + scratch_anims + turn_anims

		if anim_run != "":
			var run_anim = anim.get_animation(anim_run)
			if run_anim:
				run_anim.loop_mode = Animation.LOOP_LINEAR
			anim.play(anim_run)

		if anim_attack != "":
			anim.get_animation(anim_attack).loop_mode = Animation.LOOP_NONE

		for idle_name in anim_idles:
			var idle_anim = anim.get_animation(idle_name)
			if idle_anim:
				idle_anim.loop_mode = Animation.LOOP_NONE

	idle_cooldown = randf_range(0.0, IDLE_COOLDOWN)

func _physics_process(_delta):
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	_handle_growl(_delta, distance_to_player)

	if attack_cooldown > 0.0:
		attack_cooldown -= _delta

	if is_attacking:
		if not anim.is_playing() or anim.current_animation != anim_attack:
			is_attacking = false
			if anim_run != "":
				anim.play(anim_run)

	if not is_attacking:
		if distance_to_player <= ATTACK_RANGE and attack_cooldown <= 0.0:
			is_attacking = true
			attack_cooldown = ATTACK_COOLDOWN
			if anim_attack != "":
				anim.play(anim_attack)
			_deal_attack_damage()

	if not is_on_floor():
		velocity.y -= GRAVITY * _delta
	else:
		velocity.y = 0.0

	if distance_to_player <= DETECTION_RANGE and distance_to_player > ATTACK_RANGE:
		is_idle_playing = false
		idle_cooldown = IDLE_COOLDOWN

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
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		look_at(look_target, Vector3.UP)

		if not is_attacking:
			if not anim.is_playing() or anim.current_animation != anim_run:
				anim.play(anim_run)
			elif anim.current_animation_position >= 0.9:
				anim.seek(0.0)

	elif distance_to_player <= ATTACK_RANGE:
		velocity.x = 0
		velocity.z = 0
		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		look_at(look_target, Vector3.UP)

	else:
		velocity.x = 0
		velocity.z = 0
		_handle_idle(_delta)

	move_and_slide()

func _handle_idle(_delta):
	if anim_idles.is_empty():
		return

	if is_idle_playing:
		if not anim.is_playing():
			is_idle_playing = false
			idle_cooldown = IDLE_COOLDOWN
	else:
		idle_cooldown -= _delta
		if idle_cooldown <= 0.0:
			var picked = anim_idles[randi() % anim_idles.size()]
			anim.play(picked)
			is_idle_playing = true

func _handle_growl(_delta, distance_to_player):
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
		player.take_damage(3)

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	dead = true
	velocity = Vector3.ZERO
	if anim and anim_die != "":
		anim.play(anim_die)
	await get_tree().create_timer(2.0).timeout
	queue_free()
