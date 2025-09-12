extends Node2D
# Grid settings
const GRID_SIZE = 32
const GRID_COLOR = Color(0.7, 0.7, 0.7, 0.5)  # light gray, semi-transparent

# Optional: grid size in cells
const GRID_WIDTH = 50
const GRID_HEIGHT = 50

func _ready():
	queue_redraw()

func _draw():
	# Draw vertical lines
	for x in range(GRID_WIDTH + 1):
		var start = Vector2(x * GRID_SIZE, 0)
		var end = Vector2(x * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)
		draw_line(start, end, GRID_COLOR, 1)
	# Draw horizontal lines
	for y in range(GRID_HEIGHT + 1):
		var start = Vector2(0, y * GRID_SIZE)
		var end = Vector2(GRID_WIDTH * GRID_SIZE, y * GRID_SIZE)
		draw_line(start, end, GRID_COLOR, 1)
