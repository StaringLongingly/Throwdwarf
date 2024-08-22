extends Node2D

@export var damage: float = 1
@export var leech: float = 0
@export var DamageOverTimeDps: float = 0
@export var DamageOverTimeDuration: float = 1
# Accepted values: melee, mortar, bullet
@export var weaponType: String = "bullet"
# true for player item, false for enemy item
@export var isUsedByPlayer: bool = true
@export var angleVariation: float = 0
@export var rotateSpeed: float = 0
var from: Vector2
var to: Vector2

# for melee, bullet
var target_angle: float = 0
#only for melee
@export var distanceFromBody: float = 2
#only for bullet
@export var bulletSpeed: float = 10
@export var bulletPenetration: int = 0
var isBulletMoving: bool = true
#only for mortar
@export var mortarDelay: float = 1
var mortarProgress: float = 0
var mortarFinalPosition: Vector2
var cachedScale
var cachedPos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_scale = scale
	cachedPos = position
	cachedScale = scale
	if weaponType == "melee":
		position = Vector2.ONE * 10000000
		scale = Vector2.ZERO
	var Helmet = get_node("/root/Node2D/Player/Helmet")
	# if get_parent().is_in_group("Player"):
	# print("Artifact spawned by player")
	# elif get_parent().is_in_group("Enemy"):
	# print("Artifact spawned by enemy")
	# else:
	# print("Artifact spawned by unknown " + get_parent().name)
	isUsedByPlayer = !get_parent().is_in_group("Enemy")
	
	if isUsedByPlayer:
		from = Helmet.global_position
		to = get_global_mouse_position()
	else:
		from = find_parent("*").global_position
		to = Helmet.global_position
	# print("Launching Projectile:")
	# print("    from: " + str(from.x).left(7) + ", "+ str(from.y).left(7))
	# print("      to: " + str(to.x).left(7) + ", "+ str(to.y).left(7))
	
	mortarProgress = 0
	target_angle = (to - from).angle()
	target_angle += (randf() * 2 - 1) * angleVariation / 360 * PI
	global_position = from
	rotation_degrees = rad_to_deg(target_angle) + 90
	if weaponType == "melee":
		position = Vector2.UP * distanceFromBody * 1000 
		if (to - from).length() > 2000:
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
			rotation_degrees += rotateSpeed * delta
			if mortarProgress < 1:
				mortarProgress += delta / mortarDelay
			scale = cachedScale * ease3(mortarProgress)
			global_position = lerp(from, to, ease3(mortarProgress))
		"melee":
			var newPosDif = Vector2.UP.rotated(deg_to_rad(count)) * distanceFromBody * 1000
			if !isUsedByPlayer:
				newPosDif = newPosDif.rotated(target_angle)
				rotation_degrees = count + rad_to_deg(target_angle)
			else:
				rotation_degrees = count
			position = newPosDif
			var scaleMagnitude = ease((1 - abs((count - 90) / 90)), 0.4) * cachedScale.x
			# print(str(scaleMagnitude) + ", " + str(count))
			scale = Vector2.ONE * scaleMagnitude
			if count > 180:
				queue_free()

# Called when the node enters the area
func _on_area_2d_body_entered(body):
	# print("Projectile collided with " + body.name)
	var groupToCheck: String
	if isUsedByPlayer:
		groupToCheck = "Enemy"
	else:
		groupToCheck = "Player"
		
	if body.is_in_group(groupToCheck):  # Make sure to add enemies to an "enemies" group
		var scriptHost: Node2D = body.get_parent()
		scriptHost.take_damage(damage, DamageOverTimeDps, DamageOverTimeDuration, leech)
		# print("Hit Enemy")
		if bulletPenetration == 0:
			queue_free()  # Remove the projectile after hitting an enemy (optional)
		else:
			bulletPenetration -= 1
	else:
		pass
		# print("Bullet collided with group: " + str(body.get_groups()))

func ease2(t: float) -> float:
	if t <= 0.5:
		return ease((1-t) * 2, 4.8)
	else:
		return ease(t * 2, 4.8)

func ease3(t: float) -> float:
	if t <= 0.5:
		return ease(1-ease((1-t), 4.8), 2) / 2
	else:
		return ease(ease(t, 4.8), 2) / 2 + 0.5
