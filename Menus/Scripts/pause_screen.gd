extends CanvasLayer
@onready var continue_button = $ColorRect/CenterContainer/VBoxContainer/Continue
@onready var quit_button = $ColorRect/CenterContainer/VBoxContainer/Quit
@onready var pause_label = $ColorRect/CenterContainer/VBoxContainer/PauseLabel
@onready var score_label = $ColorRect/CenterContainer/VBoxContainer/ScoreLabel

@onready var main = $"../.."

func _ready():
	visible = false
	continue_button.grab_focus()

func show_screen():
	# Make the screen visible
	get_tree().paused = true
	visible = true
	$ColorRect/CenterContainer.visible = true
	continue_button.grab_focus()
	#continue_button.focus_pls()
	
	var curr_score = Handler.score_manager.curr_score if Handler.score_manager else 0
	
	if score_label:
		score_label.text = "Current Score: " + str(curr_score)

func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	
	main.game_paused = !main.game_paused
	main.pause_screen.visible = main.game_paused
	main.update_pause_state()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://Menus/Scenes/start_screen.tscn")
