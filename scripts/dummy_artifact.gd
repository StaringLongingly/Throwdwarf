extends AnimatedSprite2D
var trail: Node2D
var helmet: Node2D
@export var baseSpeed: float
@export var acceleration: float
@export var idleDuration: float = 2
@export var isTrailEnabled: bool = false
var currentidleDuration: float = 0
var cachedScale: Vector2
var timeMoving: float = 0

func _ready() -> void:
	var artifactInfo: Dictionary = get_node("/root/Node2D/Artifact").latestArtifact
	var rarityStr: String = get_node("/root/Node2D/Artifact").latestRarity
	var rarityColor: Color = get_node("/root/Node2D/HUD").get_color(rarityStr)
	var artifactScene: PackedScene = load("res://artifacts/scenes/" + artifactInfo.name + ".tscn")
	var artifact = artifactScene.instantiate()
	
	var squarePng = load("res://sprites/" + rarityStr + "_square.png")
	material.set_shader_parameter("color_gradient", squarePng)
	
	sprite_frames = artifact.sprite_frames
	scale = Vector2.ONE * 0.7
	artifact.queue_free()
	global_rotation_degrees = randf() * 360
	
	var trailScene = preload("res://scenes/Item Trail.tscn")
	trail = trailScene.instantiate()
	add_child(trail)
	cachedScale = trail.global_scale
	trail.get_node("CPUParticles2D").color = rarityColor
	trail.get_node("CPUParticles2D").emitting = false
	trail.get_node("CPUParticles2D").amount /= 5
	
	helmet = get_node("/root/Node2D/Player/Helmet")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var to: Vector2 = helmet.global_position
	var from: Vector2 = global_position
	var difference: Vector2 = to - from
	var direction: Vector2 = difference.normalized()
	var magnitude = difference.length()
	
	if magnitude < 1000: 
		var progress = clamp(magnitude / 1000, 0, 1)
		global_scale = cachedScale * progress
		if global_scale.length() < 0.2:
			trail.reparent(get_node("/root/Node2D"))
			trail.get_node("CPUParticles2D").emitting = false
			queue_free()
			
	if currentidleDuration < idleDuration:
		currentidleDuration += delta
	else:
		trail.get_node("CPUParticles2D").emitting = isTrailEnabled 
		timeMoving += delta
		var speed = baseSpeed + timeMoving * acceleration
		global_position += direction * speed * 1000 * delta
		if magnitude < 1000 and global_scale.length() < 0.2:
			trail.get_node("CPUParticles2D").emitting = false
			
