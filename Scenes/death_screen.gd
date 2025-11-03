extends CanvasLayer

@onready var try_again_button = $ColorRect/CenterContainer/VBoxContainer/PlayAgain
@onready var game_over_label = $ColorRect/CenterContainer/VBoxContainer/GameOverLabel
@onready var score_label = $ColorRect/CenterContainer/VBoxContainer/ScoreLabel
@onready var segments_label = $ColorRect/CenterContainer/VBoxContainer/SegmentsLabel

func _ready():
	# Connect button signal. This ONLY needs to happen once.
	# We also hide the screen by default so it's not visible on game start.
	visible = false

# This is our new function!
func show_screen(final_segments):
	# Make the screen visible
	visible = true
	$ColorRect/CenterContainer.visible = true
	
	var final_score = Handler.score_manager.curr_score if Handler.score_manager else 0
	
	if score_label:
		score_label.text = "Final Score: " + str(final_score)
	if segments_label:
		segments_label.text = "Segments: " + str(final_segments)
	
	# Optional: Pause the game
	# get_tree().paused = true


func _on_try_again_button_pressed():
	print("Play Again button was pressed!") 	
	visible = false
	get_tree().call_group("GameManager", "reset_game")
