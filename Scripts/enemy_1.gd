extends CharacterBody2D
@export var speed := 200.0
@export var min_wait_time := 0.5
@export var max_wait_time := 2.0
@export var HP := 1.0

var target_position: Vector2
enum State_enum { IDLE, MOVING, SHOOT }
var state: State_enum = State_enum.IDLE
var direction := Vector2.ZERO

@onready var main := get_tree().root.get_node("main")
@onready var snake := get_tree().get_root().get_node("main/SnakeHead")
@onready var timer := $Timer
@onready var sprite = $AnimatedSprite2D

@onready var flash = $sMuzzleFlash
var flash_time := 0.05   # how long to show the flash (seconds)
@export var bullet_scene: PackedScene
@onready var muzzle = $Muzzle   # Marker2D
@export var damage = 1.0
@export var bullet_speed = 250

var spam_mode := false

func _ready():
	randomize()
	sprite.play("default")
	
	randomize()
	_transition_to(State_enum.IDLE)

func _process(delta: float):
	var player_pos = snake.global_position
	if player_pos.x < position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true


func _physics_process(delta):
	match state:
		State_enum.MOVING:
			_process_moving(delta)
		State_enum.IDLE:
			velocity = Vector2.ZERO  # stay still
		State_enum.SHOOT:
			velocity = Vector2.ZERO # movement stuff

func _process_moving(delta):
	var to_target = target_position - position
	var distance = to_target.length()

	if distance < 20.0:
		#position = target_position
		if true: # randf_range(0,2) == 2
			_transition_to(State_enum.SHOOT)
		else:
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
			var wait_time = 0.05
			if not spam_mode:
				wait_time = randf_range(min_wait_time, max_wait_time)
			#print(wait_time)
			timer.start(wait_time)
			#print("Idle for:", wait_time)
		State_enum.SHOOT:
			_shoot()
			var wait_time = 0.05
			if not spam_mode:
				wait_time = randf_range(min_wait_time, max_wait_time)
			timer.start(wait_time) # Bullet Stuff

func _on_timer_timeout() -> void:
	_transition_to(State_enum.MOVING)

func _pick_new_target():
	if not spam_mode:
		# Pick a random point within Main's play area
		var x = randf_range(main.left, main.right)
		if x < main.left:
			x = main.left
		if x > main.right:
			x = main.right
		var y = snake.target_pixel_pos.y
		#var snake_direction = snake.direction # Trying to make the bird head more in the direction it's already going, but then again, what if the snake isn't going up or down
		#if snake_direction == UP:
			#y += 3
		#else:
			#y -= 3
		target_position = Vector2(x, y)
	else:
		var x = position.x
		var y = position.y
		spam_mode = true
		target_position = Vector2(x + 50 * randi_range(-1, 1), y + 50 * randi_range(-1, 1))
		# ...if someone could make 0 not possible I'd be happy
	if randi_range(1, 10) == 10: # 10% chance to enter spam mode, move a tiny bit and fire again
		spam_mode = true
	else:
		if spam_mode and randi_range(1,4) != 1: # 25ish% chance to leave once entered
			spam_mode = true
		else:
			spam_mode = false
	
#func _on_area_entered(area: Area2D) -> void: # failed attempt to make the enemy die
	#if area.is_in_group("SnakeBullet"):
		#print("Confirmed Kill")
		#area.queue_free()
		#main.spawn_enemy() # respawn a new one

func _shoot():
	#show muzzle flash
	flash.show()
	var point_at_snake = global_position.direction_to(snake.global_position)
	flash.rotation = point_at_snake.angle() #+ randf_range(-0.1, 0.1)  # optional: small random tilt
	# hide it again shortly
	get_tree().create_timer(flash_time).timeout.connect(flash.hide)
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation =  point_at_snake.angle()
	bullet.damage = damage  # pass damage to bullet
	bullet.b_speed = bullet_speed  # pass damage to bullet
	get_tree().current_scene.add_child(bullet)
