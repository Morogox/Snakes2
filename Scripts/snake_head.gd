extends Area2D
var input_vector = Vector2.ZERO
const GRID_SIZE = 32
@export var move_delay = 0.1  # seconds per move, this is also speed; higher = slower

var snake_pos = Vector2(0, 0)   # grid coordinates
var start_pos = Vector2.ZERO

var direction = Vector2.RIGHT   
var prev_pixel_pos = Vector2.ZERO
var target_pixel_pos = Vector2.ZERO

var move_timer = move_delay
var cell_offset = Vector2(GRID_SIZE, GRID_SIZE) * 0.5
const MAX_QUEUE_SIZE = 3
var input_queue = []

#Snake segment stuff
@export var segment_scene: PackedScene
var segments = []
var pending_growth = 0
var move_history = []

@export var starting_segments = 5

func _init_position():
	var main_node = get_parent()
	# Set snake to the center of the grid
	snake_pos = Vector2(floor(main_node.grid_width / 2), floor(main_node.grid_height / 2))
	
	start_pos = main_node.start_pos
	target_pixel_pos = start_pos + snake_pos * GRID_SIZE + cell_offset
	prev_pixel_pos = target_pixel_pos
	position = target_pixel_pos
	
	for s in segments:
		s.queue_free()
	segments.clear()
	move_history.clear()
		
	move_history.push_front(target_pixel_pos)

	for i in range(starting_segments):
		var seg = segment_scene.instantiate()
		get_parent().add_child(seg)
		var seg_pos = target_pixel_pos - direction * GRID_SIZE * (i + 1)
		seg.position = seg_pos
		segments.append(seg)
		move_history.append(seg_pos)

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
	
	match direction:
		Vector2.RIGHT:
			rotation = 0
		Vector2.LEFT:
			rotation = PI
		Vector2.UP:
			rotation = -PI / 2
		Vector2.DOWN:
			rotation = PI / 2
	var t = move_timer / move_delay
	position = prev_pixel_pos.lerp(target_pixel_pos, t)

	for i in range(segments.size()):
		var segment = segments[i]
		# The segment's previous spot on the trail
		var p1 = move_history[i+1]
		# The segment's target spot on the trail
		var p2 = move_history[i]
		# Lerp the segment's position between those two points
		segment.position = p1.lerp(p2, t)
		# Rotate to face movement direction
		var dir = p2 - p1
		segment.rotation = atan2(dir.y, dir.x)
		
		# The “segment ahead” is move_history[i-1] (head for first segment)
		var dir_current = (p2 - p1).normalized()
		var dir_ahead : Vector2
		if i == 0:
			dir_ahead = (target_pixel_pos - move_history[0]).normalized()
		else:
			dir_ahead = (move_history[i - 1] - p2).normalized()
		var turning = dir_current != dir_ahead
		
		
	
		# debugging
		var sprite: Sprite2D = segment.get_node("Sprite2D") # replace with actual child name
		if turning:
			sprite.texture = preload("res://sprites/snakeSegmentTest.png")
		else:
			sprite.texture = preload("res://sprites/snakeSegment.png")
		#print((move_history[0] - move_history[1]).normalized())
		#print("Segment ", i, " turning: ", turning, dir_current, dir_ahead)
		#print("----------------------------------------------------------------------------------")

func _queue_direction(new_dir):
	 # Only queue if it doesn’t reverse current direction or last queued
	var last_dir = input_queue[-1] if input_queue.size() > 0 else direction
	# Add inpiut to queue if its not reversing direction, the same diection, or exeedig input queue size
	if new_dir != -last_dir and new_dir != last_dir and input_queue.size() < MAX_QUEUE_SIZE:
		input_queue.append(new_dir)


func _add_segment():
	if segment_scene == null:
		print("No segment scene assigned!")
		return
	var seg = segment_scene.instantiate()
	get_parent().add_child(seg)
	seg.position = prev_pixel_pos if segments.is_empty() else segments[-1].position
	segments.append(seg)
	var tail_pos = move_history.back()
	seg.position = tail_pos
	move_history.append(tail_pos)


func grow(amount=1):
	pending_growth += amount

func _move_snake():
	move_history.push_front(target_pixel_pos)
	move_history.resize(segments.size() + 1)
	
	prev_pixel_pos = target_pixel_pos
	if input_queue.size() > 0:
		direction = input_queue.pop_front()
	snake_pos += direction
	target_pixel_pos = start_pos + snake_pos * GRID_SIZE + cell_offset
	
	if pending_growth > 0:
		_add_segment()
		pending_growth -= 1

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Boundaries"):
		print("Boundary Collision detected")
	
	
		


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Apple"):
		print("Snake ate apple!")
		area.queue_free() # remove apple
		get_parent().spawn_apple() # respawn a new one
		grow(1) # grow snake by 1
