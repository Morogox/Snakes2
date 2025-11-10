extends "res://Bullets/Scripts/bullet.gd"

signal s_miss(position: Vector2) # for sound
signal snake_hit(position: Vector2) # for sound

func _on_body_entered(body):
	super(body)
	if has_hit:
		return
	has_hit = true
	if body.is_in_group("Enemies"):
		hit_effect()
		body.take_hit(damage, velocity, force)
		emit_signal("snake_hit", global_position)
		queue_free()
	if body.is_in_group("Boundaries"):
		hit_effect()
		emit_signal("s_miss", global_position)
		queue_free()
