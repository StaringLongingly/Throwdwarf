extends AnimatedSprite2D

func drill_entered() -> void:
	play()

func drill_exited() -> void:
	pause()

func drill_stays() -> void:
	play()
