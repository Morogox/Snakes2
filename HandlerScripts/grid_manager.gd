extends Node2D
# Grid settings
const GRID_SIZE = 32
const CELL_OFFSET = Vector2(GRID_SIZE, GRID_SIZE) * 0.5
const GRID_COLOR = Color(0.7, 0.7, 0.7, 0.5)  # light gray, semi-transparent

@export var grid_dimensions = 5

@onready var tilemap = get_node("/root/main/Game/TileMapLayer")
var tile_layer = 3
const TILES = {
	"top_wall_top": Vector2i(3, 1),
	"top_wall_bot": Vector2i(3, 2),
	"bottom_wall_top": Vector2i(2, 7),
	"bottom_wall_bot": Vector2i(2, 8),
	"side_wall": Vector2i(2, 2),
	"top_left_corner_floor": Vector2i(3, 3),
	"top_right_corner_floor": Vector2i(6, 3),
	"bottom_right_corner_floor": Vector2i(6,6),
	"bottom_left_corner_floor": Vector2i(3,6),
	"wall_left_edges": [Vector2i(3, 4),Vector2i(3, 5),Vector2i(3, 6)],
	"wall_right_edges": [Vector2i(6, 4),Vector2i(6, 5)],
	"wall_top_edges": [Vector2i(4, 3),Vector2i(5, 3)],
	"floors":[Vector2i(4, 4),Vector2i(5, 4), Vector2i(4, 5),Vector2i(5, 5),Vector2i(4, 6),Vector2i(5, 6)]
	# Add more as needed
}


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
	Handler.register(name.to_snake_case(), self)

func setup(top_w: Node2D, bottom_w: Node2D, left_w: Node2D, right_w: Node2D):
	top_wall = top_w
	bottom_wall = bottom_w
	left_wall = left_w
	right_wall = right_w
	_init_bounds()
	_init_grid()
	tilemap.scale = Vector2(2, 2)
	_populate_tilemap()
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
			if grid_map[x][y] == value:
				return Vector2(x, y)
	return Vector2(-1, -1)  # no empty cells found

# debugging
#func _draw():
	#var start_pos = Vector2(left, top)
	#for x in range(grid_width + 1):
		#var start = start_pos + Vector2(x * GRID_SIZE, 0)
		#var end = start_pos + Vector2(x * GRID_SIZE, grid_height * GRID_SIZE)
		#draw_line(start, end, GRID_COLOR, 1)
#
	#for y in range(grid_height + 1):
		#var start = start_pos + Vector2(0, y * GRID_SIZE)
		#var end = start_pos + Vector2(grid_width * GRID_SIZE, y * GRID_SIZE)
		#draw_line(start, end, GRID_COLOR, 1)

# Converts a world pixel position to grid cell coordinates
# pos = pixel position
# Returns a Vector2 containing the grid cell indices
func pixel_to_cell(pos: Vector2) -> Vector2:
	return Vector2(int((pos.x - grid_origin.x)/GRID_SIZE), int((pos.y - grid_origin.y)/GRID_SIZE))

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


func _populate_tilemap():
	# Clear any existing tiles
	tilemap.clear()
	tilemap.position = grid_origin
	_place_walls(tilemap, tile_layer)
	_place_floors(tilemap, tile_layer)

func _place_floors(tilemap: TileMapLayer, layer: int):
	tilemap.set_cell(Vector2i(0,0), layer, TILES["top_left_corner_floor"])
	tilemap.set_cell(Vector2i(grid_width - 1,0), layer, TILES["top_right_corner_floor"])
	tilemap.set_cell(Vector2i(grid_width - 1,grid_height -1), layer, TILES["bottom_right_corner_floor"])
	tilemap.set_cell(Vector2i(0,grid_height -1), layer, TILES["bottom_left_corner_floor"])
	
	for y in range(1, grid_height -1):
		tilemap.set_cell(Vector2i(0, y), layer, TILES["wall_left_edges"].get(randi()%3))
		tilemap.set_cell(Vector2i(grid_width -1, y), layer, TILES["wall_right_edges"].get(randi()%2))
	
	for x in range(1, grid_width -1):
		tilemap.set_cell(Vector2i(x, 0), layer, TILES["wall_top_edges"].get(randi()%2))
		
	for i in range(1, grid_width-1):
		for j in range(1, grid_height):
			tilemap.set_cell(Vector2i(i,j), layer, TILES["floors"].get(randi()%6))

func _place_walls(tilemap: TileMapLayer, layer: int):
	for x in range(-1, grid_width +1):
		tilemap.set_cell(Vector2i(x, -1), layer, TILES["top_wall_bot"])
		tilemap.set_cell(Vector2i(x, -2), layer, TILES["top_wall_top"])
		tilemap.set_cell(Vector2i(x, grid_height), layer, TILES["bottom_wall_top"])
		tilemap.set_cell(Vector2i(x, grid_height + 1), layer, TILES["bottom_wall_bot"])
	for y in range (-1, grid_height):
		tilemap.set_cell(Vector2i(-1, y), layer, TILES["side_wall"])
		tilemap.set_cell(Vector2i(grid_width, y), layer, TILES["side_wall"])
	
	
