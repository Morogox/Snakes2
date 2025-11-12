extends CanvasLayer

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var music = $Title_Music

func _ready():
	# Connect button signal
	play_button.pressed.connect(_on_play_button_pressed)

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
