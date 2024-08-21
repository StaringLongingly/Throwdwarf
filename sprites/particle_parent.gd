extends Node2D

@export var DrillParticle: PackedScene
@export var DrillBreakParticle: PackedScene
@export var ParticlePosition: Vector2

func _on_animated_sprite_2d_frame_changed() -> void:
	spawn_particles(DrillBreakParticle)
	
func _on_animated_sprite_2d_drill_stays() -> void:
	spawn_particles(DrillParticle)

func spawn_particles(particleScene: PackedScene) -> void:
	var particle = particleScene.instantiate()
	add_child(particle)
	particle.emitting = true
