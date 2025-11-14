extends "res://Enemies/Scripts/enemy.gd"
var rage := false
@export var rage_chance = 0.3
@export var rage_shot_count = 5
@export var rage_bullet_scene = PackedScene
var regular_bullet_speed : float
var regular_bullet_scene : PackedScene
var rage_shot_counter = 0
@export var rage_transform_time := 3.0
@onready var smoke = $smoke
@onready var rage_transform_timer = $RageTransformTimer
var tick_timer := 0.0
var tick_time := 5.0   # every 5 seconds

func _ready():
	super()

func _process(delta: float):
	super(delta)
	if not rage and state != state_enum.DEAD:
		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = tick_time   
			if randf() < rage_chance:
				_enter_rage()

func _enter_rage():
	smoke.toggle_emission(true)
	rage = true
	speed = 400.0
	_transition_to(state_enum.MOVING)
	timer.stop()
	shoot_timer = 0
	shoot_delay = INF
	emit_signal("raging", global_position)
	await _play_rage_anim(rage_transform_time)
	sprite_default_name = "rage_default"
	sprite_shooting_name = "rage_shooting"


	shoot_delay_base = 0.1
	shoot_delay_variation = 0.3
	shoot_delay = shoot_delay_base
	
	sprite.speed_scale = 6.0
	angle_variation_degrees = 10.0
	
	regular_bullet_scene = bullet_scene
	regular_bullet_speed = bullet_speed 
	bullet_speed *= 1.5
	bullet_scene = rage_bullet_scene
	
	_change_sprite(sprite_default_name)
func _exit_rage():
	rage = false
	speed = 200.0
	
	shoot_timer = 0
	shoot_delay_base = 2.0
	shoot_delay_variation = 2.0
	shoot_delay = shoot_delay_base
	
	sprite_default_name = "default"
	sprite_shooting_name = "shooting"
	sprite.speed_scale = 1.8
	
	movement = true
	angle_variation_degrees = 0.0
	
	bullet_scene = regular_bullet_scene
	bullet_speed = regular_bullet_speed
	
	_transition_to(state_enum.IDLE)
	_change_sprite(sprite_default_name)
	smoke.toggle_emission(false)

func _play_rage_anim(time: float):
	movement = false
	_change_sprite("rage_transform")
	rage_transform_timer.start(time)
	await rage_transform_timer.timeout
	movement = true
	
func _shoot(dir = Handler.snake_head.global_position, amount := 1, fan_angle := 0.0):
	super()
	if rage:
		rage_shot_counter += 1
		_transition_to(state_enum.MOVING)
		angle_variation_degrees += 10
		if rage_shot_counter >= rage_shot_count:
			rage_shot_counter = 0
			_exit_rage()

func _transition_to(new_state: state_enum):
	super(new_state)
	match state:
		state_enum.DEAD:
			smoke.toggle_emission(false)
			rage_transform_timer.stop()
