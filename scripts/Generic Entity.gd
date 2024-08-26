extends Node2D

@export var isPlayer: bool = false
@export var enemyRarity: String
@export var hitParticles: PackedScene
@export var hpText: RichTextLabel
var cachedHPTextPosition: Vector2
@export var artifact: PackedScene
@export var hp: float = 100
@export var hpRegenRate: float = 0
@export var attackCooldown: float = 5
var splitsDirection: Array[Vector2] = [
	Vector2(1500, 200),
	Vector2(600, -600),
	Vector2(-600, -600),
	Vector2(-1500, 200)
]
var finalSplitPosition: Array[Vector2] = [
	Vector2(400, 1000),
	Vector2(200, 1000),
	Vector2(-200, 1000),
	Vector2(-400, 1000),
]
var deathAnimationDurationPart0: float = 1;
var currentDeathAnimationDurationPart0: float = 0;
var deathAnimationDurationPart1: float = 1;
var currentDeathAnimationDurationPart1: float = 0;
var deathAnimationDurationPart2: float = 0.5;
var currentDeathAnimationDurationPart2: float = 0;
var deathAnimationDurationPart3: float = 1;
var currentDeathAnimationDurationPart3: float = 0;
var splits: Array[AnimatedSprite2D] = [null, null, null, null]
var chains: Array[AnimatedSprite2D] = [null, null, null, null]
var splitsCachedPosition: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var isDying = false
var startingHP
var currentCooldown
var currentDoTduration = 0
var latestDoTdps
var cachedPosition
var splitsTo: Array[Vector2] = [
	Vector2.ZERO,
	Vector2.ZERO,
	Vector2.ZERO,
	Vector2.ZERO
]
var spawnParticlesSuper
var cachedHelmetRotation
signal lifeDrain

func _ready():
	startingHP = hp
	cachedHPTextPosition = hpText.position
	currentCooldown = attackCooldown
	var genericSprite: AnimatedSprite2D = get_node("/root/Node2D/Wall/Generic Sprite")
	var chain: AnimatedSprite2D = get_node("/root/Node2D/Wall/Chain")
	
	if isPlayer:
		genericSprite.sprite_frames = get_node("Helmet").sprite_frames
	else:
		genericSprite.sprite_frames = get_node("Enemy Sprite").sprite_frames
	for i in range(4):
		splits[i] = genericSprite.duplicate()
		splits[i].global_position = Vector2.ONE * 100000
		chains[i] = chain.duplicate()
		
		var splitsMat: ShaderMaterial = ShaderMaterial.new()
		var chainsMat: ShaderMaterial = ShaderMaterial.new()
		
		splitsMat.shader = preload("res://shaders/Quad.gdshader")
		chainsMat.shader = preload("res://shaders/Cutoff.gdshader")
		
		splitsMat.set_shader_parameter("id", i)
		chainsMat.set_shader_parameter("cutoff", 0)
		
		splits[i].material = splitsMat
		chains[i].material = chainsMat
		chains[i].material.set_shader_parameter("modulate", get_node("/root/Node2D/HUD").get_color(enemyRarity))
		
		add_child(splits[i])
		add_child(chains[i])
		
		chains[i].position = Vector2.ONE * 100000
		
		splits[i].global_scale = global_scale
		chains[i].global_scale = global_scale

func _process(delta: float) -> void:
	if isDying:
		death(delta)
		return
	if hp < startingHP:
		hp += hpRegenRate * delta
	var strHP: String = str(hp)
	if strHP.length() % 2 == 1 or strHP.length() <= 2:
		strHP += "."
	while strHP.length() <= 4:
		strHP += "0"
	var rarityColor = "[color=ff0000]"
	if not isPlayer:
		rarityColor = get_node("/root/Node2D/HUD").get_color_string(enemyRarity)
	hpText.text = "[code][center] " + rarityColor + strHP.left(4)
	if currentDoTduration > 0:
		currentDoTduration -= delta
		hp -= latestDoTdps * delta
		if hp <= 0:
			death(delta)
	if not isPlayer:
		if currentCooldown > 0:
			currentCooldown -= delta
		else:
			currentCooldown = attackCooldown
			var spawnedArtifact = artifact.instantiate()
			add_child(spawnedArtifact)
	else:
		hpText.global_position = get_node("Helmet").global_position + cachedHPTextPosition 

func take_damage(damage: float = 0, DoTdps: float = 0, DoTduration: float = 1, drainHP: float = 0):
	var particle = hitParticles.instantiate()
	add_child(particle)
	if isPlayer:
		particle.global_position = get_node("Helmet").global_position
	particle.global_scale = particle.scale
	particle.emitting = true
	
	if currentDoTduration <= 0:
		latestDoTdps = DoTdps
	currentDoTduration += DoTduration
	hp -= damage
	lifeDrain.emit(drainHP)
	if hp <= 0:
		isDying = true

func _on_generic_enemy_life_drain(hpGain: float) -> void:
	if isPlayer:
		hp += hpGain

