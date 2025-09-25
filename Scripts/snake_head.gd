extends Area2D
var input_vector = Vector2.ZERO
const GRID_SIZE = 32
@export var move_delay = 0.2 # seconds per move, this is also speed; higher = slower

var snake_pos = Vector2(5, 5)   # grid coordinates
var direction = Vector2.RIGHT   
var prev_pixel_pos = Vector2.ZERO
var target_pixel_pos = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D # for when we add animations
var rotation_time # when a direction is pressed, how much time until moving that direction
var is_rotating: bool = false # makes it so key variables are only set once per turn
var rotate_direction = Vector2.RIGHT # remembers which direction it should turn
var rotation_start
var rotation_end
var rotation_duration

var move_timer = 0.0
var cell_offset = Vector2(GRID_SIZE, GRID_SIZE) * 0.5
const MAX_QUEUE_SIZE = 2
var input_queue = []

func _ready():
	# Origin is not at top left of a node, its at the center, so cell_offset is added
	target_pixel_pos = snake_pos * GRID_SIZE + cell_offset
	prev_pixel_pos = target_pixel_pos
	position = target_pixel_pos

func _process(delta):
	# Input
	move_timer += delta

# Handle input and queue directions
	var new_dir: Vector2 = Vector2.ZERO
	if Input.is_action_just_pressed("ui_right"):
		new_dir = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left"):
		new_dir = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up"):
		new_dir = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		new_dir = Vector2.DOWN

	if new_dir != Vector2.ZERO:
		if _queue_direction(new_dir):
			# Start rotation immediately for first queued direction
			if not is_rotating:
				_start_rotation(input_queue[0])
	# Update smooth rotation
	_rotate_snake(delta)
	
	# Move snake every move_delay
	if move_timer >= move_delay:
		move_timer = 0
		_move_snake()

	# Smoothly interpolate position
	var t = move_timer / move_delay
	position = prev_pixel_pos.lerp(target_pixel_pos, t)
func _queue_direction(new_dir):
	 # Only queue if it doesn’t reverse current direction or last queued
	var last_dir = input_queue[-1] if input_queue.size() > 0 else direction
	# Add input to queue if its not reversing direction, the same diection, or exeedig input queue size
	if new_dir != -last_dir and new_dir != last_dir and input_queue.size() < MAX_QUEUE_SIZE:
		input_queue.append(new_dir)
		return true
	return false

func _move_snake():
	prev_pixel_pos = target_pixel_pos
	# Pop next direction from queue if available
	if input_queue.size() > 0:
		direction = input_queue.pop_front()
	snake_pos += direction
	target_pixel_pos = snake_pos * GRID_SIZE + cell_offset
	# Start rotation toward new direction
	if direction != rotate_direction:
		_start_rotation(direction)

func _start_rotation(new_dir):
	rotate_direction = new_dir
	is_rotating = true
	rotation_start = rotation
	rotation_end = _get_snap_rotation(new_dir)
	rotation_time = move_delay - move_timer
	rotation_duration = rotation_time      

# Get what angle the sprite need to be roatated to base on direction
func _get_snap_rotation(dir):
	match dir:
		Vector2.RIGHT: return 0
		Vector2.LEFT: return PI
		Vector2.UP: return -PI/2
		Vector2.DOWN: return PI/2
		_: return rotation

func _rotate_snake(delta):
	if not is_rotating:
		return
 	# reduce remaining rotation time
	rotation_time -= delta
	# Compute fraction of rotation completed
	# If rotation_time <= 0, t = 1
	var elapsed_fraction = clamp(1.0 - rotation_time / rotation_duration, 0, 1)
	rotation = lerp_angle(rotation_start, rotation_end, elapsed_fraction)
	# Snap exactly when done
	if rotation_time <= 0:
		rotation = rotation_end
		is_rotating = false


##alternatively, just this
#func _rotate_snake(delta):
	## Desired angle based on the movement direction
	#var target_angle := 0.0
	#match direction:
		#Vector2.RIGHT: target_angle = 0
		#Vector2.LEFT:  target_angle = PI
		#Vector2.UP:    target_angle = -PI / 2
		#Vector2.DOWN:  target_angle = PI / 2
	#
	## Smoothly rotate every frame
	#rotation = lerp_angle(rotation, target_angle, delta * 10) 
