extends "res://scripts/Generic Entity.gd"

@export var target: Node2D
@export var hurtbox: AnimatableBody2D
@export var moveSpeed: float = 3
@export var desiredDistance: float = 4
@export var desiredDistanceAngleVariation: float = 45
@export var repositionCooldown: float
@export var disableAI: bool
var to: Vector2
var from: Vector2
var currentRepositionCooldown: float
@export var spawnAnimationDuration: float = 2
@export var cutoffShader: Shader
@export var spawnParticlesScene: PackedScene
var spawnParticles: CPUParticles2D
var spawnAnimationProgress: float
var spriteNode: AnimatedSprite2D
var shaderMaterial
var canMove

func _ready() -> void:
	if not spawnParticles:
		cutoffShader = preload("res://shaders/Cutoff.gdshader")
	if not spawnParticlesScene:
		spawnParticlesScene = preload("res://scenes/spawn_particles.tscn")
	spawnParticles = spawnParticlesScene.instantiate()
	add_child(spawnParticles)
	
	var rarity = super.get_rarity()
	spawnParticles.color = get_node("/root/Node2D/HUD").get_color(rarity)
	shaderMaterial = ShaderMaterial.new()
	shaderMaterial.shader = cutoffShader
	
	spriteNode = get_node("Enemy Sprite")
	spriteNode.material = shaderMaterial
	spriteNode.material.set_shader_parameter("cutoff", 0)
	
	spawnAnimationProgress = 0
	target = get_node("/root/Node2D/Player/Helmet")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if isDying:
		return
	if spawnAnimationProgress < spawnAnimationDuration:
		spawnAnimationProgress += delta
		var rarity = super.get_rarity()
		spawnParticles.color = get_node("/root/Node2D/HUD").get_color(rarity)
		spriteNode.material.set_shader_parameter("cutoff", ease(clampf(spawnAnimationProgress / spawnAnimationDuration, 0, 1), 4))
		return
	else:
		spawnParticles.emitting = false
	
	if currentRepositionCooldown > 0:
		currentRepositionCooldown -= delta
		
		# Ease towards the target position `to`
		global_position = global_position.lerp(to, moveSpeed * delta)
		
		# Stop if close enough to `to` to avoid overshooting
		if global_position.distance_to(to) < 0.1:
			global_position = to
	else:
		if not disableAI:
			reposition()
	
func reposition():
	if target == null:
		print("No target")
		return

	currentRepositionCooldown = repositionCooldown
	from = global_position
	to = target.global_position
	
	# Calculate the desired position relative to the target.
	var difference: Vector2 = (from - to).normalized() * 1000 * desiredDistance
	var isValidPosition = false
	var i = 0
	while not isValidPosition:
		i += 1
		var target_angle = deg_to_rad((randf() * 2 - 1) * desiredDistanceAngleVariation)
		difference = difference.rotated(target_angle)
		isValidPosition = get_node("/root/Node2D/Wall").is_valid_enemy_position(to + difference)
		if i > 1000:
			print("Couldnt find valid position for enemy reposition")
			break
	to = to + difference  # Set `to` to the new calculated position

func take_damage(damage: float = 0, DoTdps: float = 0, DoTduration: float = 1, drainHP: float = 0):
	super.take_damage(damage, DoTdps, DoTduration, drainHP)
