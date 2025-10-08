extends Node2D
@export var lifetime := 0.05  # seconds

func _ready():
	# auto-destroy after a short time
	rotation += randf_range(-0.1, 0.1)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
