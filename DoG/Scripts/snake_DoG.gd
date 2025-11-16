extends "res://Scripts/snake_head.gd"
@onready var sprite = $sSnakeHead
@export var worm_hole = preload("res://DoG/Scenes/DoG_hole.tscn")
func _ready():
	super()
	alive_texture = preload("res://DoG/Sprites/The_Devourer_of_Gods_Final_Phase_Head.png")
	sprite.scale = Vector2(0.5,0.5)
	

	
	
func _deferred_rdy():
	super()
	visible = false
	var wh = worm_hole.instantiate()
	wh.global_position = global_position
	get_tree().get_root().add_child(wh)
	is_dead = true
	await get_tree().create_timer(9.65).timeout
	is_dead = false
	visible = true
	
func _add_segment():
	super()
	segments[-1].sprite.texture = preload("res://DoG/Sprites/The_Devourer_of_Gods_Final_Phase_Body.png")

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
		
			
func _on_body_entered(body: Node2D) -> void:
	super(body)
