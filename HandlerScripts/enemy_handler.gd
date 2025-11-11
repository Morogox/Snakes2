extends Node2D
@export var spawner_scene: PackedScene

signal enemy_killed(points: int)
var active_enemy_amt := 0
var enemy_types = {
	"basic": preload("res://Enemies/Scenes/enemy.tscn"),
	"rager": preload("res://Enemies/Scenes/enemy_rager.tscn")
}
func _ready():
	Handler.register(name.to_snake_case(), self)
	
func _spawn_enemy(type: String, amount: int = 1, delay_variation: float = 0.0, ):
	active_enemy_amt += amount
	var delay_time = randf_range(0.0, delay_variation)
	await get_tree().create_timer(delay_time).timeout
	for i in range(amount):
		var spawner = spawner_scene.instantiate()
		spawner.enemy_scene = enemy_types[type]
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
		
		

func generate_wave(spawn_q : Array[String]):
	for i in spawn_q:	
		_spawn_enemy(i, 1, 1.0)

func _enemy_killed(score: int, loc: Vector2):
	active_enemy_amt -= 1
	emit_signal("enemy_killed", score, loc)
	
