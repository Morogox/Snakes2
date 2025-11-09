extends CanvasLayer

@onready var try_again_button = $ColorRect/CenterContainer/VBoxContainer/PlayAgain
@onready var quit_button = $ColorRect/CenterContainer/VBoxContainer/Quit
@onready var game_over_label = $ColorRect/CenterContainer/VBoxContainer/GameOverLabel
@onready var score_label = $ColorRect/CenterContainer/VBoxContainer/ScoreLabel
@onready var segments_label = $ColorRect/CenterContainer/VBoxContainer/SegmentsLabel
@onready var rect = $ColorRect
@onready var music = $"../Game_Music"

func _ready():
	# Connect button signal. This ONLY needs to happen once.
	# We also hide the screen by default so it's not visible on game start.
	visible = false

# This is our new function!
func show_screen():
	# Make the screen visible
	visible = true
	$ColorRect/CenterContainer.visible = true
	
	var final_score = Handler.score_manager.curr_score if Handler.score_manager else 0
	var final_segments = Handler.score_manager.longest_segment if Handler.score_manager else 0
	
	if score_label:
		score_label.text = "Final Score: " + str(final_score)
	if segments_label:
		segments_label.text = "Longest segment count: " + str(final_segments)
	
	rect.modulate.a = 0
	var tween = create_tween()
	var tween_music = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.5)
	tween_music.tween_property(music, "volume_db", music.volume_db - 15, 0.5)
	await tween.finished  # await completion
	
	# Optional: Pause the game
	# get_tree().paused = true


func _on_try_again_button_pressed():
	get_tree().reload_current_scene()	
	#isible = false
	#get_tree().call_group("GameManager", "reset_game")


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start_screen.tscn")
