extends Node2D
# Grid settings
const GRID_SIZE = 32
const CELL_OFFSET = Vector2(GRID_SIZE, GRID_SIZE) * 0.5
const GRID_COLOR = Color(0.7, 0.7, 0.7, 0.5)  # light gray, semi-transparent

@export var grid_dimensions = 15 

# Optional: grid size in cells
var grid_width
var grid_height

@onready var top_wall = $WorldBoundaries/Top
@onready var bottom_wall = $WorldBoundaries/Down
@onready var left_wall = $WorldBoundaries/Left
@onready var right_wall = $WorldBoundaries/Right
@onready var camera = $Camera2D

@onready var AppleScene = preload("res://Scenes/Apple.tscn")

var left 
var right 
var top
var bottom 

var grid_origin = Vector2.ZERO

# 2d array use to keep track of map state
# 0 = empty, 1 = snake, 2 = apple
var grid_map = []

func _ready():
	for wall in [top_wall, bottom_wall, left_wall, right_wall]:
		wall.shape.distance = grid_dimensions * -GRID_SIZE
	
	# Compute the playable area inside the walls
	left = left_wall.position.x + left_wall.shape.distance
	right = right_wall.position.x - right_wall.shape.distance
	top = top_wall.position.y + top_wall.shape.distance
	bottom = bottom_wall.position.y - bottom_wall.shape.distance
	

	# Calculate grid size
	grid_width = int((right - left) / GRID_SIZE)
	grid_height = int((bottom - top) / GRID_SIZE)

	# Initialize 2D grid array
	grid_map = []
	for x in range(grid_width):
		grid_map.append([])
		for y in range(grid_height):
			grid_map[x].append(0) 

	# Center the camera
	camera.position = Vector2((left + right)/2, (top + bottom)/2)

	grid_origin = Vector2(left, top)  # inside edge of the walls
	queue_redraw()
	
	randomize()  # seed RNG
	spawn_apple()

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

func spawn_apple():
	if !find_grid_value(0):
		print("NO FREE SPACE FOUND, EXITING")
		return

	var apple = AppleScene.instantiate()
	add_child(apple)
	var cell_pos: Vector2

	while true:
		var cell_x = randi_range(0, grid_width - 1)
		var cell_y = randi_range(0, grid_height - 1)
		cell_pos = Vector2(cell_x, cell_y)
		print("CHECKING FOR FREE SPOT AT ", cell_pos)
		if grid_map[cell_x][cell_y] == 0:
			break  # Found a free cell

	set_grid_cell_if_valid(cell_pos, 2)
	var pos = grid_origin + cell_pos * GRID_SIZE + CELL_OFFSET
	apple.position = pos

func set_grid_cell_if_valid(pos: Vector2, value: int):
	var x = int(pos.x)
	var y = int(pos.y)
	if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
		#print("SETTING POSITION AT", pos, value)
		grid_map[x][y] = value

func find_grid_value(value: int) -> bool:
	for row in grid_map:
		for v in row:
			if v == 0:
				return true
	return false

func print_grid_map():
	for y in range(grid_height):
		var row = ""
		for x in range(grid_width):
			match grid_map[x][y]:
				0: row += "."  # empty
				1: row += "S"  # snake
				2: row += "A"  # apple
			row += " "
		print(row)
	print("\n")
