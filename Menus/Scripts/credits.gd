extends CanvasLayer
@onready var un_credits = $ColorRect/CenterContainer/VBoxContainer/Un_credits
@onready var start_screen = $".."

func _ready():
	visible = false

func show_screen():
	# Make the screen visible
	visible = true
	$ColorRect/CenterContainer.visible = true
	un_credits.grab_focus()

func _on_un_credits_pressed() -> void:
	visible = false
	start_screen.credits.grab_focus()
