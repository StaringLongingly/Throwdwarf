extends CPUParticles2D

func _process(_delta):
	if not self.emitting:
		queue_free()
