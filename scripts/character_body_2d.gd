extends CharacterBody2D

@export_category("Basic Movement")
@export var speed = 2
@export var rotation_speed = 5.0  # Controls the speed of rotation towards the mouse
@export var canMove: bool = true
var target_direction 

@export_category("Dashing")
@export var dashCost: int = 3
@export var dashDuration: float = 1 
var currectDashDuration: float = dashDuration 
@export var dashSpeedScalar: float = 5
var isDashing: bool
var dashTrail
@export_category("Death Animation")
var cachedDrillScale: Vector2
@export var shrinkAnimationDuration: float 
var currentShrinkAnimationDuration: float = 0

func _ready() -> void:
	cachedDrillScale = get_node("Drill Sprite").scale
	var trail= preload("res://scenes/Item Trail.tscn")
	dashTrail = trail.instantiate()
	dashTrail.get_node("CPUParticles2D").color = Color.WHITE
	add_child(dashTrail)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not canMove:
		if currentShrinkAnimationDuration < shrinkAnimationDuration:
			currentShrinkAnimationDuration += delta
			var progress = clamp(currentShrinkAnimationDuration/shrinkAnimationDuration, 0, 1)
			var progressEased = ease(progress, 2)
			get_node("Drill Sprite").scale = lerp(cachedDrillScale, Vector2.ZERO, progressEased)
	else:	
		var custom_velocity = Vector2.ZERO
	
		if Input.is_action_pressed("ui_up"):
			custom_velocity.y -= 1
		if Input.is_action_pressed("ui_down"):
			custom_velocity.y += 1
		if Input.is_action_pressed("ui_left"):
			custom_velocity.x -= 1
		if Input.is_action_pressed("ui_right"):
			custom_velocity.x += 1
		
		if Input.is_action_just_pressed("Dash"):
			var canDash: bool = get_node("/root/Node2D/Artifact").remove_least_valuables(dashCost)
			if canDash:
				# print("Dashing..")
				currectDashDuration = 0
			else:
				pass
				# print("Not Enough Artifacts for a Dash!")
	
		# Calculate the target angle towards the mouse position
		if not Input.is_action_pressed("Lock Drill"):
			target_direction = (get_global_mouse_position() - global_position).angle()
		
		# Interpolate current rotation towards the target direction
		rotation = lerp_angle(rotation, target_direction, rotation_speed * delta)
		
		isDashing = currectDashDuration < dashDuration
		dashTrail.get_node("CPUParticles2D").emitting = isDashing
		if isDashing:
			currectDashDuration += delta
		
		if custom_velocity.length() > 0:
			custom_velocity = custom_velocity.normalized() * speed * 1000
			get_node("Drill Collider Base").disabled = isDashing
			get_node("Drill Collider Tip").disabled = isDashing
			get_node("Head Collider").disabled = isDashing
			if isDashing:
				dashTrail.global_position = global_position
				var progress = clamp(currectDashDuration / dashDuration, 0, 1)
				custom_velocity *= dashSpeedScalar
				
		velocity = custom_velocity  # Use the built-in velocity property
		move_and_slide()  # No arguments needed, `velocity` is used internally
