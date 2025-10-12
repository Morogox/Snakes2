extends CharacterBody2D
@export var speed := 200.0
@export var min_wait_time := 0.5
@export var max_wait_time := 2.0
@export var hp := 1

var target_position: Vector2
enum State_enum { IDLE, MOVING, DEAD }
var state: State_enum = State_enum.IDLE
var direction := Vector2.ZERO

@onready var main := get_tree().root.get_node("main")
@onready var snake := get_tree().get_root().get_node("main/SnakeHead")
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

var spam_mode := false
var spam_mode_enabled := false

@onready var shader_mat: ShaderMaterial = sprite.material

var friction := 2000 # pixels/sec^2
func _ready():
	randomize()

	# Make the sprite's material unique for this instance
	# sprite.material = sprite.material.duplicate()

	_change_sprite(0)
	sprite.play("default")
	_transition_to(State_enum.IDLE)

func _process(delta: float):
	if state != State_enum.DEAD:
		var player_pos = snake.global_position
		sprite.flip_h = player_pos.x >= position.x

func _change_sprite(type):
	sprite.play("Bird"+str(type))
	sprite.speed_scale = type * 3 + 1 # If in spam mode, animation is super fast, if not, normal speed

func _physics_process(delta):
	if state != State_enum.DEAD:
		match state:
			State_enum.MOVING:
				_process_moving(delta)
			State_enum.IDLE:
				velocity = Vector2.ZERO  # stay still
		
		
		shoot_timer += delta
		if shoot_timer >= shoot_delay:
			# handle spam-mode chance
			if spam_mode_enabled:
				if spam_mode:
					if randi_range(1, 5) == 1:  # 20% chance to stop spamming
						_exit_spam_mode()
				else:
					if randi_range(1, 20) == 20:  # 5% chance to enter
						_enter_spam_mode()
			_shoot()
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
			velocity = velocity.bounce(collision_info.get_normal()) * 0.7

func _process_moving(delta):
	var to_target = target_position - position
	var distance = to_target.length()

	if distance < 20.0:
		#position = target_position
		_transition_to(State_enum.IDLE)
	else:
		velocity = to_target.normalized() * speed
		move_and_slide()

func _transition_to(new_state: State_enum):
	state = new_state
	match state:
		State_enum.MOVING:
			_pick_new_target()
		State_enum.IDLE:
			if spam_mode:
				_shoot()
				timer.start(0.05)
			else:
				var wait_time = randf_range(min_wait_time, max_wait_time)
				timer.start(wait_time)
		State_enum.DEAD:
			timer.stop()  # immediately stops the timer
			sprite.play("dead")
			collision_mask |= 1 << 1  # add layer 2 (boundaries) to mask
			collision_mask &= ~(1 << 0)  # remove layer 1 (snake)
			collision_layer &= ~(1 << 4) # remove layer 5 (enemies)
			z_index = 0
			await get_tree().create_timer(2).timeout
			await flash_disappear(4, 0.1) 
			queue_free()
func _on_timer_timeout() -> void:
	_transition_to(State_enum.MOVING)

func _pick_new_target():
	if spam_mode:
		var dx = 50 * (randi_range(0, 1) * 2 - 1)  
		var dy = 50 * (randi_range(0, 1) * 2 - 1)
		target_position = position + Vector2(dx, dy)
	else:
		var x = clamp(randf_range(main.left, main.right), main.left, main.right)
		var y = snake.target_pixel_pos.y
		target_position = Vector2(x, y)

func _shoot():
	#show muzzle flash
	#flash.show()
	var point_at_snake = global_position.direction_to(snake.global_position)
	#flash.rotation = point_at_snake.angle() #+ randf_range(-0.1, 0.1)  # optional: small random tilt
	## hide it again shortly
	#get_tree().create_timer(flash_time).timeout.connect(flash.hide)
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation =  point_at_snake.angle()
	bullet.damage = damage  # pass damage to bullet
	bullet.b_speed = bullet_speed  # pass damage to bullet
	get_tree().get_root().get_node("main").add_child(bullet)

func _enter_spam_mode():
	spam_mode = true
	shoot_delay = 0.05
	_change_sprite(1)

func _exit_spam_mode():
	spam_mode = false
	shoot_delay = randf_range(1, 4)
	_change_sprite(0)

func flash_whiteout(count: int, interval: float) -> void:
	for i in count:
		shader_mat.set("shader_param/flash", true)
		await get_tree().create_timer(interval).timeout
		shader_mat.set("shader_param/flash", false)
		await get_tree().create_timer(interval).timeout

func take_hit(dmg: int, kb_dir: Vector2 = Vector2.ZERO, force: float = 0.0 ):
	hp -= dmg
	if hp <= 0:
		_transition_to(State_enum.DEAD)
		var angle_variation := deg_to_rad(90.0)  # max +- 90 degrees variation
		var random_angle := randf_range(-angle_variation, angle_variation)
		velocity = kb_dir.normalized() * force
	await flash_whiteout(4, 0.05)

func flash_disappear(count: int, interval: float) -> void:
	for i in range(count):
		visible = false
		await get_tree().create_timer(interval).timeout
		visible = true
		await get_tree().create_timer(interval).timeout
