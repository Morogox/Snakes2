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
@onready var BirdScene = preload("res://Scenes/birds.tscn")

var left 
var right 
var top
var bottom 

var grid_origin = Vector2.ZERO

# 2d array use to keep track of map state
# 0 = empty, 1 = snake, 2 = apple, 3 = bird
var grid_map = []
@export var check_depth: int = 2 # Determines how much leniency there is for spawncamp prevention, keep whole & >0, 2 is a good amount

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

	# Protect the snake by making its spawn in the array at initialization, unsure if it clears after ((I think the tail takes care of it))
	var snake_spawn
	snake_spawn = Vector2(floor(grid_width / 2), floor(grid_height / 2))
	set_grid_cell_if_valid(snake_spawn, 1)

	# Center the camera
	camera.position = Vector2((left + right)/2, (top + bottom)/2)

	grid_origin = Vector2(left, top)  # inside edge of the walls
	queue_redraw()
	
	randomize()  # seed RNG
	spawn_apple()
	#for x in range(0,30): # I just made it spawn 30 birds for now
		#spawn_bird() 
	print_grid_map() # For debugging purposes

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
		print("CHECKING FOR FREE SPOT FOR APPLE AT ", cell_pos)
		if grid_map[cell_x][cell_y] == 0:
			break  # Found a free cell

	set_grid_cell_if_valid(cell_pos, 2)
	var pos = grid_origin + cell_pos * GRID_SIZE + CELL_OFFSET
	apple.position = pos

func spawn_bird():
	# Copies the code for spawning an apple... but for a bird
	if !find_grid_value(0):
		print("NO FREE SPACE FOUND, EXITING")
		return

	var bird = BirdScene.instantiate()
	add_child(bird)
	var cell_pos: Vector2

	while true:
		var cell_x = randi_range(0, grid_width - 1)
		var cell_y = randi_range(0, grid_height - 1)
		cell_pos = Vector2(cell_x, cell_y)
		print("CHECKING FOR FREE SPOT FOR BIRD AT ", cell_pos)
		if grid_map[cell_x][cell_y] == 0: # Found a free cell
			if anti_spawncamp(cell_x, cell_y) == true: # But is it near the snake?
				break  # It's free and far from snek

	set_grid_cell_if_valid(cell_pos, 3) # 3 should be bird I think
	var pos = grid_origin + cell_pos * GRID_SIZE + CELL_OFFSET
	bird.position = pos

func anti_spawncamp(cell_x, cell_y): # Because you don't want a bird right in front of your face immediately and neither do we
	var center_pos: Vector2
	center_pos = Vector2(cell_x, cell_y) # This actually is useless, maybe not for debugging though
	var z: int = check_depth # z is easier to write than check_depth
	var row: int = -z
	var col: int = -z
	while true:
		if grid_map[cell_x + row][cell_y + col] == 1: # SHOULD MEAN IF IT'S A SNAKE
			break # Not a good spot
		row += 1
		if row == z + 1: # At the end of a row
			row = -z
			col += 1
		if cell_x + row == 30:
			# For some reason, the array of grid_map doesn't like going over 30
			# I'm guessing it's because it's trying to reach outside the grid
			# but outside the grid doesn't exist...
			# Welp, our grid is a square so if it reaches 30 then it should be far from the snake anyway
			# ...unless it's just that grid_map[x][y] == 1 to check for a snake isn't the right format
			row = -z
			col += 1
		if cell_y + col == 30:
			# Same deal as the paragraph above, though if it's the last column it's fine to return true
			return true
		if col == z + 1: # If all columns clear, great!
			return true # Good spot
	
	return false # We broke, it's not a good spot, report back

func set_grid_cell_if_valid(pos: Vector2, value: int):
	var x = int(pos.x)
	var y = int(pos.y)
	if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
		#print("SETTING POSITION AT", pos, value)
		grid_map[x][y] = value

func find_grid_value(value: int) -> bool:
	for row in grid_map:
		for v in row:
			if v == value:
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
				3: row += "B"  # bird
			row += " "
		print(row)
	print("\n")
