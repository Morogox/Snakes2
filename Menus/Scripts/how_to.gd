extends CanvasLayer
@onready var exit = $ColorRect/exit
@onready var start_screen = $".."

@onready var stop_fading = false

func show_screen():
	# Make the screen visible
	visible = true
	$ColorRect/CenterContainer.visible = true
	exit.grab_focus()


func _on_un_credits_pressed() -> void:
	visible = false
	start_screen.how_to_btn.grab_focus()
	
