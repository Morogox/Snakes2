extends "res://Enemies/Scripts/enemy.gd"
var dodging = false;
@export var dodge_cd := 5.0
@export var dodge_cd_timer := dodge_cd
@export var dodge_distance = Vector2(80,150)
@export var dodge_speed =  600.0
@export var dodge_threshold = 70.0

@onready var exclamation = $EnemyExclamation

var base_speed : float
func _ready():
	super()
	base_speed = speed
func _process(delta):
	super(delta)
	dodge_cd_timer += delta
	if is_in_player_los(global_position, dodge_threshold) and dodge_cd_timer >= dodge_cd:
		if not dodging and state != state_enum.DEAD:
			dodge(Handler.snake_head.direction.normalized())

func is_in_player_los(enemy_pos: Vector2, danger_threshold: float) -> bool:
	# Player info
	var player_pos = Handler.snake_head.global_position
	var player_dir = Handler.snake_head.direction.normalized()

	# Cardinal directions only: make sure vector is exactly along one axis
	if abs(player_dir.x) > 0:
		player_dir.y = 0
	else:
		player_dir.x = 0

	# Compute vector from player to enemy
	var to_enemy = enemy_pos - player_pos

	# Project the vector onto the player direction
	var projected_length = to_enemy.dot(player_dir)

	# If projected_length < 0, enemy is behind the player
	if projected_length < 0:
		return false

	# Compute perpendicular distance from enemy to the LOS line
	var perpendicular_vector = to_enemy - player_dir * projected_length
	var perpendicular_distance = perpendicular_vector.length()

	# If perpendicular distance is less than threshold, enemy is in danger
	return perpendicular_distance <= danger_threshold
	
func dodge(los: Vector2):
	dodging = true
	dodge_cd_timer = 0.0
	shoot_timer = 0
	movement = true
	speed = dodge_speed
	timer.paused = true
	_change_sprite("dodging")
	exclamation.toggle_emission(true)
	sprite.speed_scale = 4.0
	
	
	var dir = los.normalized()
	var side =  1 if randf() < 0.5 else -1
	var dodge_dir = dir.rotated(side * PI / 2)
	var angle_offset = randf_range(-PI/12, PI/12)  # ±15 degrees
	dodge_dir = dodge_dir.rotated(angle_offset)
	var distance = randf_range(dodge_distance.x, dodge_distance.y)
	target_position = global_position + dodge_dir * distance
	target_position.x = clamp(target_position.x, Handler.grid_manager.left, Handler.grid_manager.right)
	target_position.y = clamp(target_position.y, Handler.grid_manager.top, Handler.grid_manager.bottom)
	state = state_enum.MOVING

func _process_moving(delta):
	if not movement:
		return
	var to_target = target_position - position
	var distance = to_target.length()

	if distance < 20.0:
		if dodging:
			dodging = false
			speed = base_speed
			timer.paused = false
			sprite.speed_scale = 1.8
			_change_sprite(sprite_default_name)
		_transition_to(state_enum.IDLE)
	else:
		velocity = to_target.normalized() * speed
		move_and_slide()
		

func predict_intercept(shooter_pos: Vector2, target_pos: Vector2, target_vel: Vector2, projectile_speed: float) -> Vector2:
	var to_target = target_pos - shooter_pos
	var a = target_vel.length_squared() - projectile_speed * projectile_speed
	var b = 2 * to_target.dot(target_vel)
	var c = to_target.length_squared()
	
	var discriminant = b*b - 4*a*c
	
	if discriminant < 0 or abs(a) < 0.001:
		# No solution, just aim at current position
		return target_pos
	
	var t1 = (-b + sqrt(discriminant)) / (2*a)
	var t2 = (-b - sqrt(discriminant)) / (2*a)
	var t = min(t1, t2)
	if t < 0:
		t = max(t1, t2)
	if t < 0:
		print("no fucking way")
		return target_pos  # target is moving away too fast
	
	return target_pos + target_vel * t

func _shoot(dir = global_position.direction_to(Handler.snake_head.global_position)):
	var snake_vel = Handler.snake_head.get_predicted_velocity()
	var adjusted_target = predict_intercept(muzzle.global_position, Handler.snake_head.global_position, snake_vel, bullet_speed)
	print("The elite is firing")
	print("Snake velocity: ", snake_vel)
	print("Moment of record: ", dir)
	print("Aiming at ", global_position.direction_to(adjusted_target))
	super(adjusted_target)
