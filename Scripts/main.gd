extends Node2D
# Grid settings
const GRID_SIZE = 32
const GRID_COLOR = Color(0.7, 0.7, 0.7, 0.5)  # light gray, semi-transparent

# Optional: grid size in cells
var grid_width = 50
var grid_height = 50

@onready var top_wall = $WorldBoundaries/Top
@onready var bottom_wall = $WorldBoundaries/Down
@onready var left_wall = $WorldBoundaries/Left
@onready var right_wall = $WorldBoundaries/Right
@onready var camera = $Camera2D

var left 
var right 
var top
var bottom 

var start_pos = Vector2.ZERO



func _ready():
	# Compute the playable area inside the walls
	left = left_wall.position.x + left_wall.shape.distance
	right = right_wall.position.x - right_wall.shape.distance
	top = top_wall.position.y + top_wall.shape.distance
	bottom = bottom_wall.position.y - bottom_wall.shape.distance
	

	# Calculate grid size
	grid_width = int((right - left) / GRID_SIZE)
	grid_height = int((bottom - top) / GRID_SIZE)

	# Center the camera
	camera.position = Vector2((left + right)/2, (top + bottom)/2)

	start_pos = Vector2(left, top)  # inside edge of the walls
	queue_redraw()

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
