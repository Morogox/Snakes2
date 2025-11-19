extends Area2D

@onready var GRID_SIZE = 0
@onready var CELL_OFFSET = Vector2.ZERO
var grid_origin = Vector2.ZERO

#const SEGMENT_TEXTURE = preload("res://Sprites/snakeSegment.png")
#const SEGMENT_TURN_TEXTURE = preload("res://Sprites/snakeSegmentTest.png")
const DEATH_TEXTURE = preload("res://Sprites/sSnakeHead_dead.png")


@export var move_delay_default = 0.12  # Squares per frame
var move_delay = move_delay_default
var move_timer = move_delay
var move_progress = move_timer / move_delay
var can_input = true

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


const MAX_QUEUE_SIZE = 5
var input_queue = []

#Snake segment stuff
@export var segment_scene: PackedScene
var segments = []
var pending_growth = 0
var move_history = []

@export var starting_segments = 2


@export var bullet_scene: PackedScene 
@onready var muzzle = $Muzzle   # Marker2D
@export var damage = 1
@export var bullet_speed = 10000
var target_angle = null
var cooldown := 0.2
var timer := 0.0

@export var invulnerable = false
@export var inf_ammo = false
@export var inf_stamina = false

@onready var flash = $sMuzzleFlash

@export var boost_multi = 2

var flash_time := 0.05   # how long to show the flash (seconds)
signal shooted() # for sound
@onready var ear = $AudioListener2D

var is_dead = false

signal segments_update(count: int)
signal snake_died(segment_count: int)
signal stamina_changed(stamina, max_stamina)
var alive_texture: Texture
signal snake_has_a_critical_owie() # for sound
signal snake_after_not_surviving() # for sound


@export var stamina_regen_rate := 0.1
@export var max_stamina := 100.0
@export var stamina_cap := 300.0
@export var stamina_consumption_rate := 20.0
var stamina := max_stamina
var is_boosting = false

@export var hp = 1.0


var current_velocity: Vector2:
	get:
		if move_delay > 0:
			return (target_pixel_pos - prev_pixel_pos) / move_delay
		return Vector2.ZERO

var force_clear_tail = false
func _deferred_rdy():
	is_dead = false
	collision_layer = 1
	$sSnakeHead.texture = alive_texture
	direction = Vector2.RIGHT            
	modulate.a = 1.0
	scale = Vector2(1, 1)
	move_timer = move_delay
	# Set snake to the center of the grid
	snake_pos = Vector2(floor(Handler.grid_manager.grid_width / 2), floor(Handler.grid_manager.grid_height / 2))
	GRID_SIZE = Handler.grid_manager.GRID_SIZE
	CELL_OFFSET = Handler.grid_manager.CELL_OFFSET
	Handler.grid_manager.set_cell(snake_pos, 1)
	
	grid_origin = Handler.grid_manager.grid_origin
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
	Handler.register(name.to_snake_case(), self)
	alive_texture = $sSnakeHead.texture
	call_deferred("_deferred_rdy")

func _process(delta):
	
	if is_dead:
		return
	move_timer += delta
	move_progress = move_timer/move_delay
	_handle_input(delta)
	_update_head_rotation()
	# Move snake logic every move_delay
	if move_timer >= move_delay:
		move_timer = 0.0
		_move_snake()
	position = _lerp_position(prev_pixel_pos, target_pixel_pos)
	_update_segments()
	timer = max(timer - delta, 0.0)

func _handle_input(delta):
	if not can_input:
		return
	if Input.is_action_pressed("ui_boost") and stamina > 0: #
		is_boosting = true
		move_delay = move_delay_default / boost_multi
		move_timer = move_delay * move_progress
		if not inf_stamina: stamina = max(0.0, stamina - stamina_consumption_rate * delta)
	else:
		is_boosting = false
		move_delay = move_delay_default
		move_timer = move_delay * move_progress
		if !Input.is_action_pressed("ui_boost"):
			stamina = min(max_stamina, stamina + (max_stamina * stamina_regen_rate) * delta)
	emit_signal("stamina_changed", stamina, max_stamina)

func _update_head_rotation():
	rotation = DIR_ROTATIONS.get(direction, 0)

func _update_segments():
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
			if i == segments.size() - 1:
				segment.is_end(true)
			else:
				segment.is_end(false)
			
			var turn_direction = _is_turning(i, p2, p1)
			if turn_direction != 0:
				sprite2.visible = true
				sprite2.position = Vector2(sprite.texture.get_size().x, 0).lerp(Vector2.ZERO, move_timer/move_delay)
				
				# Determine turn direction and flip accordingly
				if turn_direction > 0:  # Clockwise
					sprite2.flip_v = true 
				else:  # Counterclockwise
					sprite2.flip_v = false
			else:
				sprite2.visible = false
				sprite2.position.x = sprite.position.x + sprite.texture.get_size().x
			
			#sprite.texture = _get_segment_texture(i, p2, p1)
			
