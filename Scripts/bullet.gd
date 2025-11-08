extends Area2D
@onready var tip = $Marker2D
@export var lifetime: float = 15.0   # seconds before auto-destroy

var life_timer := 0.0
@export var damage: int = 0         # placeholder, will be set by gun
@export var b_speed: float = 0.0    # placeholder, will be set by gun

var last_pos: Vector2
var velocity: Vector2
var has_hit := false
var original_rotation

var type: String

@export var impact_scene = preload("res://Scenes/bullet_impact.tscn")

@export var rotate = false

@export var force := 0.0


@export_enum("player_1", "enemy_1") var bullet_type: String = "player_1"

var hit_normal: Vector2 = Vector2.ZERO
var impact_data = {
	"player_1": {
		"sprite": preload("res://Sprites/sBullet1_impact.png"),
		"particle": preload("res://Particles/player_bullet_spark.tscn"),
		"lifetime": 0.2,
		"scale": 1.0,
		"lock_rotation": true
	},
	"enemy_1": {
		"sprite": preload("res://Sprites/sBullet_enemy1_impact.png"),
		"particle": preload("res://Particles/enemy_bullet1_spark.tscn"),
		"lifetime": 0.3,
		"scale": 2.0,
		"lock_rotation": true
	}
}

var rotate_val = 0.1
func _ready():
	original_rotation = rotation
	velocity = Vector2.RIGHT.rotated(rotation) * b_speed

func _process(delta):
	var from = global_position
	var to = from + velocity * delta
	# Build the query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = collision_mask
	query.exclude = [self]  # avoid hitting itself
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		hit_normal = result.normal 
		global_position = hit_pos
		if result.collider is Area2D:
			_on_area_entered(result.collider)
		elif result.collider is PhysicsBody2D:
			_on_body_entered(result.collider)
		return
	# No hit → just move
	global_position = to
	
	# Auto-destroy after lifetime
	life_timer += delta
	if life_timer >= lifetime:
		queue_free()
	
	rotating(rotate)

func hit_effect():
	# spawn impact effect
	rotation = original_rotation
	var impact = impact_scene.instantiate()
	impact.global_position = tip.global_position
	impact.rotation = rotation
	
	get_tree().current_scene.add_child(impact)
	impact.setup(impact_data[bullet_type], hit_normal)

func rotating(flag: bool):
	if not flag:
		return
	rotation += rotate_val
	
func _on_area_entered(area: Area2D) -> void: 
	hit_normal = get_surface_normal()

func _on_body_entered(body: Node2D) -> void:
	hit_normal = get_surface_normal()

func get_surface_normal() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position - velocity.normalized() * 50,
		global_position + velocity.normalized() * 50
	)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = collision_mask
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.normal
	else:
		return -velocity.normalized() 
