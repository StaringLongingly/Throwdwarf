extends Node2D

@export var damage: float = 1
@export var leech: float = 0
@export var DamageOverTimeDps: float = 0
@export var DamageOverTimeDuration: float = 1
@export var weaponType: String = "bullet" # Accepted values: melee, mortar, bullet, explosion
@export var isUsedByPlayer: bool
@export var angleVariation: float = 0
@export var rotateSpeed: float = 0

var from: Vector2
var to: Vector2
var target_angle: float = 0 # For melee, bullet

@export_category("Only for melee")
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

func _ready() -> void:
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
	
	var Helmet = get_node("/root/Node2D/Player/Helmet")
	isUsedByPlayer = not get_parent().is_in_group("Enemy")
	
	# Set 'from' and 'to' positions based on whether it's used by player or enemy
	if isUsedByPlayer:
		from = Helmet.global_position
		to = get_global_mouse_position()
	else:
		from = find_parent("*").global_position
		to = Helmet.global_position
	
	# Calculate target angle with variation
	mortarProgress = 0
	target_angle = (to - from).angle()
	target_angle += (randf() * 2 - 1) * angleVariation / 360 * PI
	
	global_position = from
	rotation_degrees = rad_to_deg(target_angle) + 90
	
	if weaponType == "melee":
		position = Vector2.UP * distanceFromBody * 1000
		if not isUsedByPlayer and (to - from).length() > 2000:
			queue_free()
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
				queue_free()

func _process_mortar(delta: float) -> void:
	rotation_degrees += rotateSpeed * delta
	if mortarProgress < 1:
		mortarProgress += delta / mortarDelay
	else:
		var spawnedExplosion = explosionScene.instantiate()
		spawnedExplosion.isUsedByPlayer = isUsedByPlayer  # Pass down the property
		get_tree().root.add_child(spawnedExplosion)
		spawnedExplosion.global_position = to 
		queue_free()
	
	var progress = ease(mortarProgress, -0.5)
	var mortalProgressCos = mortarProgress * 2 - 1
	scale = cachedScale * (sqrt(1 - mortalProgressCos * mortalProgressCos) + 0.4) 
	scale.y = pow(scale.y, 2.5)
	global_position = lerp(from, to, progress)

func _process_melee(delta: float) -> void:
	var newPosDif = Vector2.UP.rotated(deg_to_rad(count)) * distanceFromBody * 1000
	if not isUsedByPlayer:
		newPosDif = newPosDif.rotated(target_angle)
		rotation_degrees = count + rad_to_deg(target_angle)
	else:
		rotation_degrees = count
	
	position = newPosDif
	var scaleMagnitude = ease((1 - abs((count - 90) / 90)), 0.4) * cachedScale.x
	scale = Vector2.ONE * scaleMagnitude
	
	if count > 180:
		queue_free()

func _on_area_2d_body_entered(body: Node) -> void:
	var groupToCheck: String = "Enemy" if isUsedByPlayer else "Player"
	
	if weaponType == "explosion":
		groupToCheck = "Player" if isUsedByPlayer else "Enemy"
	
	if body.is_in_group(groupToCheck):
		var scriptHost: Node2D = body.get_parent()
		scriptHost.take_damage(damage, DamageOverTimeDps, DamageOverTimeDuration, leech)
		if bulletPenetration == 0 and weaponType != "explosion":
			queue_free()
		else:
			bulletPenetration -= 1
