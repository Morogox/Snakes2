extends Node2D
var curr_score := 0
@onready var score_popup_scene = preload("res://Scenes/score_popup.tscn")
signal score_changed(val : int)

func _ready():
	Handler.register(name.to_snake_case(), self)
	Handler.enemy_handler.enemy_killed.connect(_enemy_score)
	Handler.item_handler.apple_eaten.connect(_apple_score)

func add(amount: int, multiplier: int, loc: Vector2):
	if multiplier <= 0:
		multiplier = 1
	amount *= multiplier
	curr_score += amount
	spawn_score_label(amount, loc)
	print("Current Score: ", curr_score)
	emit_signal("score_changed", curr_score)

func _apple_score(score: int, loc: Vector2):
	add(score, Handler.snake_head.segments.size(), loc)

func _enemy_score(score: int, loc: Vector2):
	add(score, Handler.snake_head.segments.size(),loc)

func spawn_score_label(value: int, pos: Vector2):
	print(pos)
	var popup = score_popup_scene.instantiate()
	popup.position = pos
	get_tree().get_root().get_node("main").add_child(popup)
	
	popup.set_text(str(value))
	
