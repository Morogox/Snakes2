extends Area2D
var input_vector = Vector2.ZERO
const GRID_SIZE = 32
@export var move_delay = 0.2  # seconds per move, this is also speed; higher = slower

var snake_pos = Vector2(0, 0)   # grid coordinates
var start_pos = Vector2.ZERO

var direction = Vector2.RIGHT   
var prev_pixel_pos = Vector2.ZERO
var target_pixel_pos = Vector2.ZERO

var move_timer = 0.0
var cell_offset = Vector2(GRID_SIZE, GRID_SIZE) * 0.5
const MAX_QUEUE_SIZE = 2
var input_queue = []


func _init_position():
	var main_node = get_parent()
	# Set snake to the center of the grid
	snake_pos = Vector2(floor(main_node.grid_width / 2), floor(main_node.grid_height / 2))
	
	start_pos = main_node.start_pos
	target_pixel_pos = start_pos + snake_pos * GRID_SIZE + cell_offset
	prev_pixel_pos = target_pixel_pos
	position = target_pixel_pos
	

func _ready():
	call_deferred("_init_position")
	

func _process(delta):
	move_timer += delta
	
	# Input
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
	
	# Rotate head to face direction
	match direction:
		Vector2.RIGHT:
			rotation = 0
		Vector2.LEFT:
			rotation = PI
		Vector2.UP:
			rotation = -PI / 2
		Vector2.DOWN:
			rotation = PI / 2

	# Smoothly interpolate position according to how much time (t) has passed since last move
	var t = move_timer / move_delay
	position = prev_pixel_pos.lerp(target_pixel_pos, t)
	
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
	target_pixel_pos =  start_pos + snake_pos * GRID_SIZE + cell_offset


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Boundaries"):
		print("Boundary Collision detected")
