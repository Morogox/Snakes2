extends Area2D
@onready var main := get_tree().root.get_node("main")
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

@export var starting_segments = 3


@export var bullet_scene: PackedScene 
@onready var muzzle = $Muzzle   # Marker2D
@export var damage = 100
@export var bullet_speed = 10000
var target_angle = null
var cooldown := 0.1
var timer := 0.0

@onready var flash = $sMuzzleFlash

var dead := false

var flash_time := 0.05   # how long to show the flash (seconds)

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

	_grow(starting_segments)

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
	timer = max(timer - delta, 0.0)

func _handle_input():
	for action in inputs.keys():
		if Input.is_action_just_pressed(action) and direction != -inputs[action]:
			_queue_direction(inputs[action])
			break

func _update_head_rotation():
	rotation = DIR_ROTATIONS.get(direction, 0)

func _update_segments(delta):
	for i in range(segments.size()):
		if is_instance_valid(segments[i]):
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
	#seg.position = prev_pixel_pos if segments.is_empty() else segments[-1].position
	segments.append(seg)
	var tail_pos = move_history.back()
	seg.position = tail_pos
	move_history.append(tail_pos)

func _remove_segment():
	var tail_segment = segments[-1]
	var tail_cell = _pixel_to_cell(tail_segment.position)
	main.set_grid_cell_if_valid(tail_cell, 0)
	
	tail_segment.queue_free()
	segments.remove_at(segments.size() - 1)
	move_history.remove_at(move_history.size() - 1)
	_update_grid_map()

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
	# compute new head cell
	var next_pos = snake_pos + direction

	# self-collision check using grid map
	if main.get_grid_cell_if_valid(next_pos) == 1:
		_game_over()
		return

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
	if pending_growth == 0 :
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
	if body.is_in_group("Boundaries") or body.is_in_group("Enemies"):
		_game_over()
	

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Apple"):
		area.queue_free() # remove apple
		main.spawn_apple() # respawn a new one
		_grow(1) # grow snake by 1
	if area.is_in_group("EnemyBullet"):
		_game_over()


func _input(event):
	if Input.is_action_pressed("ui_fire"):
		if segments.size() > 0:
			_shoot()
			_remove_segment()
	if not Input.is_action_pressed("ui_anti_zoomies"):
		if Input.is_action_pressed("ui_zoomies"):
			move_delay = 0.05
		else:
			move_delay = 0.15 # Currently it's hardcoded, could change but I think these speeds are good
	if not Input.is_action_pressed("ui_zoomies"):
		if Input.is_action_pressed("ui_anti_zoomies"): 
			move_delay = 0.30 
			# Surprisingly it's not going faster that kinda breaks it but it's going slower that does
			# spam and see what I mean. Doesn't really matter anyway, what purpose is there to slow down?
		else:
			move_delay = 0.15
		
func _shoot():
	if timer > 0.0:
		return
	timer = cooldown
	# show muzzle flash
	flash.show()
	flash.rotation = randf_range(-0.1, 0.1)  # optional: small random tilt
	# hide it again shortly
	get_tree().create_timer(flash_time).timeout.connect(flash.hide)
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.damage = damage  # pass damage to bullet
	bullet.b_speed = bullet_speed  # pass damage to bullet
	get_tree().current_scene.add_child(bullet)
	
	get_node("/root/main/Camera2D").shake(50.0, 10.0)

func _game_over():
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
