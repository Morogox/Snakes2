extends "res://Bullets/Scripts/bullet.gd"

signal e_miss(position: Vector2) # for sound
signal e_hit(position: Vector2) # for sound


func _on_body_entered(body):
	super(body)
	if has_hit:
		return
	if body.is_in_group("Boundaries"):
		hit_effect()
		has_hit = true
		emit_signal("e_miss", global_position)
		queue_free()

func _on_area_entered(area: Area2D) -> void: 
	super(area)
	if has_hit:
		
		return
	has_hit = true
	if area.is_in_group("SnakeHead"):
		print(">>>>>>>>>>>>>>HEAD HIT<<<<<<<<<<<<<<<<<<<")
		hit_effect()
		area.take_hit(1)
		emit_signal("e_hit", global_position)
		queue_free()

	if area.is_in_group("Segments"):
		hit_effect()
		area.take_hit(1)
		emit_signal("e_hit", global_position)
		queue_free()
