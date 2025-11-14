extends StaticBody2D

func destroy():
	collision_layer = 0  
	collision_mask = 0  
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished  # await completion
	queue_free()  # free the node after animation
