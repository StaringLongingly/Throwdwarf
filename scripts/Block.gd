extends AnimatedSprite2D

@export var hp: float = 100
@export var HpLoseRate: float = 5
@export var speedGainScale = 1
@export var ScaleLoseRate: float = 0.1
@export var collider: CollisionShape2D
@onready var isBeingEntered: bool = false
@export var DrillParticleCooldown: float
var currentDrillParticleCooldown: float
var scale2: float = 1
var drillSprite
var particleParent

func _ready() -> void:
	var hue = randf()
	modulate = Color.from_hsv(hue, 1.0, 1.0, 1.0)
	drillSprite = get_node("/root/Node2D/Player/Drill & Colliders/Drill Sprite")
	particleParent = drillSprite.get_node("./Particle Parent")

func _process(delta: float) -> void:
	if (isBeingEntered):
		if (frame != 5):
			if currentDrillParticleCooldown < 0:
				currentDrillParticleCooldown = DrillParticleCooldown
				drillSprite.drill_stays()
				particleParent.drill_stays()
			else:
				currentDrillParticleCooldown -= delta
			var totalSellValue = get_node("/root/Node2D/Artifact").calculate_total_sell_value()
			# print(totalSellValue)
			var speedGain = totalSellValue * speedGainScale / 1000 
			hp -= (speedGain + 1) * HpLoseRate * delta
			
			@warning_ignore("narrowing_conversion")
			frame = 5 - hp / 25
	
	if (frame == 5):
		if (collider.disabled == false):
			get_node("/root/Node2D/Artifact").give_new_artifact()
			get_node("/root/Node2D/Wall").remove_position(global_position)
		collider.disabled = true
		scale2 -= ScaleLoseRate * delta
		scale = ease(scale2, 4.8) * Vector2.ONE;
		if (scale2 < 0):
			find_parent("*").queue_free()

func _on_area_2d_body_exited(_body: Node2D) -> void:
	if (isBeingEntered):
		drillSprite.drill_exited()
	isBeingEntered = false

func _on_area_2d_body_shape_entered(_body_rid: RID, _body: Node2D, body_shape_index: int, _local_shape_index: int) -> void:
	if (isBeingEntered):
		pass
	if (body_shape_index == 2):
		drillSprite.drill_entered()
		isBeingEntered = true
