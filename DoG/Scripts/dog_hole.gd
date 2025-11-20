extends Node2D
@export var rotational_speed = 0.1

var regular_scale : Vector2
@onready var l4 = $Sprites/Sprite2D
@onready var l3 = $Sprites/Sprite2D2
@onready var l2 = $Sprites/Sprite2D3
@onready var l1 = $Sprites/Sprite2D4

@onready var sw = $Shockwave
@onready var star = $DoGSparks

@onready var sprites = $Sprites

var emerge = true
var pair_pos : Vector2
func _ready():
	regular_scale = scale
	sprites.scale = Vector2.ZERO
	modulate.a = 0.0
	spawn()
func _process(delta):
	l4.rotation += rotational_speed * delta
	l3.rotation += (rotational_speed + 0.2) * delta
	l2.rotation += (rotational_speed + 0.7) * delta
	#l1.rotation += (rotational_speed + 0.6) * delta
func spawn():
	#rotational_speed = 2.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(sprites, "scale", Vector2(1.0,1.0), 1.0)
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	await tween.finished
	#rotational_speed = 0.5
func destroy():
	#rotational_speed = 2.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN) 
	tween.set_trans(Tween.TRANS_EXPO)    
	tween.set_parallel(true)
	tween.tween_method(set_rotational_value, 2.0, 0.1, 1.0)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished  # await completion
	queue_free()  # free the node after animation


func _on_area_exited(area: Area2D) -> void:
	if area == Handler.snake_head.segments[-1]:
		destroy()

func set_rotational_value(value):
	rotational_speed = value


func _on_area_entered(area: Area2D) -> void:
	if area == Handler.snake_head:
		if emerge:			
			area.set_collision_mask_value(2, true)
			area.can_input = true
			sw.toggle_emission(true)
			star.toggle_emission (true)
			get_node("/root/main/Game/Camera2D").shake(100.0, 5.0)
			
	if area.is_in_group("Segments") and not emerge:
		area.teleport = true
	elif area.is_in_group("Segments") and emerge and area.teleport: 
		await get_tree().create_timer(0.1).timeout
		area.teleport = false 