func death(delta : float):
	if isPlayer:
		get_node("Helmet").canMove = false
		get_node("Drill & Colliders").canMove = false
	else:
		get_node("Enemy Sprite").sprite_frames = null
		get_node("Hurtbox/CollisionShape2D").disabled = true
	if isPlayer and currentDeathAnimationDurationPart0 < deathAnimationDurationPart0:
		if currentDeathAnimationDurationPart0 == 0:
			cachedHelmetRotation = get_node("Helmet").global_rotation_degrees
		currentDeathAnimationDurationPart0 += delta
		var progress = clamp(currentDeathAnimationDurationPart0 / deathAnimationDurationPart0, 0, 1)
		var progressEased = ease(progress, 2)
		var degrees = lerp(cachedHelmetRotation, 0.0, progressEased)
		get_node("Helmet").global_rotation_degrees = degrees
		
	elif currentDeathAnimationDurationPart1 < deathAnimationDurationPart1:
		if isPlayer:
			get_node("Helmet").sprite_frames = null
		currentDeathAnimationDurationPart1 += delta
		var progress = currentDeathAnimationDurationPart1 / deathAnimationDurationPart1
		hpText.scale *= 1 - progress
		for i in range(4):
			#print("Split "+str(i)+" position is: "+str(splits[i].global_position))
			splits[i].z_index = 10
			if isPlayer:
				splits[i].global_position = get_node("Helmet").global_position + splitsDirection[i] * ease(currentDeathAnimationDurationPart1, -3)
			else:
				splits[i].global_position = global_position + splitsDirection[i] * ease(currentDeathAnimationDurationPart1, -3)
			splitsCachedPosition[i] = splits[i].global_position
		
	elif currentDeathAnimationDurationPart2 == 0:
		var spawnParticlesScene = preload("res://scenes/spawn_particles.tscn")
		spawnParticlesSuper = spawnParticlesScene.instantiate()
		if isPlayer:
			get_node("Helmet").add_child(spawnParticlesSuper)
			spawnParticlesSuper.scale = Vector2(1.5, 1.1) * 1.5
		else:
			add_child(spawnParticlesSuper)
			spawnParticlesSuper.scale = Vector2(1.5, 1.1)
		spawnParticlesSuper.amount = 600 * global_scale.x
		spawnParticlesSuper.global_rotation_degrees = -90
		spawnParticlesSuper.position = Vector2(0, minimum_of_ys(finalSplitPosition) + 400 * get_parent().scale.x)
		spawnParticlesSuper.color = get_node("/root/Node2D/HUD").get_color(enemyRarity)
		spawnParticlesSuper.z_index = 20
		#print(spawnParticlesSuper.global_position)
		currentDeathAnimationDurationPart2 += delta
		for i in range(4):
			if isPlayer:
				splitsTo[i] = get_node("Helmet").global_position + finalSplitPosition[i] * global_scale.y
			else:
				splitsTo[i] = global_position + finalSplitPosition[i] * global_scale.y
			var difference = splitsTo[i] - splitsCachedPosition[i]
			chains[i].global_position = lerp(splitsCachedPosition[i], splitsTo[i], 0.5) 
			chains[i].global_scale = Vector2.ONE * difference.length() / 1000
			chains[i].global_position += Vector2.RIGHT.rotated(difference.angle()) * 1000 / 500
			chains[i].global_rotation_degrees = 270 + rad_to_deg(difference.angle())
			
	elif currentDeathAnimationDurationPart2 < deathAnimationDurationPart2:
		currentDeathAnimationDurationPart2 += delta
		var progress = clamp(currentDeathAnimationDurationPart2 / deathAnimationDurationPart2, 0, 1)
		var progressEased = ease(progress, 2)
		for i in range(4):
			chains[i].material.set_shader_parameter("cutoff", progressEased)
			
	elif currentDeathAnimationDurationPart3 < deathAnimationDurationPart3:
		currentDeathAnimationDurationPart3 += delta
		for i in range(4):
			var progress = clamp(currentDeathAnimationDurationPart3 / deathAnimationDurationPart3, 0, 1)
			var progressEased = ease(progress, 3)
			chains[i].material.set_shader_parameter("cutoff", 1 - progressEased)
			splits[i].global_position = lerp(
				splitsCachedPosition[i],
				splitsTo[i],
				progressEased)
			#print("Split "+str(i)+" position is: "+str(splits[i].global_position))
	else:
		spawnParticlesSuper.reparent(get_node("/root/Node2D"))
		spawnParticlesSuper.emitting = false
		if isPlayer:
			get_node("/root/Node2D/HUD/PauseMenu").restart_scene()
		else:
			queue_free()  # Remove the enemy if HP is 0 or below

func get_rarity() -> String:
	return enemyRarity

func minimum_of_ys(array: Array[Vector2]) -> float:
	var minimum: float = array[0].y
	for i in array.size():
		if array[i].y < minimum:
			minimum = array[i].y
	return minimum
