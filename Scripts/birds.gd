extends Area2D

# Lots of code here is just copied from the snake_head, will be useful when we want to make the birds move
# Especially if they're supposed to be intelligent

#@onready var main = get_parent()
#@onready var snake = $SnakeHead
#@onready var grid_size = main.GRID_SIZE
#@onready var CELL_OFFSET = main.CELL_OFFSET

#@export var move_delay = 0.15 # Could be useful when they move

#var snake_pos_on_spawn = snake.snake_pos
#var snake_direction = snake.direction
#var snake_target = snake.target_pixel_pos
# A good enemy is an informed enemy! But it breaks if done up here
# Probably because the birds spawn on spawn and the snake lags behind or something

#@export var world_size := Vector2(1024, 1024) # match WorldBoundaries

@export var min_type: int = 0
@export var max_type: int = 1
@export var type: int = -1

@onready var sprite = $AnimatedSprite2D

#var bird_pos = Vector2.ZERO   # grid coordinates
#var direction = Vector2.RIGHT   
#var prev_pixel_pos = Vector2.ZERO
#var target_pixel_pos = Vector2.ZERO

#const DIR_ROTATIONS = {
	#Vector2.RIGHT: 0,
	#Vector2.LEFT: PI,
	#Vector2.UP: -PI/2,
	#Vector2.DOWN: PI/2
#}

#var move_timer = move_delay

func _ready():
	call_deferred("randomize_type") # Into the trenches you go little blue/red bird
	# In this world you cannot choose what you're born as
	# ...but you can choose what you become

func _process(delta: float) -> void:
	pass # For now they sit, soon they'll run

func randomize_type():
	type = randi_range(min_type, max_type) # Min and Max allow for changing what types can spawn, meaning more advanced ones could be later and simple removed
	# That said, might need a different system if spawning is to be set amounts of a type
	sprite.play("Bird"+str(type))
	# The current idle animation's Bird0 or Bird1, this works
	# And it should work even if each type will have more than 1 animation
	# ((they will, at LEAST: Walk, shoot, and possibly die))
