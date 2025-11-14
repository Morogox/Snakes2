extends Node2D

@onready var snake = $"../SnakeHead"

@onready var eat = $Chomp
@onready var shoot = $Shoot
@onready var yelp = $Yelp
@onready var death = $Snake_Head_Death
@onready var s_miss = $Snake_Bullet_Miss
@onready var snake_hit = $Snake_Bullet_Hit # There's no reason that I wrote the full word "snake" instead of just "s"
@onready var s_deflect = $Snake_Bullet_Deflect
@onready var e_shoot = $Enemy_Shoot
@onready var charge = $Enemy_Charge
@onready var rage = $Enemy_Rage
@onready var e_miss = $Enemy_Bullet_Miss
@onready var e_hit = $Enemy_Bullet_Hit
@onready var segment_death = $Snake_Segment_Death
@onready var segment_heal = $Snake_Segment_Heal
@onready var boost = $Boost
@onready var LOVE = $Level_Up
@onready var hiss = $Hiss
@onready var explosion = $Explosion

var is_snake_dead = false

var reset_timer_stuff = 0.0
var is_timer_going = false
var segment_timer = false
var heal_timer = false
var combo_timer = false

func _ready():
	Handler.register(name.to_snake_case(), self)
	Handler.item_handler.apple_eaten.connect(_chomp) #Chomp sound effect
	Handler.snake_head.shooted.connect(_shooted) #Shoot sound effect
	Handler.snake_head.snake_has_a_critical_owie.connect(_yelp) # Upon death, before fade out
	Handler.snake_head.snake_after_not_surviving.connect(_no_head) # Upon death, now fading out
	Handler.game_master.tier_change.connect(_level_up)

func _process(delta: float) -> void: # for resetting incremental pitches, could be done way way better
	if reset_timer_stuff == 0.0:
		_reset_combo()
		reset_timer_stuff += 0.01
		is_timer_going = false
	elif reset_timer_stuff > 1.0:
		reset_timer_stuff = -0.01
	if is_timer_going:
		reset_timer_stuff += 0.01
	
	if snake.is_boosting and not is_snake_dead:
		if Input.is_action_just_pressed("ui_boost"): # NOTE: Edge case, going to 0 stamina, picking up food while still holding boost, this edge case needs to be acounted for but I don't have the time to think of the solution
			boost.play()
		if not snake.inf_stamina:
			boost.pitch_scale = (snake.stamina / snake.max_stamina) * 0.5 + 0.5
		else: boost.pitch_scale = 1.0
	else:
		boost.stop()

func _chomp(_score: int, _loc: Vector2):
	eat.play()
	is_timer_going = true

func _shooted():
	shoot.play()

func _s_miss(go_to: Vector2):
	s_miss.global_position = go_to
	s_miss.play()

func _snake_hit(go_to: Vector2):
	snake_hit.global_position = go_to
	snake_hit.play()
	reset_timer_stuff = 0.01
	if not is_timer_going:
		is_timer_going = true
		combo_timer = true
	snake_hit.pitch_scale += 0.05
	if snake_hit.pitch_scale > 1.8:
		snake_hit.pitch_scale = 1.8

func _s_deflect(go_to: Vector2):
	s_deflect.global_position = go_to
	s_deflect.play()

func _e_shoot(go_to: Vector2):
	e_shoot.global_position = go_to
	e_shoot.play()

func _e_charge(go_to: Vector2):
	charge.global_position = go_to
	charge.play()

func _e_rage(go_to: Vector2):
	rage.global_position = go_to
	rage.play()

func _e_miss(go_to: Vector2):
	e_miss.global_position = go_to
	e_miss.play()

func _e_hit(go_to: Vector2):
	e_hit.global_position = go_to
	e_hit.play()

func _yelp():
	yelp.play()
	is_snake_dead = true

func _no_head():
	death.play()

func _segment_death(go_to: Vector2):
	segment_death.global_position = go_to
	segment_death.play()
	if is_snake_dead == true:
		segment_death.volume_db -= 0.2
		segment_death.pitch_scale -= 0.02
		if segment_death.pitch_scale < 0.2:
			segment_death.pitch_scale = 0.2
		if segment_death.volume_db < 0.0:
			segment_death.volume_db = 0.0
	else:
		if not is_timer_going:
			is_timer_going = true
			segment_timer = true
		segment_death.volume_db -= 0.2
		segment_death.pitch_scale -= 0.02
		if segment_death.pitch_scale < 0.2:
			segment_death.pitch_scale = 0.2

func _segment_heal(go_to: Vector2):
	segment_heal.global_position = go_to
	segment_heal.play()
	reset_timer_stuff = 0.01
	if not is_timer_going:
		is_timer_going = true
		heal_timer = true
	segment_heal.pitch_scale += 0.05
	if segment_heal.pitch_scale > 10.0:
		segment_heal.pitch_scale = 10.0

func _reset_combo():
	# Segment death
	# Segments healing
	# and Successful shots all have combos
	if segment_timer:
		segment_death.volume_db = 5.0
		segment_death.pitch_scale = 1.0
		segment_timer = false
	if heal_timer:
		#segment_heal.volume_db = 10.0
		segment_heal.pitch_scale = 2.0
		segment_timer = false
	if combo_timer:
		#snake_hit.volume_db = 10.0
		snake_hit.pitch_scale = 0.8
		combo_timer = false

func _level_up(tier: int):
	LOVE.pitch_scale = 1.3 + (tier * -0.05)
	LOVE.play()
	if LOVE.pitch_scale < 0.8:
			LOVE.pitch_scale = 0.8

func _explode(go_to: Vector2):
	explosion.global_position = go_to
	explosion.play()

func _hiss(go_to: Vector2):
	hiss.global_position = go_to
	hiss.play()
