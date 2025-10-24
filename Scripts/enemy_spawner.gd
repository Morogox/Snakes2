extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_time := 4.0       # how long the indicator last
@export var deploy_time := 0.5     # how long till the enemy finish spawning
@export var fall_height := 50.0     # how high the enemy starts from
@export var fade_in_speed := 2.0

enum state_enum {SPAWNING, DEPLOYING}
var state: state_enum = state_enum.SPAWNING

@onready var shadow = $spawning_indicator
@onready var dummy = $enemy_sprite

var timer := 0.0
var duration := 0.0


func _ready():
	# Start transparent + offset
	dummy.modulate.a = 0.0
	dummy.position.y = -fall_height
	shadow.scale = Vector2(0.5, 0.5)
	shadow.modulate.a = 0.0
	_transition_to(state_enum.SPAWNING)
	z_index = 99

func _process(delta):
	timer += delta
	var t = clamp(timer / duration, 0.0, 1.0)
	match state:
		state_enum.SPAWNING:
			# Shadow grows & darkens
			shadow.scale = Vector2.ONE * lerp(0.5, 1.0, t)
			shadow.modulate.a = lerp(0.0, 0.5, t)
			
			if timer >= duration:
				_transition_to(state_enum.DEPLOYING)
		state_enum.DEPLOYING:
			var eased_t = ease(t, 0.2)
			dummy.position.y = lerp(-fall_height, 0.0, eased_t)
			dummy.modulate.a = lerp(0.0, 1.0, t)
			
			# When time’s up: spawn real enemy
			if timer >= duration:
				_spawn_enemy()

func _spawn_enemy():
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = global_position
		Handler.enemy_handler.add_child(enemy)
		
		enemy.death.connect(Handler.enemy_handler._enemy_killed)
		enemy.drop_item_here.connect(Handler.item_handler.spawn_item_on_grid)
	queue_free()

func _transition_to(new_state: state_enum):
	state = new_state
	timer = 0.0
	match new_state:
		state_enum.SPAWNING:
			duration = spawn_time
		state_enum.DEPLOYING:
			duration = deploy_time
