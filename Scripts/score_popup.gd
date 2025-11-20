extends Node2D

@onready var label = get_node("Label")
func _ready():
	label.pivot_offset = label.size / 2
	# Make it fade and float upward, then destroy itself
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 20, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
	
	
func set_text(value: String):
	if int(value) >= 2000:
		label.modulate = Color.YELLOW
	else:
		label.modulate = Color.WHITE
	label.text = value
