extends "res://Enemies/Scripts/enemy.gd"
@onready var explosion_origin = $ExplosionSpot
@onready var explosion_indicator = $Sprite2D
@export var explosion_scene : PackedScene
@export var shot_amt = 3
@export var shot_angle = 15.0

func _transition_to(new_state: state_enum):
	state = new_state
	
	#To state
	match state:
		state_enum.MOVING:
			_pick_new_target()
		state_enum.IDLE:
			var wait_time = randf_range(min_wait_time, max_wait_time)
			timer.start(wait_time)
		state_enum.STUNNED:
			print("OW IM STUNNED")
			
			movement = false
			_change_sprite("stunned")
			timer.stop()
			shoot_timer = 0.0
		state_enum.DEAD:
			timer.stop()  # immediately stops the timer
			stun_timer.stop()
			sprite.play("dead")
			movement = false
			shoot_timer = 0
			invulnerable = true
			collision_mask |= 1 << 1  # add layer 2 (boundaries) to mask
			collision_mask &= ~(1 << 0)  # remove layer 1 (snake)
			collision_layer &= ~(1 << 4) # remove layer 5 (enemies)
			sprite.z_index = -1
			explosion_indicator.visible = true
			emit_signal("hiss", global_position)
			_flash_indicator()
			emit_signal("death", base_score, position)
			feathers.toggle_emission(true)
			_check_drops()

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == sprite_shooting_name:
		movement = true
		_change_sprite(sprite_default_name)
	elif sprite.animation == "dead": 
		var explosion = explosion_scene.instantiate()
		emit_signal("explode", global_position)
		
		explosion.snake_hit.connect(Handler.sound_effect_handler._snake_hit)
		explosion.global_position = explosion_origin.global_position
		get_tree().get_root().get_node("main/Game/Bullets").add_child(explosion)
		queue_free()

func _on_frame_changed() -> void:
	if sprite.frame == 10 and sprite.animation == sprite_shooting_name:
		emit_signal("fire", global_position)
		_shoot(Handler.snake_head.global_position, 3, 40.0)

func _flash_indicator():
	var tween = create_tween()
	tween.set_loops()  # Loop forever
	tween.tween_property(explosion_indicator, "modulate:a", 0.2, 0.1)  # Fade to full
	tween.tween_property(explosion_indicator, "modulate:a", 0.05, 0.1)  # Fade to dim
