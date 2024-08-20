extends AnimatedSprite2D
signal getSellvalue

@export var hp: float = 100
@export var HpLoseRate: float = 5
@export var ScaleLoseRate: float = 0.1
@export var collider: CollisionShape2D
@onready var isBeingEntered: bool = false
var scale2: float = 1

signal drillEntered
signal drillStays
signal drillExited
signal giveArtifact

func _ready() -> void:
	var hue = randf()
	modulate = Color.from_hsv(hue, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	if (isBeingEntered):
		if (frame != 5):
			drillStays.emit()
			var totalSellValue = get_node("/root/Node2D/Artifact").calculate_total_sell_value()
			print(totalSellValue)
			var speedGain = totalSellValue / 500 
			hp -= (speedGain + 1) * HpLoseRate * delta
			
			@warning_ignore("narrowing_conversion")
			frame = 5 - hp / 25
	
	if (frame == 5):
		if (collider.disabled == false):
			giveArtifact.emit()
		collider.disabled = true
		scale2 -= ScaleLoseRate * delta 
		scale = ease(scale2, 4.8) * Vector2.ONE;
		if (scale2 < 0):
			find_parent("*").queue_free()

func _on_area_2d_body_exited(_body: Node2D) -> void:
	if (isBeingEntered):
		drillExited.emit()
	isBeingEntered = false

func _on_area_2d_body_shape_entered(_body_rid: RID, _body: Node2D, body_shape_index: int, _local_shape_index: int) -> void:
	if (isBeingEntered):
		pass
	if (body_shape_index == 2):
		drillEntered.emit()
		isBeingEntered = true
