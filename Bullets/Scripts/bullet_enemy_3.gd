extends "res://Bullets/Scripts/bullet.gd"

signal e_miss(position: Vector2) # for sound
signal e_hit(position: Vector2) # for sound
var hit_segments = {}
@export var hit_cd = 0.1


func _on_body_entered(body):
	super(body)
	#if has_hit and not can_hit_multiple:
		#return
	if body.is_in_group("Boundaries"):
		hit_effect()
		has_hit = true
		emit_signal("e_miss", global_position)
		queue_free()

func _on_area_entered(area: Area2D) -> void: 
	super(area)
	if area.is_in_group("SnakeHead"):
		hit_effect()
		area.take_hit(1)
		emit_signal("e_hit", global_position)


	if area.is_in_group("Segments"):
		if area in hit_segments:
			return
		# Mark as hit

		hit_segments[area] = true
		hit_effect()
		area.take_hit(1)
		emit_signal("e_hit", global_position)
