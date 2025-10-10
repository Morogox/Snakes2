extends Area2D
@onready var tip = $Marker2D
@export var lifetime: float = 2.0   # seconds before auto-destroy

var life_timer := 0.0
var damage: int = 0          # placeholder, will be set by gun
var b_speed: float = 0.0    # placeholder, will be set by gun

var last_pos: Vector2
var velocity: Vector2
func _ready():
	velocity = Vector2.RIGHT.rotated(rotation) * b_speed

func _process(delta):
	var from = global_position
	var to = from + velocity * delta
	# Build the query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]  # avoid hitting itself
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		global_position = hit_pos
		_on_Bullet_body_entered(result.collider)

		return
	# No hit → just move
	global_position = to
	
	# Auto-destroy after lifetime
	life_timer += delta
	if life_timer >= lifetime:
		queue_free()
	
func hit_effect():
	# spawn impact effect
	var impact = preload("res://Scenes/bullet_player_impact.tscn").instantiate()
	impact.global_position = get_node("Marker2D").global_position
	impact.global_rotation = global_rotation
	get_tree().current_scene.add_child(impact)

func _on_Bullet_body_entered(body):
	if life_timer > 0.1:
		if body.is_in_group("Segments"):
			#place holder
			print("called")
			hit_effect()
		if body.is_in_group("Boundaries"):
			hit_effect()
		queue_free()
