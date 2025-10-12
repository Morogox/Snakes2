extends Node2D
var grid_manager_ref: Node  # reference to GridManager
@export var enemy_scene: PackedScene
@onready var snake_head_ref = Node


func setup(grid_manager_node: Node, snake_head_node: Node):
	grid_manager_ref = grid_manager_node
	snake_head_ref = snake_head_node

func spawn_enemy(amount: int = 1):
	for i in range(amount):
		var enemy = enemy_scene.instantiate()
		var spawn_ok = false
		var x = 0.0
		var y = 0.0
		while not spawn_ok:
			x = randf_range(grid_manager_ref.left, grid_manager_ref.right)
			y = randf_range(grid_manager_ref.top, grid_manager_ref.bottom)
			var spawn_pos = Vector2(x, y)
			# check if spawn_pos overlaps snake head
			if snake_head_ref.position.distance_to(spawn_pos) > grid_manager_ref.GRID_SIZE * 2:
				spawn_ok = true
		
		enemy.setup(grid_manager_ref)
		enemy.position = Vector2(x, y)
		add_child(enemy)
