extends Node2D
@export var spawner_scene: PackedScene

signal enemy_killed(points: int)

func _ready():
	Handler.register(name.to_snake_case(), self)

func _spawn_enemy(amount: int = 1, delay_variation: float = 0.0):
	for i in range(amount):
		var spawner = spawner_scene.instantiate()
		var spawn_ok = false
		var x = 0.0
		var y = 0.0
		while not spawn_ok:
			x = randf_range(Handler.grid_manager.left, Handler.grid_manager.right)
			y = randf_range(Handler.grid_manager.top, Handler.grid_manager.bottom)
			var spawn_pos = Vector2(x, y)
			# check if spawn_pos overlaps snake head
			if Handler.snake_head.position.distance_to(spawn_pos) > Handler.grid_manager.GRID_SIZE * 2:
				spawn_ok = true
		spawner.position = Vector2(x, y)
		add_child(spawner)
		
		var delay_time = randf_range(0.0, delay_variation)
		await get_tree().create_timer(delay_time).timeout

func generate_wave(min_time, max_time):
	var amt = randi_range(min_time, max_time)
	_spawn_enemy(amt, 1)

func _enemy_killed(score: int, loc: Vector2):
	emit_signal("enemy_killed", score, loc)
	
