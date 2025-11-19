extends CanvasLayer
@onready var un_credits = $ColorRect/CenterContainer/VBoxContainer/Un_credits
@onready var start_screen = $".."

@onready var DoG_1 = $ColorRect/CenterContainer/VBoxContainer/DoG_credits
@onready var DoG_2 = $ColorRect/CenterContainer/VBoxContainer/Hint
@onready var stop_fading = false


func _ready():
	visible = false

func show_screen():
	# Make the screen visible
	visible = true
	$ColorRect/CenterContainer.visible = true
	un_credits.grab_focus()
	
	_DoG_fade_in()

func _on_un_credits_pressed() -> void:
	visible = false
	start_screen.credits.grab_focus()
	
	_DoG_pop_out()

func _DoG_fade_in():
	stop_fading = false
	DoG_1.modulate = Color(1, 1, 1, 0)
	DoG_1.visible = true
	DoG_2.modulate = Color(1, 1, 1, 0)
	DoG_2.visible = true
	await get_tree().create_timer(2).timeout or stop_fading
	var opacity = 0
	while opacity < 1.002:
		if stop_fading:
			opacity == 1.002
			stop_fading = false
			break
		DoG_1.modulate = Color(1, 1, 1, opacity)
		DoG_2.modulate = Color(1, 1, 1, opacity)
		opacity += 0.002
		await get_tree().create_timer(0.001).timeout
		


func _DoG_pop_out():
	DoG_1.modulate = Color(0, 0, 0, 0)
	DoG_1.visible = false
	DoG_2.modulate = Color(0, 0, 0, 0)
	DoG_2.visible = false
	stop_fading = true
