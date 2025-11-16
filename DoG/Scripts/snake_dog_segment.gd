extends "res://Scripts/snake_segment.gd"

func _ready():
	super()
	call_deferred("_deferred_rdy")
	end_sprite = preload("res://DoG/Sprites/The_Devourer_of_Gods_Final_Phase_Tail.png")
