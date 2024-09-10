extends Node2D

@export var cooldown = 1
var currentCooldown = 0
@export var animationDuration = 0.5
var currentAnimationDuration = 0

func _ready() -> void:
	get_node("Rectangle").material.set_shader_parameter("progress", 1)
	currentCooldown = cooldown
	currentAnimationDuration = animationDuration

func _process(delta: float) -> void:
	if currentAnimationDuration < animationDuration:
		currentAnimationDuration += delta
		var progress = clamp(currentAnimationDuration / animationDuration, 0, 1)
		var progressEased = ease(1.0 - progress, 2)
		get_node("Rectangle").material.set_shader_parameter("progress", progressEased)
	elif currentCooldown < cooldown:
		currentCooldown += delta
		var progress = clamp(currentCooldown / cooldown, 0, 1)
		get_node("Rectangle").material.set_shader_parameter("progress", progress)

func reset():
	currentCooldown = 0
	currentAnimationDuration = 0

func is_ready() -> bool:
	return currentCooldown >= cooldown
