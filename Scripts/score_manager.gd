extends Node2D
var curr_score := 0

func _ready():
	Handler.register(name.to_snake_case(), self)
	Handler.enemy_handler.enemy_killed.connect(_enemy_score)
	Handler.item_handler.apple_eaten.connect(_apple_score)

func add(amount: int, multiplier: int):
	amount *= multiplier
	curr_score += amount
	print("Current Score: ", curr_score)

func _apple_score(score: int):
	add(score, 1)

func _enemy_score(score: int):
	add(score, Handler.snake_head.segments.size())
