extends CharacterBody3D

const SPEED = 3.0
const GRAVITY = 9.8
const MAX_HEALTH = 100

var health = MAX_HEALTH
var dead = false
var player = null

@onready var health_label = $HealthLabel
@onready var anim = $"Zombie Model/AnimationPlayer2"

func _ready():
	add_to_group("zombie")
	collision_layer = 2
	collision_mask = 1
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	update_health_bar()
	$"Zombie Model".rotation_degrees.y = 180
	$"Zombie Model/Skeleton3D".motion_scale = 0.01
	
	if anim:
		print("Available animations:")
		for anim_name in anim.get_animation_list():
			print("  - " + anim_name)
		
		var running_anim = anim.get_animation("Zombie Running/mixamo_com")
		if running_anim:
			running_anim.loop_mode = Animation.LOOP_LINEAR
			print("Playing: Zombie Running/mixamo_com")
			anim.play("Zombie Running/mixamo_com")
		else:
			print("ERROR: Animation not found!")

func _physics_process(delta):
	if dead:
		return
	
	if anim:
		if not anim.is_playing() or anim.current_animation != "Zombie Running/mixamo_com":
			anim.play("Zombie Running/mixamo_com")
		else:
			if anim.current_animation_position >= 0.9:
				anim.seek(0.0)
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if player != null:
		var dir = global_position.direction_to(player.global_position)
		dir.y = 0
		
		# Push away from nearby zombies so they don't stack
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
	
	move_and_slide()

func update_health_bar():
	health_label.text = "HP: " + str(health)
	if health > 50:
		health_label.modulate = Color.GREEN
	else:
		health_label.modulate = Color.RED

func take_damage(amount):
	health -= amount
	update_health_bar()
	if health <= 0:
		die()

func die():
	dead = true
	velocity = Vector3.ZERO
	health_label.visible = false
	if anim:
		anim.play("Zombie Dying/mixamo_com")
	await get_tree().create_timer(2.0).timeout
	queue_free()
