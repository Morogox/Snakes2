extends Node2D

@export var diffculty_level := 1

@export var enemy_wave_amt := Vector2(1, 4)
@export var enemy_wave_time := Vector2(8.0, 15.0)
var wave_timer := 0.0
var next_wave_time := 0.0

@export var enemy_variation := Vector2(0.0, 0.0)

func _ready():
	Handler.register(name.to_snake_case(), self)
	_reset_wave_timer()
	

func _process(delta):
	wave_timer += delta

	# Time to spawn a wave
	if wave_timer >= next_wave_time:
		_spawn_enemy_wave()
		_reset_wave_timer()

func _spawn_enemy_wave() -> void:
	if Handler.enemy_handler == null:
		push_warning("Enemy handler not set!")
		return

	Handler.enemy_handler.generate_wave(int(enemy_wave_amt.x), int(enemy_wave_amt.y))

func _reset_wave_timer() -> void:
	wave_timer = 0.0
	next_wave_time = randf_range(enemy_wave_time.x, enemy_wave_time.y)
