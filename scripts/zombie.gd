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

# Resolved animation names
var anim_idle = ""
var anim_scratch = ""
var anim_run = ""
var anim_attack = ""
var anim_die = ""

@onready var anim = $"Zombie Model/AnimationPlayer2"
@onready var growl_player = $GrowlPlayer

func _find_anim(keyword: String) -> String:
	for anim_name in anim.get_animation_list():
		if anim_name.to_lower().contains(keyword.to_lower()):
			return anim_name
	return ""

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
	growl_cooldown = randf_range(0.0, GROWL_COOLDOWN_MAX)

	if anim:
		print("Available animations:")
		for anim_name in anim.get_animation_list():
			print("  - " + anim_name)

		# Auto-resolve animation names by keyword
		anim_idle    = _find_anim("Zombie Idle")
		anim_scratch = _find_anim("Zombie Scratch")
		anim_run     = _find_anim("Zombie Running")
		anim_attack  = _find_anim("Zombie Attack")
		anim_die     = _find_anim("Zombie Dying")

		print("Resolved anims: idle=%s scratch=%s run=%s attack=%s die=%s" % [
			anim_idle, anim_scratch, anim_run, anim_attack, anim_die
		])

		# Set loop modes
		if anim_run != "":
			anim.get_animation(anim_run).loop_mode = Animation.LOOP_LINEAR
		if anim_scratch != "":
			anim.get_animation(anim_scratch).loop_mode = Animation.LOOP_LINEAR
		if anim_idle != "":
			anim.get_animation(anim_idle).loop_mode = Animation.LOOP_LINEAR
		if anim_attack != "":
			anim.get_animation(anim_attack).loop_mode = Animation.LOOP_NONE

		if anim_idle != "":
			anim.play(anim_idle)

func _physics_process(_delta):
	if dead:
		return

	var distance_to_player = player.global_position.distance_to(global_position) if player else INF

	_handle_growl(_delta, distance_to_player)

	if attack_cooldown > 0.0:
		attack_cooldown -= _delta

	if is_attacking:
		if not anim.is_playing() or anim.current_animation != anim_attack:
			is_attacking = false

	if anim and not is_attacking:
		if distance_to_player <= ATTACK_RANGE and attack_cooldown <= 0.0:
			is_attacking = true
			attack_cooldown = ATTACK_COOLDOWN
			if anim_attack != "":
				anim.play(anim_attack)
			_deal_attack_damage()
		elif distance_to_player <= DETECTION_RANGE:
			idle_playing = false
			idle_cooldown = randf_range(3.0, 10.0)
			if anim_run != "":
				if not anim.is_playing() or anim.current_animation != anim_run:
					anim.play(anim_run)
				elif anim.current_animation_position >= 0.9:
					anim.seek(0.0)
		else:
			if idle_playing:
				if anim.current_animation_position >= 0.9:
					idle_playing = false
					idle_cooldown = randf_range(5.0, 12.0)
					if anim_idle != "":
						anim.play(anim_idle)
			else:
				idle_cooldown -= _delta
				if idle_cooldown <= 0.0:
					idle_playing = true
					if anim_scratch != "":
						anim.play(anim_scratch)
				elif anim.current_animation != anim_idle:
					if anim_idle != "":
						anim.play(anim_idle)

	if not is_on_floor():
		velocity.y -= GRAVITY * _delta

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
		player.take_damage(1)

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