func _get_turn_direction(index: int, current_pos: Vector2, next_pos: Vector2) -> int:
	
	var dir1 = (current_pos - segments[index].global_position).normalized()
	var dir2 = (next_pos - current_pos).normalized()
	var cross = dir1.x * dir2.y - dir1.y * dir2.x
	print(sign(cross))
	return sign(cross)  # Returns 1 for clockwise, -1 for counterclockwise

# Checks if a snake segment is currently turning.
# - Compares the segment's current direction (dir_current) to the direction of the segment ahead (dir_ahead).
# - For the first segment (index == 0), dir_ahead is calculated from the head's target position.
# - For other segments, dir_ahead is based on the position of the segment directly before it in move_history.
# - Returns true if the segment is turning (i.e., directions are different and non-zero), false otherwise.
# index: The segment's index in the segments array (0 = first segment).
# p2: The segment's target position on the move_history trail.
# p1: The segment's previous position on the move_history trail.
func _is_turning(index: int, p2: Vector2, p1: Vector2) -> int:
	var dir_current = (p2 - p1).normalized()
	var dir_ahead: Vector2
	if index == 0:
		dir_ahead = (target_pixel_pos - move_history[0]).normalized()
	else:
		dir_ahead = (move_history[index - 1] - p2).normalized()
		
	# Check if turning
	var turning = dir_current != dir_ahead and dir_current != Vector2.ZERO and dir_ahead != Vector2.ZERO
	if not turning:
		return 0
	
	# Calculate turn direction using cross product
	var cross = dir_current.x * dir_ahead.y - dir_current.y * dir_ahead.x
	return sign(cross)  # 1 or -1

# Queues a new movement direction for the snake.
# - Only adds the new direction if it does not reverse the current direction or the last queued direction.
# - Ensures the new direction is different from the last direction to prevent redundant input.
# - Limits the input queue to a maximum size (MAX_QUEUE_SIZE) to prevent excessive buffering.
# new_dir: Vector2 representing the desired movement direction (e.g., Vector2.RIGHT, Vector2.UP).
func _queue_direction(new_dir):
	 # Only queue if it doesn’t reverse current direction or last queued
	var last_dir = input_queue[-1] if input_queue.size() > 0 else direction
	# Add input to queue if its not reversing direction, the same diection, or exeedig input queue size
	if new_dir != -last_dir and input_queue.size() < MAX_QUEUE_SIZE:
		#print("Direction successfully appended!")
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
		return
	var seg = segment_scene.instantiate()
	
	# Manually attach the script
	var script = load("res://Scripts/snake_segment.gd")
	seg.set_script(script)
	
	get_tree().get_root().get_node("main/Game/Segments").add_child(seg)
	seg.add_to_group("Segments")
	
	# Only connect if signal exists
	if seg.has_signal("segment_destroyed"):
		seg.segment_destroyed.connect(_remove_segment)
	
	seg.segment_death.connect(Handler.sound_effect_handler._segment_death)
	seg.segment_heal.connect(Handler.sound_effect_handler._segment_heal)
	
	segments.append(seg)
	var tail_pos = move_history.back()
	seg.position = tail_pos
	move_history.append(tail_pos)
	
	segments[-1]._heal(1, 0.05 * (segments.size() - 1))
	
	emit_signal("segments_update", segments.size())

func _remove_tail_segment():
	var tail_segment = segments[-1]
	
	var tail_cell = Handler.grid_manager.pixel_to_cell(tail_segment.position)
	Handler.grid_manager.set_cell(tail_cell, 0)
	
	tail_segment.queue_free()
	segments.remove_at(segments.size() - 1)
	move_history.remove_at(move_history.size() - 1)
	_update_grid_map()

func remove_segment_logical(segment):
	force_clear_tail = true
	var i = segments.find(segment)
	var cell = Handler.grid_manager.pixel_to_cell(segment.position)
	#print("REMOVING segment at index ", i, " from cell ", cell, " | Grid before: ", Handler.grid_manager.get_cell(cell))
	Handler.grid_manager.set_cell(cell, 0)
	#print("Grid after clear: ", Handler.grid_manager.get_cell(cell))
	segments.remove_at(i)
	move_history.remove_at(i+1)
	_update_grid_map()
	force_clear_tail = false
func _grow(amount:=1, heal:= true):
	pending_growth += amount
	if heal:
		for idx in range(segments.size()):
			segments[idx]._heal(1, 0.05 * idx)
	_update_stamina(amount)
	

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
		var validPop = false
		while validPop == false:
			var temp =input_queue.pop_front()
			if input_queue.size() <= 0:
				validPop = true
			if temp != direction and temp != -direction:
				direction = temp
				validPop = true 

	# compute new head cell
	var next_pos = snake_pos + direction
	# self-collision check using grid map
	if Handler.grid_manager.get_cell(next_pos) == 1:
		print("YOU HIT A SEGMENT YOU HIT A SEGMENT")
		_game_over()
	
	snake_pos += direction
	target_pixel_pos = grid_origin + snake_pos * GRID_SIZE + CELL_OFFSET
	_update_grid_map()
	if pending_growth > 0:
		_add_segment()
		pending_growth -= 1
	#Handler.grid_manager.print_grid_map()
