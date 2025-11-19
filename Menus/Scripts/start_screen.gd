extends CanvasLayer

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var credits = $CenterContainer/VBoxContainer/Credits
@onready var music = $Title_Music
@onready var credits_screen = $Credits


func _ready():
	# Connect button signal
	play_button.pressed.connect(_on_play_button_pressed)
	play_button.grab_focus()

func _on_play_button_pressed():
	music.stop()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	## Hide this screen and start the game
	#queue_free()
	#self.hide()
	## Tell the main scene to start the game
	#get_tree().call_group("GameManager", "start_game")


func _on_quit_pressed() -> void:
	music.stop()
	get_tree().quit()


func _on_credits_pressed() -> void:
	credits_screen.visible
	credits_screen.show_screen()
