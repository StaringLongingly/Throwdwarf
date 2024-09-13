extends Node2D

# Exported Variables
@export var itemRarity: String
@export var damage: float = 1
@export var leech: float = 0
@export var DamageOverTimeDps: float = 0
@export var DamageOverTimeDuration: float = 1
@export var weaponType: String = "bullet" # Accepted values: melee, mortar, bullet, explosion
@export var isUsedByPlayer: bool
@export var angleVariation: float = 0
@export var rotateSpeed: float = 0

# Export Categories
@export_category("Only for melee")
@export var isRotating: bool = true
@export var distanceFromBody: float = 2

@export_category("Only for bullet")
@export var bulletSpeed: float = 10
@export var bulletPenetration: int = 0

@export_category("Only for mortar")
@export var mortarDelay: float = 1
@export var explosionScene: PackedScene

@export_category("Only for Explosion")
@export var animationDuration: float

# Internal Variables
var gotParried: bool = false
var previousArtifactScene: PackedScene
var artifactName: String

var from: Vector2
var to: Vector2
var target_angle: float = 0

var animationProgress: float = 0
var mortarProgress: float = 0
var cachedScale: Vector2
var cachedPos: Vector2

var trail: Node2D
var helmet: Node2D

var isBulletMoving: bool = true
var count: float = 0.0

# Constants
const MELEE = "melee"
const MORTAR = "mortar"
const BULLET = "bullet"
const EXPLOSION = "explosion"

func _ready() -> void:
	# Initialize artifact name
	artifactName = name
	print(artifactName)
	
	# Cache essential nodes
	helmet = get_node("/root/Node2D/Player/Helmet")
	
	# Instantiate and configure trail
	trail = preload("res://scenes/Item Trail.tscn").instantiate()
	var rarityColor: Color = get_node("/root/Node2D/HUD").get_color(itemRarity)
	trail.get_node("CPUParticles2D").color = Color(rarityColor, 0.5)
	add_child(trail)
	trail.position = Vector2.ZERO
	
	# Cache initial scale and position
	cachedScale = scale
	cachedPos = position
	
	# Setup based on weapon type
	match weaponType:
		MELEE:
			scale = Vector2.ZERO
			position = Vector2.ONE * 10000000
		EXPLOSION:
			get_node("Explosion Particles").emitting = true
	
	# Determine if used by player and set positions
	isUsedByPlayer = not get_parent().is_in_group("Enemy")
	set_from_to_positions(isUsedByPlayer)
	
	# Calculate target angle with variation
	target_angle = (to - from).angle()
	target_angle += (randf() * 2 - 1) * angleVariation / 360 * PI
	
	# Initialize position and rotation and scale
	global_scale = cachedScale
	global_position = from
	rotation_degrees = rad_to_deg(target_angle) + 90
	
	if weaponType == MELEE:
		position = Vector2.UP * distanceFromBody * 1000
	else:
		reparent(get_node("/root"))
		rotation_degrees = rad_to_deg(target_angle) + 90

func _process(delta: float) -> void:
	count += rotateSpeed * delta
	match weaponType:
		BULLET:
			_process_bullet(delta)
		MORTAR:
			_process_mortar(delta)
		MELEE:
			_process_melee(delta)
		EXPLOSION:
			_process_explosion()

func _process_bullet(delta: float) -> void:
	rotation_degrees += rotateSpeed * delta
	if isBulletMoving:
		var direction = Vector2.RIGHT.rotated(target_angle)
		global_position += direction * bulletSpeed * 1000 * delta

func _process_mortar(delta: float) -> void:
	rotation_degrees += rotateSpeed * delta
	mortarProgress += delta / mortarDelay
	
	if mortarProgress >= 1:
		_spawn_explosion()
		return
	
	# Update scale and position with easing
	var progress = ease(mortarProgress, -0.5)
	var mortalProgressCos = mortarProgress * 2 - 1
	scale = cachedScale * (sqrt(1 - mortalProgressCos * mortalProgressCos) + 0.4)
	scale.y = pow(scale.y, 2.5)
	global_position = lerp(from, to, progress)

func _spawn_explosion() -> void:
	var spawnedExplosion = explosionScene.instantiate()
	spawnedExplosion.isUsedByPlayer = isUsedByPlayer
	get_tree().root.add_child(spawnedExplosion)
	spawnedExplosion.global_position = to
	destroy()

func _process_melee(delta: float) -> void:
	var newPosDif = Vector2.UP.rotated(deg_to_rad(count)) * distanceFromBody * 1000
	
	if not isUsedByPlayer:
		newPosDif = newPosDif.rotated(target_angle)
		if isRotating:
			rotation_degrees = count + rad_to_deg(target_angle)
		else:
			if count > 90 and scale.y > 0:
				scale.y *= -1
			rotation_degrees = 0
	else:
		if isRotating:
			rotation_degrees = count
		else:
			rotation_degrees = 0
	
	position = newPosDif
	var scaleMagnitude = ease((1 - abs((count - 90) / 90)), 0.4) * cachedScale.x
	scale = Vector2.ONE * scaleMagnitude
	
	if count > 180:
		destroy()

func _process_explosion() -> void:
	if not get_node("Explosion Particles").emitting:
		destroy()

func _on_area_2d_body_entered(body: Node) -> void:
	var groupToCheck: String = "Enemy" if isUsedByPlayer else "Player"
	
	if weaponType == EXPLOSION:
		groupToCheck = "Player" if isUsedByPlayer else "Enemy"
	
	if body.is_in_group("Parry") and not gotParried and not is_in_group("Parry"):
		_handle_parry()
	elif body.is_in_group(groupToCheck):
		_handle_damage(body, groupToCheck)
	# No action for other cases

func _handle_parry() -> void:
	gotParried = true
	var artifactPath = "res://artifacts/scenes/%s.tscn" % artifactName
	print("Parried artifact: " + artifactPath)
	
	var artifactScene: PackedScene = load(artifactPath)
	var newArtifact = artifactScene.instantiate()
	
	# Modify artifact properties
	newArtifact.angleVariation += 20
	newArtifact.bulletSpeed *= 2
	newArtifact.DamageOverTimeDps /= 2
	newArtifact.damage /= 2
	
	# Attach to helmet
	helmet.add_child(newArtifact)
	newArtifact.global_position = global_position
	destroy()

func _handle_damage(body: Node, groupToCheck: String) -> void:
	var scriptHost: Node2D = body.get_parent()
	scriptHost.take_damage(damage, DamageOverTimeDps, DamageOverTimeDuration, leech)
	
	if bulletPenetration == 0 and weaponType != EXPLOSION:
		destroy()
	else:
		bulletPenetration -= 1

func destroy() -> void:
	# Detach and stop trail particles
	trail.reparent(get_node("/root/Node2D"))
	trail.get_node("CPUParticles2D").emitting = false
	queue_free()

func set_from_to_positions(is_player: bool) -> void:
	if is_player:
		from = helmet.global_position
		to = get_global_mouse_position()
	else:
		from = get_parent().global_position
		to = helmet.global_position
