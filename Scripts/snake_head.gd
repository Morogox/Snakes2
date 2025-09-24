extends Area2D
var input_vector = Vector2.ZERO
const GRID_SIZE = 32
@export var move_delay = 0.3  # seconds per move, this is also speed; higher = slower

var snake_pos = Vector2(5, 5)   # grid coordinates
var direction = Vector2.RIGHT   
var prev_pixel_pos = Vector2.ZERO
var target_pixel_pos = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D # for when we add animations
var rotation_time # when a direction is pressed, how much time until moving that direction
var is_rotating = "no" # makes it so key variables are only set once per turn
var rotate_direction = Vector2.RIGHT # remembers which direction it should turn
var queued = Vector2.RIGHT # tells "rotate_direction" what to remember when needed
var what_is_delta # used to remove time from the rotation time to get exactly how many partial rotations are needed

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
	what_is_delta = delta # Allows for the removal of time... later
	if Input.is_action_just_pressed("ui_right") and direction != Vector2.LEFT:
		_queue_direction(Vector2.RIGHT)
		queued = Vector2.RIGHT # gets "rotate_direction" in "_rotate_snake" ready to remember this direction
	elif Input.is_action_just_pressed("ui_left") and direction != Vector2.RIGHT:
		_queue_direction(Vector2.LEFT)
		queued = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up") and direction != Vector2.DOWN:
		_queue_direction(Vector2.UP)
		queued = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") and direction != Vector2.UP:
		_queue_direction(Vector2.DOWN)
		queued = Vector2.DOWN
	#print(input_queue)
	_rotate_snake()
	# Move snake logic every move_delay
	if move_timer >= move_delay:
		move_timer = 0.0
		_move_snake()
		
	# Smoothly interpolate position
	var t = move_timer / move_delay
	position = prev_pixel_pos.lerp(target_pixel_pos, t)
	
	print(t)
func _queue_direction(new_dir):
	 # Only queue if it doesn’t reverse current direction or last queued
	var last_dir = input_queue[-1] if input_queue.size() > 0 else direction
	# Add input to queue if its not reversing direction, the same diection, or exeedig input queue size
	if new_dir != -last_dir and new_dir != last_dir and input_queue.size() < MAX_QUEUE_SIZE:
		input_queue.append(new_dir)

func _move_snake():
	prev_pixel_pos = target_pixel_pos
	# Pop next direction from queue if available
	if input_queue.size() > 0:
		direction = input_queue.pop_front()
	snake_pos += direction
	target_pixel_pos = snake_pos * GRID_SIZE + cell_offset

func _rotate_snake():
	if is_rotating == "no" and queued != direction: # Only happens ONCE if a new direction is queued, despite the function being called every frame
		rotation_time = (move_delay - move_timer)/what_is_delta # Equation for finding how many tiny turns must be done
		is_rotating = "yes" # makes this block not happen again, storing these variables
		rotate_direction = queued # this also gets stored
	# Rotate head to face direction
	if is_rotating == "yes" and rotation_time > 5: # Only need to rotate if rotating, the > part is for not making a super duper fast turn, >5 means no fancy rotation if only 5 tiny turns
		if rotate_direction == Vector2.RIGHT: # If we want to go right...
			if direction == Vector2.DOWN: # ...but we're moving down...
					rotation -= (PI / 2)/rotation_time # ...Turn Counterclockwise
			if direction == Vector2.UP: # ...but we're moving up...
					rotation += (PI / 2)/rotation_time #Clockwise
		elif rotate_direction == Vector2.LEFT: # If we want to go left...
			if direction == Vector2.DOWN: # ...but we're moving down...
					rotation += (PI / 2)/rotation_time
			if direction == Vector2.UP: # ...but we're moving up... [[you get the pattern]]
					rotation -= (PI / 2)/rotation_time
		elif rotate_direction == Vector2.UP:
			if direction == Vector2.LEFT:
					rotation += (PI / 2)/rotation_time
			if direction == Vector2.RIGHT:
					rotation -= (PI / 2)/rotation_time
		elif rotate_direction == Vector2.DOWN:
			if direction == Vector2.LEFT:
					rotation -= (PI / 2)/rotation_time
			if direction == Vector2.RIGHT:
					rotation += (PI / 2)/rotation_time
	if move_timer < 2 * what_is_delta: # When the move timer resets, no more fancy rotating    It needs to be about 0 but I don't think it reaches exactly 0
		# This whole chunk down here corrects any wrongness from the pre-rotating
		# Essentially it's your normal rotation
		is_rotating = "no" # We're not doing shenanigans anymore so we're not rotating
		if direction == Vector2.RIGHT:
			rotation = 0 # Rotation is in Radians I think
		elif direction == Vector2.LEFT:
			rotation = PI
		elif direction == Vector2.UP:
			rotation = -PI / 2
		elif direction == Vector2.DOWN:
			rotation = PI / 2
