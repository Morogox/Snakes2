extends CharacterBody2D
@export var speed := 200.0
@export var min_wait_time := 0.5
@export var max_wait_time := 2.0
@export var hp := 1

var target_position: Vector2
enum state_enum { IDLE, MOVING, DEAD}
var state: state_enum = state_enum.IDLE
var direction := Vector2.ZERO

@onready var timer := $Timer
@onready var sprite = $AnimatedSprite2D

@onready var muzzle_flash = $sMuzzleFlash
var muzzle_flash_time := 0.05   # how long to show the flash (seconds)
@export var bullet_scene: PackedScene
@onready var muzzle = $Muzzle   # Marker2D

@export var damage = 1.0
@export var bullet_speed = 250
@export var shoot_delay_base = 2.0
@export var shoot_delay_variation = 2.0
var shoot_delay = shoot_delay_base
var shoot_timer = 0

@onready var shader_mat: ShaderMaterial = sprite.material

var invulnerable = false

var friction := 2000 # pixels/sec^2

signal death(points: int, loc: Vector2)
signal drop_item_here(type: String, loc: Vector2)
signal charge(position: Vector2) # for sound
signal fire(position: Vector2) # for sound

@export var base_score = 50

@export var movement = true
var drop_item := true

@export var drops := {
	"apple_2": 0.1,   # 10% chance
}


var sprite_default_name := "default"
var sprite_shooting_name := "shooting"

@export var angle_variation_degrees := 0.0

@onready var feathers = $EnemyFeather
func _ready():
	randomize()
	_change_sprite(sprite_default_name)
	_transition_to(state_enum.MOVING)

func _process(delta: float):
	if state != state_enum.DEAD:
		var player_pos = Handler.snake_head.global_position
		sprite.flip_h = player_pos.x <= position.x

func _change_sprite(type):
	sprite.play(type)

func _physics_process(delta):
	if state != state_enum.DEAD:
		match state:
			state_enum.MOVING:
				_process_moving(delta)
			state_enum.IDLE:
				velocity = Vector2.ZERO  # stay still
		shoot_timer += delta
		if shoot_timer >= shoot_delay:
			_change_sprite(sprite_shooting_name)
			#emit_signal("fire", global_position)
			movement = false
			#_shoot()
			shoot_delay = randf_range(shoot_delay_base, shoot_delay_base + shoot_delay_variation)
			shoot_timer = 0.0
	# dead
	else:
		if velocity.length() <= (friction * delta):
			velocity = Vector2.ZERO
		else:
			velocity -= velocity.normalized() * (friction * delta)

		var collision_info = move_and_collide(velocity * delta)
		if collision_info:
			velocity = velocity.bounce(collision_info.get_normal()) * 0.4

func _process_moving(delta):
	if not movement:
		return
	var to_target = target_position - position
	var distance = to_target.length()

	if distance < 20.0:
		#position = target_position
		_transition_to(state_enum.IDLE)
	else:
		velocity = to_target.normalized() * speed
		move_and_slide()

func _transition_to(new_state: state_enum):
	state = new_state
	
	#To state
	match state:
		state_enum.MOVING:
			_pick_new_target()
		state_enum.IDLE:
			var wait_time = randf_range(min_wait_time, max_wait_time)
			timer.start(wait_time)
		state_enum.DEAD:
			timer.stop()  # immediately stops the timer
			sprite.play("dead")
			invulnerable = true
			collision_mask |= 1 << 1  # add layer 2 (boundaries) to mask
			collision_mask &= ~(1 << 0)  # remove layer 1 (snake)
			collision_layer &= ~(1 << 4) # remove layer 5 (enemies)
			sprite.z_index = -1
			emit_signal("death", base_score, position)
			feathers.toggle_emission(true)
			_check_drops()
			await get_tree().create_timer(2).timeout
			await flash_disappear(4, 0.1) 
			queue_free()

func _on_timer_timeout() -> void:
	_transition_to(state_enum.MOVING)

func _pick_new_target():
		var axes = ["x", "y"]
		var align_axis = axes[randi() % 2]
		target_position = Vector2(
			Handler.snake_head.target_pixel_pos.x if align_axis == "x" else randf_range(Handler.grid_manager.left + 50, Handler.grid_manager.right -50), 
			Handler.snake_head.target_pixel_pos.y if align_axis == "y" else randf_range(Handler.grid_manager.top + 50, Handler.grid_manager.bottom - 70))

func _shoot(dir = Handler.snake_head.global_position):
	# Spawn bullet
	dir = global_position.direction_to(dir)
	var spread = deg_to_rad(randf_range(-angle_variation_degrees, angle_variation_degrees))
	var final_angle = dir.angle() + spread
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation =  final_angle
	bullet.damage = damage  # pass damage to bullet
	bullet.b_speed = bullet_speed  # pass damage to bullet
	get_tree().get_root().get_node("main/Game/Bullets").add_child(bullet)
	bullet.e_miss.connect(Handler.sound_effect_handler._e_miss)
	bullet.e_hit.connect(Handler.sound_effect_handler._e_hit)

func flash_whiteout(count: int, interval: float) -> void:
	for i in count:
		shader_mat.set_shader_parameter("flash", true)
		await get_tree().create_timer(interval).timeout
		shader_mat.set_shader_parameter("flash", false)
		await get_tree().create_timer(interval).timeout

func flash_disappear(count: int, interval: float) -> void:
	for i in range(count):
		visible = false
		await get_tree().create_timer(interval).timeout
		visible = true
		await get_tree().create_timer(interval).timeout

func take_hit(dmg: int, kb_dir: Vector2 = Vector2.ZERO, force: float = 0.0):
	if not invulnerable:
		hp -= dmg
	if hp <= 0:
		_transition_to(state_enum.DEAD)
		var angle_variation := deg_to_rad(15.0)  # max +- 15 degrees variation
		var random_angle := randf_range(-angle_variation, angle_variation)
		velocity = kb_dir.normalized() * force
		velocity = velocity.rotated(random_angle)
	await flash_whiteout(4, 0.05)

func _check_drops():
	if not drop_item:
		return
	var result: Array = []
	for drop_name in drops.keys():
		if randf() < drops[drop_name]: # each chance is separate
			result.append(drop_name)
	for item in result:
		emit_signal("drop_item_here", item, position)


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == sprite_shooting_name:
		movement = true
		_change_sprite(sprite_default_name)


func _on_frame_changed() -> void:
	if sprite.frame == 10 and sprite.animation == sprite_shooting_name:
		emit_signal("fire", global_position)
		_shoot()
