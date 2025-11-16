extends Node2D
@export var rotational_speed = 0.1

var regular_scale : Vector2
@onready var l4 = $Sprite2D
@onready var l3 = $Sprite2D2
@onready var l2 = $Sprite2D3
@onready var l1 = $Sprite2D4
func _ready():
	regular_scale = scale
	scale = Vector2.ZERO
	modulate.a = 0.0
	spawn()
func _process(delta):
	l4.rotation += rotational_speed * delta
	l3.rotation += (rotational_speed + 0.2) * delta
	l2.rotation += (rotational_speed + 0.7) * delta
	#l1.rotation += (rotational_speed + 0.6) * delta
func spawn():
	rotational_speed = 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", regular_scale, 1.0)
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	await tween.finished
	rotational_speed = 0.5
func destroy():
	rotational_speed = 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished  # await completion
	queue_free()  # free the node after animation


func _on_area_exited(area: Area2D) -> void:
	if area == Handler.snake_head.segments[-1]:
		destroy()
