extends Node2D

@export var itemRarity: String
@export var damage: float = 1
@export var leech: float = 0
@export var DamageOverTimeDps: float = 0
@export var DamageOverTimeDuration: float = 1
@export var weaponType: String = "bullet" # Accepted values: melee, mortar, bullet, explosion
@export var isUsedByPlayer: bool
@export var angleVariation: float = 0
@export var rotateSpeed: float = 0
var gotParried: bool = false
var previousArtifactScene: PackedScene
var artifactName: String

var from: Vector2
var to: Vector2
var target_angle: float = 0 # For melee, bullet

@export_category("Only for melee")
@export var isRotating: bool = true
@export var distanceFromBody: float = 2

@export_category("Only for bullet")
@export var bulletSpeed: float = 10
@export var bulletPenetration: int = 0
var isBulletMoving: bool = true

@export_category("Only for mortar")
@export var mortarDelay: float = 1
@export var explosionScene: PackedScene

@export_category("Only for Explosion")
@export var animationDuration: float
var animationProgress: float = 0

var mortarProgress: float = 0
var cachedScale
var cachedPos

var trail: Node2D
var helmet: Node2D

func _ready() -> void:
	artifactName = self.name
	print(artifactName)
	helmet = get_node("/root/Node2D/Player/Helmet")
	var trailScene: PackedScene = preload("res://scenes/Item Trail.tscn")
	trail = trailScene.instantiate()
	var rarityColor: Color = get_node("/root/Node2D/HUD").get_color(itemRarity)
	trail.get_node("CPUParticles2D").color = Color(rarityColor, 0.5)
	add_child(trail)
	trail.position = Vector2.ZERO
	
	# Cache initial scale and position
	global_scale = scale
	cachedPos = position
	cachedScale = scale
	
	# Handle initial setup based on weapon type
	match weaponType:
		"melee":
			scale = Vector2.ZERO
			position = Vector2.ONE * 10000000
		"explosion":
			get_node("Explosion Particles").emitting = true
	
	isUsedByPlayer = not get_parent().is_in_group("Enemy")
	get_to_from(isUsedByPlayer)
	
	# Set 'from' and 'to' positions based on whether it's used by player or enemy
	
	# Calculate target angle with variation
	mortarProgress = 0
	target_angle = (to - from).angle()
	target_angle += (randf() * 2 - 1) * angleVariation / 360 * PI
	
	global_position = from
	rotation_degrees = rad_to_deg(target_angle) + 90
	if weaponType == "melee":
		position = Vector2.UP * distanceFromBody * 1000
	else:
		reparent(get_node("/root"))
		rotation_degrees = rad_to_deg(target_angle) + 90

var count = 0

func _process(delta: float) -> void:
	count += rotateSpeed * delta
	match weaponType:
		"bullet":
			rotation_degrees += rotateSpeed * delta
			if isBulletMoving:
				global_position += Vector2(1, 0).rotated(target_angle) * bulletSpeed * 1000 * delta
		"mortar":
			_process_mortar(delta)
		"melee":
			_process_melee(delta)
		"explosion":
			if not get_node("Explosion Particles").emitting:
				destroy()

func _process_mortar(delta: float) -> void:
	rotation_degrees += rotateSpeed * delta
	if mortarProgress < 1:
		mortarProgress += delta / mortarDelay
	else:
		var spawnedExplosion = explosionScene.instantiate()
		spawnedExplosion.isUsedByPlayer = isUsedByPlayer  # Pass down the property
		get_tree().root.add_child(spawnedExplosion)
		spawnedExplosion.global_position = to 
		destroy()
	
	var progress = ease(mortarProgress, -0.5)
	var mortalProgressCos = mortarProgress * 2 - 1
	scale = cachedScale * (sqrt(1 - mortalProgressCos * mortalProgressCos) + 0.4) 
	scale.y = pow(scale.y, 2.5)
	global_position = lerp(from, to, progress)

func _process_melee(_delta: float) -> void:
	var newPosDif = Vector2.UP.rotated(deg_to_rad(count)) * distanceFromBody * 1000
	if not isUsedByPlayer:
		newPosDif = newPosDif.rotated(target_angle)
		if isRotating:
			rotation_degrees = count + rad_to_deg(target_angle)
		else:
			if count > 90 and scale.y > 0:
				scale.y *= -1
			rotation_degrees = 0
	else :
		if isRotating:
			rotation_degrees = count
		else:
			rotation_degrees = 0
	
	position = newPosDif
	var scaleMagnitude = ease((1 - abs((count - 90) / 90)), 0.4) * cachedScale.x
	scale = Vector2.ONE * scaleMagnitude
	
	if count > 180:
		destroy()

func _on_area_2d_body_entered(body: Node) -> void:
	var groupToCheck: String = "Enemy" if isUsedByPlayer else "Player"
	if weaponType == "explosion":
		groupToCheck = "Player" if isUsedByPlayer else "Enemy"
		
	if body.is_in_group("Parry") and not gotParried and not is_in_group("Parry"):
		gotParried = true
		var self2: Node2D = self
		var artifactString: String = "res://artifacts/scenes/" + artifactName + ".tscn"
		print("Parried artifact: " + artifactString)
		var artifactScene: PackedScene = load(artifactString)
		var newArtifact = artifactScene.instantiate()
		newArtifact.angleVariation += 20
		newArtifact.bulletSpeed *= 2
		newArtifact.DamageOverTimeDps /= 2 
		newArtifact.damage /= 2

		helmet.add_child(newArtifact)
		newArtifact.global_position = global_position
		destroy()
	elif body.is_in_group(groupToCheck):
		var scriptHost: Node2D = body.get_parent()
		scriptHost.take_damage(damage, DamageOverTimeDps, DamageOverTimeDuration, leech)
		if bulletPenetration == 0 and weaponType != "explosion":
			destroy()
		else:
			bulletPenetration -= 1
	else:
		pass

func destroy():
	trail.reparent(get_node("/root/Node2D"))
	trail.get_node("CPUParticles2D").emitting = false
	queue_free()

func get_to_from(isUsedByPlayer: bool):
	if isUsedByPlayer:
		from = helmet.global_position
		to = get_global_mouse_position()
	else:
		from = get_parent().global_position
		to = helmet.global_position
