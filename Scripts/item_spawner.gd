extends Node2D
var grid_manager_ref: Node  # reference to GridManager
@export var apple_scene: PackedScene



func setup(grid_manager_node: Node, snake_head_node: Node):
	grid_manager_ref = grid_manager_node

func spawn_apple(amount: int = 1):
	for i in range(amount):
		if grid_manager_ref.find_cell(0):
			#print("NO FREE SPACE FOUND, EXITING")
			return

		var apple = apple_scene.instantiate()
		add_child(apple)
		var cell_pos: Vector2

		while true:
			var cell_x = randi_range(0, grid_manager_ref.grid_width - 1)
			var cell_y = randi_range(0, grid_manager_ref.grid_height - 1)
			cell_pos = Vector2(cell_x, cell_y)
			#print("CHECKING FOR FREE SPOT FOR APPLE AT ", cell_pos)
			if grid_manager_ref.grid_map[cell_x][cell_y] == 0:
				break  # Found a free cell

		grid_manager_ref.set_cell(cell_pos, 2)
		var pos = grid_manager_ref.grid_origin + cell_pos * grid_manager_ref.GRID_SIZE + grid_manager_ref.CELL_OFFSET
		apple.position = pos
