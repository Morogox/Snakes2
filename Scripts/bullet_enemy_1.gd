extends "res://Scripts/bullet.gd"

func _on_body_entered(body):
	if has_hit:
		return
	if body.is_in_group("Boundaries"):
		hit_effect()
		has_hit = true
		queue_free()

func _on_area_entered(area: Area2D) -> void: 
	print("called, colliding area: ", area)
	if has_hit:
		return
	has_hit = true
	if area.is_in_group("SnakeHead"):
		hit_effect()
		queue_free()

	if area.is_in_group("Segments"):
		hit_effect()
		area.take_hit(1)
		queue_free()
