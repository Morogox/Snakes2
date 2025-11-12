extends Node2D

func _ready():
	pass
	#for p in get_children():
		#if p is GPUParticles2D:
			#p.restart()

func toggle_emission(flag: bool):
	for p in get_children():
		if p is GPUParticles2D:
			p.emitting = flag
