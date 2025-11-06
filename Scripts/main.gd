extends Node2D
@onready var top_wall = $Game/WorldBoundaries/Top
@onready var bottom_wall = $Game/WorldBoundaries/Down
@onready var left_wall = $Game/WorldBoundaries/Left
@onready var right_wall = $Game/WorldBoundaries/Right
@onready var camera = $Game/Camera2D
@onready var start_screen_scene = preload("res://scenes/start_screen.tscn")
@onready var game_started = false
@onready var death_screen = $Game/death_screen
@onready var pause_screen = $Game/pause_screen
@onready var cmd = $Game/cmd

var game_over =false
var game_paused =false
func _ready():
	reset_game()
	add_to_group("GameManager")
	#get_tree().paused = true
	#var start_screen = start_screen_scene.instantiate()
	#add_child(start_screen)
	
#func start_game():
	#game_started = true
	#get_tree().paused = false
	#print("Game started!")
	#reset_game()	
	
func reset_game():
	#for h in handlers_root.get_children():
		#handlers[h.name] = h
	Handler.grid_manager.setup(top_wall, bottom_wall, left_wall, right_wall)
	randomize()  # seed RNG
	Handler.item_handler.spawn_item_random("apple_1")
	
	# Center the camera
	camera.position = Vector2((Handler.grid_manager.left + Handler.grid_manager.right)/2, (Handler.grid_manager.top + Handler.grid_manager.bottom)/2)

	for item in Handler.item_handler.get_children():
		item.queue_free()

	## Reset the snake to its starting state
	#Handler.snake_head.call_deferred("_deferred_rdy")

	# Spawn a new apple
	Handler.item_handler.spawn_item_random("apple_1")
	
	# Reset the score
	if Handler.score_manager:
		Handler.score_manager.curr_score = 0
	
	# Unpause the game to start playing
	get_tree().paused = false

func _on_snake_died(segment_count):
	pause_screen.visible = false
	get_tree().paused = false
	death_screen.show_screen()
	game_over = true

func _input(event):
	if event.is_action_pressed("ui_cancel") and not game_over:
		game_paused = !game_paused
		pause_screen.visible = game_paused
		update_pause_state()

	if event.is_action_pressed("ui_cheat"):
		cmd.visible = !cmd.visible
		update_pause_state()

func update_pause_state():
	get_tree().paused = game_paused or cmd.visible
