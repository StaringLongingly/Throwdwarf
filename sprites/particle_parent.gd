extends Node2D

@export var DrillParticle: PackedScene
@export var DrillBreakParticle: PackedScene
@export var ParticlePosition: Vector2

func frame_changed() -> void:
	spawn_particles(DrillBreakParticle)
	
func drill_stays() -> void:
	spawn_particles(DrillParticle)

func spawn_particles(particleScene: PackedScene) -> void:
	var particle = particleScene.instantiate()
	add_child(particle)
	particle.emitting = true
