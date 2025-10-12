extends Node2D
# Grid settings
const GRID_SIZE = 32
const CELL_OFFSET = Vector2(GRID_SIZE, GRID_SIZE) * 0.5
const GRID_COLOR = Color(0.7, 0.7, 0.7, 0.5)  # light gray, semi-transparent

@export var grid_dimensions = 5

# Grid state
var grid_width: int
var grid_height: int
var grid_map: Array = []

var left: float
var right: float
var top: float
var bottom: float

var left_wall: Node2D
var right_wall: Node2D
var top_wall: Node2D
var bottom_wall: Node2D

var grid_origin = Vector2.ZERO

func _ready():
	pass

func setup(top: Node2D, bottom: Node2D, left: Node2D, right: Node2D):
	top_wall = top
	bottom_wall = bottom
	left_wall = left
	right_wall = right
	_init_bounds()
	_init_grid()
	queue_redraw()

func _init_bounds():
	for wall in [top_wall, bottom_wall, left_wall, right_wall]:
		wall.shape.distance = grid_dimensions * -GRID_SIZE
	
	# Compute the playable area inside the walls
	left = left_wall.position.x + left_wall.shape.distance
	right = right_wall.position.x - right_wall.shape.distance
	top = top_wall.position.y + top_wall.shape.distance
	bottom = bottom_wall.position.y - bottom_wall.shape.distance
	
	grid_origin = Vector2(left, top)
	# Calculate grid size
	grid_width = int((right - left) / GRID_SIZE)
	grid_height = int((bottom - top) / GRID_SIZE)
	
func _init_grid():
	grid_map.clear()
	for x in range(grid_width):
		grid_map.append([])
		for y in range(grid_height):
			grid_map[x].append(0)  # 0 = empty

# -----------------------------
# Grid query / update functions
# -----------------------------
func set_cell(pos: Vector2, value: int):
	var x = int(pos.x)
	var y = int(pos.y)
	if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
		grid_map[x][y] = value

func get_cell(pos: Vector2) -> int:
	var x = int(pos.x)
	var y = int(pos.y)
	if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
		return grid_map[x][y]
	return -1  # invalid

func find_cell(value: int) -> Vector2:
	for x in range(grid_width):
		for y in range(grid_height):
			if grid_map[x][y] == 0:
				return Vector2(x, y)
	return Vector2(-1, -1)  # no empty cells found

# debugging
func _draw():
	var start_pos = Vector2(left, top)
	for x in range(grid_width + 1):
		var start = start_pos + Vector2(x * GRID_SIZE, 0)
		var end = start_pos + Vector2(x * GRID_SIZE, grid_height * GRID_SIZE)
		draw_line(start, end, GRID_COLOR, 1)

	for y in range(grid_height + 1):
		var start = start_pos + Vector2(0, y * GRID_SIZE)
		var end = start_pos + Vector2(grid_width * GRID_SIZE, y * GRID_SIZE)
		draw_line(start, end, GRID_COLOR, 1)

func print_grid_map():
	for y in range(grid_height):
		var row = ""
		for x in range(grid_width):
			match grid_map[x][y]:
				0: row += "."  # empty
				1: row += "S"  # snake
				2: row += "A"  # apple
				3: row += "B"  # bird
			row += " "
		print(row)
	print("\n")
