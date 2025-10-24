extends Area2D

@export var max_hp := 3.0
var hp := max_hp

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite2: Sprite2D = $Sprite2D2

signal segment_destroyed  # Removed type hint

var factor = hp / max_hp  # 1.0 = full health, 0.0 = dead
var damaged_color_max := Color(0.1, 0.1, 0.1)  # dark red

func _ready():
	add_to_group("Segments")

func take_hit(damage: int = 1):
	hp -= damage
	_update_color()
	flash_hit()
	if hp <= 0:
		destroy_this_segment()
		segment_destroyed.emit(self) 


func _update_color():
	factor = hp / max_hp
	sprite.modulate = damaged_color_max.lerp(Color(1, 1, 1), hp / max_hp)
	sprite2.modulate = damaged_color_max.lerp(Color(1, 1, 1), hp / max_hp)

func flash_hit(count: int = 3, interval: float = 0.05) -> void:
	var original_color = sprite.modulate  # Save current color
	var original_color2 = sprite2.modulate
	for i in count:
		print("flash loop called")
		sprite.modulate = Color(3, 3, 3, 1)  # Super bright!
		sprite2.modulate = Color(3, 3, 3, 1)
		await get_tree().create_timer(interval).timeout

		sprite.modulate = original_color  # back to original color
		sprite2.modulate = original_color2
		await get_tree().create_timer(interval).timeout

func destroy_this_segment(delay: float = 0.0) -> void:
	collision_layer = 0  # stop collisions immediately
	# Wait for stagger delay
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		
	# Play tween animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished  # await completion
	queue_free()  # free the node after animation

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyBullet"):
		take_hit(0)

func _heal(amt: int) -> void:
	hp = clamp(hp + amt, 0, max_hp)
	_update_color()
