extends Node2D
@export var lifetime := 0.05  # seconds
@export var particle_effect = PackedScene
@onready var sprite = $Sprite2D
@onready var particle_origin = $Marker2D
@export var lock_rotation = false

func _ready():
	# auto-destroy after a short time
	#rotation += randf_range(-0.2, 0.2)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	
	
	
func setup(type: Dictionary, normal : Vector2):
	lifetime = type["lifetime"]
	particle_effect = type["particle"]
	sprite.texture = type["sprite"]
	scale = Vector2(type["scale"], type["scale"])
	lock_rotation = type["lock_rotation"]
	if lock_rotation:
		rotation = normal.angle() + PI
	
	particle_origin.position.x += sprite.texture.get_width()/2
	var explosion_instance = particle_effect.instantiate()
	explosion_instance.global_position = particle_origin.global_position
	explosion_instance.global_rotation = rotation
	explosion_instance.toggle_emission(true)
	get_tree().current_scene.add_child(explosion_instance)
