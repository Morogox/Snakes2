extends "res://Scripts/bullet.gd"

func _on_body_entered(body):
	if has_hit:
		return
	has_hit = true
	if body.is_in_group("Enemies"):
		hit_effect()
		body.take_hit(damage, velocity, force)
		queue_free()
	if body.is_in_group("Boundaries"):
		hit_effect()
		queue_free()
