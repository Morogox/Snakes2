extends Area2D
var input_vector = Vector2.ZERO
const GRID_SIZE = 32
@export var move_delay = 0.1  # seconds per move, this is also speed; higher = slower

var snake_pos = Vector2(5, 5)   # grid coordinates
var direction = Vector2.RIGHT   
var prev_pixel_pos = Vector2.ZERO
var target_pixel_pos = Vector2.ZERO

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
	if Input.is_action_just_pressed("ui_right") and direction != Vector2.LEFT:
		_queue_direction(Vector2.RIGHT)
	elif Input.is_action_just_pressed("ui_left") and direction != Vector2.RIGHT:
		_queue_direction(Vector2.LEFT)
	elif Input.is_action_just_pressed("ui_up") and direction != Vector2.DOWN:
		_queue_direction(Vector2.UP)
	elif Input.is_action_just_pressed("ui_down") and direction != Vector2.UP:
		_queue_direction(Vector2.DOWN)
	#print(input_queue)
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
	# Add inpiut to queue if its not reversing direction, the same diection, or exeedig input queue size
	if new_dir != -last_dir and new_dir != last_dir and input_queue.size() < MAX_QUEUE_SIZE:
		input_queue.append(new_dir)

func _move_snake():
	prev_pixel_pos = target_pixel_pos
	# Pop next direction from queue if available
	if input_queue.size() > 0:
		direction = input_queue.pop_front()
	snake_pos += direction
	target_pixel_pos = snake_pos * GRID_SIZE + cell_offset
