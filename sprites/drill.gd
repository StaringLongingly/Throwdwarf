extends AnimatedSprite2D

func _on_animated_sprite_2d_drill_entered() -> void:
	play()

func _on_animated_sprite_2d_drill_exited() -> void:
	pause()

func _on_animated_sprite_2d_drill_stays() -> void:
	play()
