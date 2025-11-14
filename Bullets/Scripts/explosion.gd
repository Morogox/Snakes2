extends Area2D
@onready var explosion_particle =  $EnemyExplosion
@onready var collision_box = $CollisionShape2D
@onready var collision_box_timer = $Timer
@export var collision_box_time = 0.2
@export var explosion_life_time = 2.0
@export var dmg = 1.0
@export var force = 1000



func _ready():
	explosion_particle.toggle_emission(true)
	collision_box_timer.start(explosion_life_time)
	get_node("/root/main/Game/Camera2D").shake(80.0, 10.0)
	await get_tree().create_timer(collision_box_time).timeout
	collision_box.disabled = true
	
func _on_area_entered(area: Area2D) -> void:
	print("triggered")
	if area.is_in_group("SnakeHead"):
		area.take_hit(dmg)
		#emit_signal("e_hit", global_position)


	if area.is_in_group("Segments"):
		area.take_hit(dmg)
		#emit_signal("e_hit", global_position)

func _on_body_entered(body):
	if body.is_in_group("Enemies"):
		var velocity = body.global_position - global_position
		body.take_hit(dmg, velocity, force)

func _on_timer_timeout() -> void:
	queue_free()
