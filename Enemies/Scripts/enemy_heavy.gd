extends "res://Enemies/Scripts/enemy.gd"
@export var shield_scene : PackedScene
var shield : StaticBody2D
@onready var shield_pivot = $ShieldPivot
@onready var helmet_particle = $EnemyHeavyHelmet

@export var shield_distance = 15.0  # How far from enemy center
@export var rotation_speed = 1.0    # Radians per second
var shield_angle = 0.0
func _ready():
	super()
	spawn_shield()

func spawn_shield(dir = Handler.snake_head.global_position):
	dir = global_position.direction_to(dir)
	var s = shield_scene.instantiate()
	shield = s
	shield_pivot.add_child(s)
	
	# Point shield in the direction
	shield_pivot.rotation = dir.angle()
	
	# Start at enemy center
	shield_pivot.position = Vector2.ZERO
	
	# Tween to final position
	var target_pos = dir * shield_distance
	var tween = create_tween()
	tween.tween_property(shield, "position", Vector2(shield_distance, 0), 0.2).from(Vector2.ZERO)
	# Optional: add easing for style
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	

func _process(delta):
	super(delta)
	if shield:
		# Get direction to player
		var dir_to_player = global_position.direction_to(Handler.snake_head.global_position)
		var target_angle = dir_to_player.angle()
		var angle_diff = angle_difference(shield_pivot.rotation, target_angle)
		
		var rotation_step = sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)
		shield_pivot.rotation += rotation_step

func take_hit(dmg: int, kb_dir: Vector2 = Vector2.ZERO, force: float = 0.0):
	super(dmg, kb_dir, force)
	if hp <= (hp + dmg) * 0.5 and not hp <= 0:
		helmet_fall_off()
	elif hp <= 0:
		shield.destroy()

func helmet_fall_off():
	helmet_particle.toggle_emission(true)
	sprite_default_name = "default_unmasked"
	sprite_shooting_name = "shooting_unmasked"
