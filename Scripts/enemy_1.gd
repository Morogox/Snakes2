extends CharacterBody2D
@export var speed := 100.0
@export var min_wait_time := 2.0
@export var max_wait_time := 4.0

var target_position: Vector2
enum State_enum { IDLE, MOVING }
var state: State_enum = State_enum.IDLE
var direction := Vector2.ZERO

@onready var main := get_tree().root.get_node("main")
@onready var snake := get_tree().get_root().get_node("main/SnakeHead")
@onready var timer := $Timer
@onready var sprite = $AnimatedSprite2D


func _ready():
	randomize()
	sprite.play("default")
	
	randomize()
	_transition_to(State_enum.IDLE)

func _process(delta: float):
	var player_pos = snake.global_position
	if player_pos.x < position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true


func _physics_process(delta):
	match state:
		State_enum.MOVING:
			_process_moving(delta)
		State_enum.IDLE:
			velocity = Vector2.ZERO  # stay still

func _process_moving(delta):
	var to_target = target_position - position
	var distance = to_target.length()

	if distance < 20.0:
		#position = target_position
		_transition_to(State_enum.IDLE)
	else:
		velocity = to_target.normalized() * speed
		move_and_slide()

func _transition_to(new_state: State_enum):
	state = new_state

	match state:
		State_enum.MOVING:
			_pick_new_target()
		State_enum.IDLE:
			var wait_time = randf_range(min_wait_time, max_wait_time)
			print(wait_time)
			timer.start(wait_time)
			#print("Idle for:", wait_time)

func _on_timer_timeout() -> void:
	_transition_to(State_enum.MOVING)

func _pick_new_target():
	# Pick a random point within Main's play area
	var x = randf_range(main.left, main.right)
	var y = randf_range(main.top, main.bottom)
	target_position = Vector2(x, y)
