extends "res://Scripts/snake_segment.gd"
@export var teleport: bool = false
@export var bullet_scene : PackedScene
var indicator_time := 0.5
var damage := 999
var bullet_speed := 5000
@export var trajectory_line: PackedScene

func fire():
	var direction1 = Vector2.RIGHT.rotated(rotation + PI/2)
	var direction2 = Vector2.RIGHT.rotated(rotation - PI/2)
	var line = trajectory_line.instantiate()
	add_child(line)
	line.rotation = -rotation
	var line2 = trajectory_line.instantiate()
	line2.rotation = -rotation
	add_child(line2)

	line.show_trajectory(Vector2(0,0), Vector2(0,0) + direction1 * 9000)
	line2.show_trajectory(Vector2(0,0), Vector2(0,0) + direction2 * 9000)
	
	await get_tree().create_timer(indicator_time).timeout
	line.queue_free()
	line2.queue_free()
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position =global_position
	bullet.global_rotation = global_rotation + PI/2
	bullet.damage = damage  # pass damage to bullet
	bullet.b_speed = bullet_speed  # pass damage to bullet
	get_tree().get_root().get_node("main/Game/Bullets").add_child(bullet)
	
	var bullet2 = bullet_scene.instantiate()
	bullet2.global_position =global_position
	bullet2.global_rotation = global_rotation - PI/2
	bullet2.damage = damage  # pass damage to bullet
	bullet2.b_speed = bullet_speed  # pass damage to bullet
	get_tree().get_root().get_node("main/Game/Bullets").add_child(bullet2)
