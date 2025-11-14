extends Node2D

signal apple_eaten(points: int, loc: Vector2)

var item_map = {
	"apple_1": {
		"type": "apple",
		"value": 1,
		"sprite": "red_apple",
		"points": 10,
		"respawnable": true
	},
	"apple_2": {
		"type": "apple",
		"value": 2,
		"sprite": "gold_apple",
		"points": 20,
		"respawnable": false
	}
}
func _ready():
	Handler.register(name.to_snake_case(), self)

func spawn_item_random(item_key: String):
	var item_data = item_map.get(item_key, null)
	if not item_data:
		push_error("Item key '%s' not found in item_map" % item_key)
		return

	if Handler.grid_manager.find_cell(0).x < 0:
		return # no free cell available
	
	
	# Pick a free cell
	var cell_pos: Vector2
	while true:
		var cell_x = randi_range(0, Handler.grid_manager.grid_width - 1)
		var cell_y = randi_range(0, Handler.grid_manager.grid_height - 1)
		cell_pos = Vector2(cell_x, cell_y)
		if Handler.grid_manager.grid_map[cell_x][cell_y] == 0:
			break

	# Instantiate the item
	var item = preload("res://Scenes/item.tscn").instantiate()
	
	#add_child(item)
	call_deferred("add_child", item)
	
	# Setup item using the item map
	item.setup(item_key, item_data)
	item.connect("destroyed", _item_destroyed)
	
	# Mark the cell and set position
	Handler.grid_manager.set_cell(cell_pos, 2)
	item.position = Handler.grid_manager.grid_origin + cell_pos * Handler.grid_manager.GRID_SIZE + Handler.grid_manager.CELL_OFFSET

func spawn_item_on_grid(item_key: String, location: Vector2):
	var item_data = item_map.get(item_key, null)
	if not item_data:
		push_error("Item key '%s' not found in item_map" % item_key)
		return
		
	# Convert pixel position to grid cell
	var start_cell = Handler.grid_manager.pixel_to_cell(location)
	
	# BFS to find nearest free cell
	var visited = {}
	var queue = [start_cell]
	var found_cell: Vector2 = Vector2(-1, -1)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var key = str(current.x) + "," + str(current.y)
		if key in visited:
			continue
		visited[key] = true

		# Check bounds
		if current.x < 0 or current.x >= Handler.grid_manager.grid_width:
			continue
		if current.y < 0 or current.y >= Handler.grid_manager.grid_height:
			continue
		
		# Check if cell is free
		if Handler.grid_manager.get_cell(Vector2(current.x, current.y)) == 0:
			found_cell = current
			break
			
			# Add neighbors to the queue
		var neighbors = [
			Vector2(current.x + 1, current.y),
			Vector2(current.x - 1, current.y),
			Vector2(current.x, current.y + 1),
			Vector2(current.x, current.y - 1)
		]
		queue += neighbors

	# No free cell found
	if found_cell.x < 0:
		return
	
	# Instantiate the item
	var item = preload("res://Scenes/item.tscn").instantiate()
	call_deferred("add_child", item)
	item.setup(item_key, item_data)
	item.connect("destroyed", _item_destroyed)

	# Mark the cell and set position
	Handler.grid_manager.set_cell(found_cell, 2)
	item.position = Handler.grid_manager.grid_origin + found_cell * Handler.grid_manager.GRID_SIZE + Handler.grid_manager.CELL_OFFSET

func _item_destroyed(key: String, loc: Vector2):
	var data = item_map.get(key, null)
	match data.get("type"):
		"apple":
			emit_signal("apple_eaten", data.get("points"), loc)

	if data.get("respawnable"):
		(spawn_item_random(key))
