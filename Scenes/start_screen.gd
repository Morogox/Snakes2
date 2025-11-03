extends CanvasLayer

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel

func _ready():
	# Make sure the screen is visible
	visible = true
	# Connect button signal
	play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed():
	# Hide this screen and start the game
	queue_free()
	self.hide()
	# Tell the main scene to start the game
	get_tree().call_group("GameManager", "start_game")
