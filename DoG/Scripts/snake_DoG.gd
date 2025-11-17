extends "res://Scripts/snake_head.gd"
@onready var sprite = $sSnakeHead
@export var worm_hole = preload("res://DoG/Scenes/DoG_hole.tscn")
var is_teleporting = false
func _ready():
	super()
	alive_texture = preload("res://DoG/Sprites/The_Devourer_of_Gods_Final_Phase_Head.png")
	sprite.scale = Vector2(0.5,0.5)
	

	
	
func _deferred_rdy():
	super()
	visible = false
	set_collision_layer_value(1, false)
	var wh = worm_hole.instantiate()
	wh.global_position = global_position
	get_tree().current_scene.add_child(wh)
	is_dead = true
	
	await get_tree().create_timer(9.65).timeout
	get_node("/root/main/Game/Camera2D").shake(50.0, 5.0)
	set_collision_layer_value(1, true)
	is_dead = false
	visible = true
	Handler.sound_effect_handler.summon.play()
	
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

func _update_segments():
	for i in range(segments.size()):
		if is_instance_valid(segments[i]):
			var segment = segments[i]
			var p1 = move_history[i+1]  # previous spot
			var p2 = move_history[i]    # target spot
			
			# Move segment
			if segment.teleport:
				#print("setting positon  of seg directly")
				segment.position = p2
				#segment.teleport = false 
			else:
				segment.position = _lerp_position(p1, p2)
			segment.rotation = _get_rotation(p1, p2)
			
			# Update sprite for turning
			var sprite: Sprite2D = segment.get_node("Sprite2D")
			var sprite2: Sprite2D = segment.get_node("Sprite2D2")
			if i == segments.size() - 1:
				segment.is_end(true)
			else:
				segment.is_end(false)
				
func _on_body_entered(body: Node2D) -> void:
	super(body)
	if body.is_in_group("Enemies"):
		body.take_hit(10000000000)
		body.queue_free()
		get_node("/root/main/Game/Camera2D").shake(40.0, 5.0)
		Handler.sound_effect_handler.devour.play()
		_grow(1)
	if body.is_in_group("Boundaries") and  not is_teleporting:
		is_teleporting = true
		Handler.sound_effect_handler.tp.play()
		print("GOT HERE")
		var opp_dist = Handler.grid_manager.grid_dimensions * Handler.grid_manager.GRID_SIZE *1.95
		var new_pos = global_position + (-direction) * opp_dist
		var wh = worm_hole.instantiate()
		wh.global_position = global_position
		wh.emerge = false
		wh.pair_pos = new_pos
		get_tree().current_scene.add_child(wh)
		
		var wh2 = worm_hole.instantiate()
		wh2.emerge = true
		wh2.global_position = new_pos
		get_tree().current_scene.add_child(wh2)
		
		set_collision_mask_value(2, false)
		# TELEPORT THE HEAD - Reset lerp positions!
		snake_pos = Handler.grid_manager.pixel_to_cell(new_pos)
		target_pixel_pos = grid_origin + snake_pos * GRID_SIZE + CELL_OFFSET
		prev_pixel_pos = target_pixel_pos  # KEY: Set prev to target so no lerping
		position = target_pixel_pos  # Set position immediately
		move_timer = 0.0  # Reset the move timer
		
		# TELEPORT THE SEGMENTS
		# Update move_history so segments don't lerp across the screen
		var offset = new_pos - global_position  # How far we teleported
		for i in range(move_history.size()):
			move_history[i] += offset  # Shift all history positions
		
		# Mark all segments as needing immediate teleport
		for i in range(segments.size()):
			if is_instance_valid(segments[i]):
				var segment = segments[i]
				segment.position = move_history[i]  # Set position NOW
				
		
		await get_tree().process_frame
		await get_tree().process_frame
		set_collision_mask_value(2, true)
		is_teleporting = false

func _add_segment():
	if segment_scene == null:
		return
	var seg = segment_scene.instantiate()
	
	# Manually attach the script
	var script = load("res://DoG/Scripts/snake_dog_segment.gd")
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
