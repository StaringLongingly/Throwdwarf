extends AnimatedSprite2D 

@export var target: Node2D
@export var rotationSpeed: float
@export var canMove: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target and canMove:
		follow_target(delta)	

func follow_target(delta: float):
	position = target.position
	var target_direction = (get_global_mouse_position() - global_position).angle() + deg_to_rad(-90)
	rotation = lerp_angle(rotation, target_direction, rotationSpeed * delta)