# Updates the grid_map for the snake
# Marks the head cell as occupied, clears the tail cell if not growing
func _update_grid_map():
	Handler.grid_manager.set_cell(snake_pos, 1)  # mark head
	if pending_growth == 0 or force_clear_tail:
		var tail_cell = Handler.grid_manager.pixel_to_cell(move_history[-1])
		Handler.grid_manager.set_cell(tail_cell, 0)

# Linear interpolation between two points based on current move progress
# p1 = starting position, p2 = target position
# Returns the interpolated position for smooth movement
func _lerp_position(p1: Vector2, p2: Vector2) -> Vector2:
	var t = move_timer / move_delay
	return p1.lerp(p2, t)

func _get_rotation(p1: Vector2, p2: Vector2) -> float:
	var dir = p2 - p1
	return atan2(dir.y, dir.x)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Boundaries") or body.is_in_group("Enemies"):
		_game_over()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Items"):
		match area.item_type:
			"apple":
				_grow(area.value) # grow snake by apple value	
				
				area.destroy() # tells apple that it has been eaten
	#if area.is_in_group("EnemyBullet"):
		#_game_over()

func _input(event):
	if not can_input:
		return
	#if event is not InputEventMouse and event.is_pressed():
	if event is InputEventKey and not event.echo:
		if Input.is_action_pressed("ui_fire"):
			if segments.size() > 0:
				
				_shoot()
				#_remove_segment(segments[0])

		for action in inputs.keys():
			if Input.is_action_just_pressed(action): 
				_queue_direction(inputs[action])
				break

func _shoot():
	if timer > 0.0:
		return
	if not inf_ammo: _remove_segment(segments[-1])
	var dir =  global_rotation
	if input_queue.size() > 0:
		dir = input_queue[0].angle()
		
	timer = cooldown
	# show muzzle flash
	flash.show()
	flash.rotation = randf_range(-0.1, 0.1)  # optional: small random tilt
	# hide it again shortly
	get_tree().create_timer(flash_time).timeout.connect(flash.hide)
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = dir
	bullet.damage = damage  # pass damage to bullet
	bullet.b_speed = bullet_speed  # pass damage to bullet
	get_tree().get_root().get_node("main/Game/Bullets").add_child(bullet)
	bullet.s_miss.connect(Handler.sound_effect_handler._s_miss)
	bullet.snake_hit.connect(Handler.sound_effect_handler._snake_hit) # Whatever you do, do NOT abbreviate "snake" and have "hit" after
	bullet.s_deflect.connect(Handler.sound_effect_handler._s_deflect)
	bullet.snake_hit.connect(_bullet_hit_enemy)
	get_node("/root/main/Game/Camera2D").shake(50.0, 10.0)
	
	# Play Sound
	emit_signal("shooted")
	#print(ear.global_position)
	#print(ear.position)

func _game_over():
	if not invulnerable and not is_dead:
		is_dead = true
		var final_segment_count = segments.size()
		collision_layer = 0
		$sSnakeHead.texture = DEATH_TEXTURE
		get_node("/root/main/Game/Camera2D").shake(100.0, 5.0)
		emit_signal("snake_has_a_critical_owie")
		await get_tree().create_timer(1.0).timeout
		emit_signal("snake_after_not_surviving")
		if segments.size() > 0:
			_remove_segment(segments[0])
		await _death_animation()
		await get_tree().create_timer(2.0).timeout
		print("Snake is emitting signal with count: ", final_segment_count)
		emit_signal("snake_died", final_segment_count)

func _death_animation():
	# Play tween animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished  # await completion
	
# Called when a segment is destroyed by enemy fire
func _remove_segment(segment: Area2D):
	
	var i = segments.find(segment)
	var to_remove = segments.slice(i, segments.size())  # forward order for domino

	for idx in range(to_remove.size()):
		var seg = to_remove[idx]
		remove_segment_logical(seg)  # remove immediately
		seg.destroy_this_segment(0.05 * idx)  # stagger tween start

	_update_stamina()
	emit_signal("segments_update", segments.size())
	

func _update_stamina(num :=  0):
	var ratio := 0.0
	if max_stamina > 0:
		ratio = stamina / max_stamina

	var new_max := 10.0 + (segments.size() + num) * 10.0
	max_stamina = new_max

	stamina = ratio * max_stamina + max_stamina * num/5
	stamina = min(stamina, max_stamina)
	emit_signal("stamina_changed", stamina, max_stamina)

func get_predicted_velocity() -> Vector2:
	# Velocity is zero if we're not about to move
	if move_timer < move_delay - 0.1:  # adjust threshold as needed
		return Vector2.ZERO
	# Otherwise, assume we'll continue in current direction
	return direction * (GRID_SIZE / move_delay)
	
func take_hit(dmg = 1.0):
	if invulnerable:
		return
	hp -= dmg
	if hp <= 0:
		_game_over()
	pass

func _bullet_hit_enemy(_v: Vector2):
	_grow(1, false)
