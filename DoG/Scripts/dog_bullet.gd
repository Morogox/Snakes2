extends "res://Bullets/Scripts/bullet.gd"


func _on_body_entered(body):
	if body.is_in_group("Enemies"):
		body.take_hit(damage, velocity, 100)
