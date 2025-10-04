extends Area2D
@onready var main = get_parent()
@onready var GRID_SIZE = main.GRID_SIZE
@onready var CELL_OFFSET = main.CELL_OFFSET
var grid_origin = Vector2.ZERO

const SEGMENT_TEXTURE = preload("res://sprites/snakeSegment.png")
const SEGMENT_TURN_TEXTURE = preload("res://sprites/snakeSegmentTest.png")

@export var move_delay = 0.15  # Squares per frame

var snake_pos = Vector2.ZERO   # grid coordinates
var input_vector = Vector2.ZERO
var direction = Vector2.RIGHT   
var prev_pixel_pos = Vector2.ZERO
var target_pixel_pos = Vector2.ZERO

var inputs = {
	"ui_right": Vector2.RIGHT,
	"ui_left": Vector2.LEFT,
	"ui_up": Vector2.UP,
	"ui_down": Vector2.DOWN
}

const DIR_ROTATIONS = {
	Vector2.RIGHT: 0,
	Vector2.LEFT: PI,
	Vector2.UP: -PI/2,
	Vector2.DOWN: PI/2
}

var move_timer = move_delay
const MAX_QUEUE_SIZE = 3
var input_queue = []

#Snake segment stuff
@export var segment_scene: PackedScene
var segments = []
var pending_growth = 0
var move_history = []

@export var starting_segments = 1

func _init_position():
	# Set snake to the center of the grid
	snake_pos = Vector2(floor(main.grid_width / 2), floor(main.grid_height / 2))
	
	grid_origin = main.grid_origin
	target_pixel_pos = grid_origin + snake_pos * GRID_SIZE + CELL_OFFSET
	prev_pixel_pos = target_pixel_pos
	position = target_pixel_pos
	
	for s in segments:
		s.queue_free()
	segments.clear()
	move_history.clear()
		
	move_history.push_front(target_pixel_pos)

	for i in range(starting_segments):
		var seg = segment_scene.instantiate()
		main.add_child(seg)
		var seg_pos = target_pixel_pos - direction * GRID_SIZE * (i + 1)
		seg.position = seg_pos
		segments.append(seg)
		move_history.append(seg_pos)

func _ready():
	call_deferred("_init_position")

func _process(delta):
	move_timer += delta
	_handle_input()
	_update_head_rotation()
	# Move snake logic every move_delay
	if move_timer >= move_delay:
		move_timer = 0.0
		_move_snake()
	position = _lerp_position(prev_pixel_pos, target_pixel_pos)
	_update_segments(delta)

func _handle_input():
	for action in inputs.keys():
		if Input.is_action_just_pressed(action) and direction != -inputs[action]:
			_queue_direction(inputs[action])
			break

func _update_head_rotation():
	rotation = DIR_ROTATIONS.get(direction, 0)

func _update_segments(delta):
	for i in range(segments.size()):
		var segment = segments[i]
		var p1 = move_history[i+1]  # previous spot
		var p2 = move_history[i]    # target spot
		
		# Move segment
		segment.position = _lerp_position(p1, p2)
		segment.rotation = _get_rotation(p1, p2)
		
		# Update sprite for turning
		var sprite: Sprite2D = segment.get_node("Sprite2D")
		var sprite2: Sprite2D = segment.get_node("Sprite2D2")

		if _is_turning(i, p2, p1):
			sprite2.visible = true
			sprite2.position = Vector2(sprite.texture.get_size().x, 0).lerp(Vector2.ZERO, move_timer/move_delay)
		else:
			sprite2.visible = false
			sprite2.position.x = sprite.position.x + sprite.texture.get_size().x
		
		#sprite.texture = _get_segment_texture(i, p2, p1)

# Checks if a snake segment is currently turning.
# - Compares the segment's current direction (dir_current) to the direction of the segment ahead (dir_ahead).
# - For the first segment (index == 0), dir_ahead is calculated from the head's target position.
# - For other segments, dir_ahead is based on the position of the segment directly before it in move_history.
# - Returns true if the segment is turning (i.e., directions are different and non-zero), false otherwise.
# index: The segment's index in the segments array (0 = first segment).
# p2: The segment's target position on the move_history trail.
# p1: The segment's previous position on the move_history trail.
func _is_turning(index: int, p2: Vector2, p1: Vector2) -> bool:
	var dir_current = (p2 - p1).normalized()
	var dir_ahead: Vector2
	if index == 0:
		dir_ahead = (target_pixel_pos - move_history[0]).normalized()
	else:
		dir_ahead = (move_history[index - 1] - p2).normalized()
	var turning = dir_current != dir_ahead and dir_current != Vector2.ZERO and dir_ahead != Vector2.ZERO
	return true if turning else false

# Queues a new movement direction for the snake.
# - Only adds the new direction if it does not reverse the current direction or the last queued direction.
# - Ensures the new direction is different from the last direction to prevent redundant input.
# - Limits the input queue to a maximum size (MAX_QUEUE_SIZE) to prevent excessive buffering.
# new_dir: Vector2 representing the desired movement direction (e.g., Vector2.RIGHT, Vector2.UP).
func _queue_direction(new_dir):
	 # Only queue if it doesn’t reverse current direction or last queued
	var last_dir = input_queue[-1] if input_queue.size() > 0 else direction
	# Add inpiut to queue if its not reversing direction, the same diection, or exeedig input queue size
	if new_dir != -last_dir and new_dir != last_dir and input_queue.size() < MAX_QUEUE_SIZE:
		input_queue.append(new_dir)

