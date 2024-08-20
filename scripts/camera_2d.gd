extends Camera2D

# Reference to the target node (e.g., player)
@export var target: Node2D
@export var speed: float

# Offset from the target position
@export var offsetFromTarget: Vector2 = Vector2.ZERO

func _ready():
	if target:
		# Optionally set the camera to follow the target immediately
		follow_target()

func _process(_delta: float) -> void:
	if target:
		follow_target()

func follow_target():
	# Set the camera position to the target position plus the offset
	var difference := (target.position - position) * speed / 100
	position += difference
