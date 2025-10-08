extends Camera2D
var shake_strength: float = 0.0
var shake_decay: float = 0.0  # how fast the shake fades
var original_offset := Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta):
	if shake_strength > 0:
		offset = original_offset + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	else:
		offset = original_offset

func shake(intensity: float = 5.0, decay: float = 5.0):
	shake_strength = intensity
	shake_decay = decay
