extends CanvasLayer

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var credits = $CenterContainer/VBoxContainer/Credits
@onready var music = $Title_Music
@onready var credits_screen = $Credits
@onready var how_to_btn = $CenterContainer/VBoxContainer/HowTo
@onready var how_to = $HowTo
@onready var title = $TextureRect
var time_passed = 0.0
func _ready():
	# Connect button signal
	play_button.pressed.connect(_on_play_button_pressed)
	play_button.grab_focus()

func _process(delta):
	time_passed += delta

	# Bobbing motion
	var bounce_amount = 30.0  # How many pixels to move
	var bounce_speed = 2.0    # How fast it bounces

	title.position.y = title.position.y + sin(time_passed * bounce_speed) * bounce_amount * delta
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


func _on_how_to_pressed() -> void:
	how_to.visible
	how_to.show_screen()
