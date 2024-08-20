extends Sprite2D

@export var target: Node2D
@export var speed: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target:
		follow_target(delta)	

func follow_target(delta: float):
	position = target.position
	
	# Apply a 90-degree offset to the target's rotation
	var target_rotation_offset: float = target.rotation_degrees - 90
	
	var differenceUnscaled: float = target_rotation_offset - rotation_degrees
	
	# Normalize the difference to the range [-180, 180]
	differenceUnscaled = fmod((differenceUnscaled + 180), 360) - 180
	
	var difference: float = differenceUnscaled * speed * delta
	
	# Apply the rotation difference
	rotation_degrees += difference
