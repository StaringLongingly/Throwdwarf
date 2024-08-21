extends CharacterBody2D

# Use a different name to avoid conflict with the built-in `velocity`
var custom_velocity = Vector2.ZERO
@export var speed = 2000
@export var rotation_speed = 5.0  # Controls the speed of rotation towards the mouse

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	custom_velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		custom_velocity.y -= 1
	if Input.is_action_pressed("ui_down"):
		custom_velocity.y += 1
	if Input.is_action_pressed("ui_left"):
		custom_velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		custom_velocity.x += 1
	
	# Calculate the target angle towards the mouse position
	var target_direction = (get_global_mouse_position() - global_position).angle()
	
	# Interpolate current rotation towards the target direction
	rotation = lerp_angle(rotation, target_direction, rotation_speed * _delta)
	
	if custom_velocity.length() > 0:
		custom_velocity = custom_velocity.normalized() * speed * 1000
		
	# Set the velocity property of CharacterBody2D
	velocity = custom_velocity  # Use the built-in velocity property
	move_and_slide()  # No arguments needed, `velocity` is used internally
