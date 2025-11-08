extends Node2D
func _ready():
	for p in get_children():
		if p is GPUParticles2D:
			p.restart()
