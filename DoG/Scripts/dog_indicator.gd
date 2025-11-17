extends Line2D
@export var flash_duration = 0.3
var tween: Tween

func show_trajectory(start: Vector2, end: Vector2):
	clear_points()
	add_point(start)
	add_point(end)
	flash()

func flash():
	if tween:
		tween.kill()

	tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.3, flash_duration)
	tween.tween_property(self, "modulate:a", 1.0, flash_duration)