# Adds a new segment to the snake's body.
# - Instantiates a new segment from the segment_scene PackedScene.
# - Adds it as a child of the main node.
# - Sets the segment's initial position to follow the last segment or the head if the snake has no segments.
# - Appends the new segment to the segments array.
# - Updates move_history to include the new segment's position for smooth movement interpolation.
# Note: Ensures the segment_scene is assigned before instantiation.
func _add_segment():
	if segment_scene == null:
		print("No segment scene assigned!")
		return
	var seg = segment_scene.instantiate()
	main.add_child(seg)
	seg.add_to_group("Segment")
	seg.position = prev_pixel_pos if segments.is_empty() else segments[-1].position
	segments.append(seg)
	var tail_pos = move_history.back()
	seg.position = tail_pos
	move_history.append(tail_pos)

func _grow(amount=1):
	pending_growth += amount

# Moves the snake one step on the grid.
# - Updates the move_history to track the head and segments positions.
# - Updates the head's grid position (snake_pos) based on the next queued direction.
# - Computes the new pixel position for smooth interpolation (target_pixel_pos).
# - Updates the grid map: marks the head cell as occupied, clears the tail cell if not growing.
# - Adds a new segment if the snake is currently growing.
# Note: Uses move_history, grid_origin, and pending_growth. Prints the grid map for debugging.
func _move_snake():
	move_history.push_front(target_pixel_pos)
	move_history.resize(segments.size() + 1)
	
	prev_pixel_pos = target_pixel_pos
	if input_queue.size() > 0:
		direction = input_queue.pop_front()

	snake_pos += direction
	target_pixel_pos = grid_origin + snake_pos * GRID_SIZE + CELL_OFFSET

	_update_grid_map()
	#main.print_grid_map()
	
	if pending_growth > 0:
		_add_segment()
		pending_growth -= 1

# Updates the grid_map for the snake
# Marks the head cell as occupied, clears the tail cell if not growing
func _update_grid_map():
	main.set_grid_cell_if_valid(snake_pos, 1)  # mark head
	if pending_growth == 0 and segments.size() > 0:
		var tail_cell = _pixel_to_cell(move_history[-1])
		main.set_grid_cell_if_valid(tail_cell, 0)

# Converts a world pixel position to grid cell coordinates
# pos = pixel position
# Returns a Vector2 containing the grid cell indices
func _pixel_to_cell(pos: Vector2) -> Vector2:
	return Vector2(int((pos.x - grid_origin.x)/GRID_SIZE), int((pos.y - grid_origin.y)/GRID_SIZE))

# Linear interpolation between two points based on current move progress
# p1 = starting position, p2 = target position
# Returns the interpolated position for smooth movement
func _lerp_position(p1: Vector2, p2: Vector2) -> Vector2:
	var t = move_timer / move_delay
	return p1.lerp(p2, t)

# Determine which texture a segment should use
# Uses the segment index, current position, and previous position
# Returns SEGMENT_TURN_TEXTURE if turning, otherwise SEGMENT_TEXTURE
func _get_rotation(p1: Vector2, p2: Vector2) -> float:
	var dir = p2 - p1
	return atan2(dir.y, dir.x)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Boundaries"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Apple"):
		print("Snake ate apple!")
		area.queue_free() # remove apple
		main.spawn_apple() # respawn a new one
		_grow(1) # grow snake by 1
	elif area.is_in_group("Segment") or area.is_in_group("Birds"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		
		
		
		
		
		
		
		
		
		
		
		
		
# Determines which texture a snake segment should use based on whether it is turning.
## - Computes the current movement direction of the segment (dir_current).
## - Computes the direction of the segment ahead (dir_ahead), or the head for the first segment.
## - Checks if the segment is turning by comparing dir_current and dir_ahead.
## - Returns SEGMENT_TURN_TEXTURE if turning, otherwise SEGMENT_TEXTURE.
## index: The segment's index in the segments array (0 = first segment).
## p2: The segment's target position on the move_history trail.
## p1: The segment's previous position on the move_history trail.
#func _get_segment_texture(index: int, p2: Vector2, p1: Vector2) -> Texture2D:
	#var dir_current = (p2 - p1).normalized()
	#var dir_ahead: Vector2
	#if index == 0:
		#dir_ahead = (target_pixel_pos - move_history[0]).normalized()
	#else:
		#dir_ahead = (move_history[index - 1] - p2).normalized()
	#var turning = dir_current != dir_ahead and dir_current != Vector2.ZERO and dir_ahead != Vector2.ZERO
	#return SEGMENT_TURN_TEXTURE if turning else SEGMENT_TEXTURE
	#
	##print((move_history[0] - move_history[1]).normalized())
		##print("Segment ", i, " turning: ", turning, dir_current, dir_ahead)
		##print("----------------------------------------------------------------------------------")
