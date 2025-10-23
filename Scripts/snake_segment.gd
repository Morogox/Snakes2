extends Area2D

@export var max_hp := 2
var hp := max_hp

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite2: Sprite2D = $Sprite2D2

signal segment_destroyed  # Removed type hint

var normal_color := Color(1, 1, 1, 1)  # white/normal
var damaged_color := Color(0.6, 0.1, 0.1, 1)  # dark red

func _ready():
	add_to_group("Segments")
	_update_color()

func take_hit(damage: int = 1):
	hp -= damage
	
	if hp <= 0:
		_destroy_segment()
	else:
		_update_color()
		await _flash_hit()

func _update_color():
	if hp <= 1:
		sprite.modulate = damaged_color
		sprite2.modulate = damaged_color
	else:
		sprite.modulate = normal_color
		sprite2.modulate = normal_color

func _flash_hit():
	var original_color = sprite.modulate
	sprite.modulate = Color.WHITE
	sprite2.modulate = Color.WHITE
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = original_color
	sprite2.modulate = original_color

func _destroy_segment():
	segment_destroyed.emit(self) 
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyBullet"):
		take_hit(1)
