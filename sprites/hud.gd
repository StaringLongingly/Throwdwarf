extends CanvasLayer
@export var newSound: PackedScene
@export var stackSound: PackedScene
@export var windowMinMax: Vector2
@export var infoLabel: RichTextLabel
@export var lifetime: float
@export var moveSpeed: float
@export var hueSpeed: float
var hue = 0
var currentLifetime = 0
var moveProgress = 0
var artifactStats = ""
var isArtifactNew: bool = false

func _process(delta: float) -> void:
	hue += hueSpeed * delta
	if (hue >= 1):
		hue -= 1
	var hsv_color = Color.from_hsv(hue, 1, 1,)
	if (isArtifactNew):
		infoLabel.text = "[color=#" + color_to_hex(hsv_color) + "]" + "NEW! " + artifactStats
	else:
		infoLabel.text = "[color=#" + color_to_hex(hsv_color) + "]" + "STACK! " + artifactStats
	
	if (moveProgress <= 1 && currentLifetime >= 0): 
		# Window is sliding up
		# print("Sliding Window up with moveProgress: ", moveProgress)
		moveProgress += moveSpeed * delta
	elif (moveProgress >= 1 && currentLifetime >= 0):
		# Window is staying
		# print("Window is staying with currentLifetime: ", currentLifetime)
		currentLifetime -= delta
	elif (moveProgress >= 0 && currentLifetime <= 0):
		# Window is sliding down
		# print("Sliding Window down with moveProgress: ", moveProgress)
		moveProgress -= moveSpeed * delta
	var viewport = get_viewport()
	var percent = Vector2(0.02, lerpf(windowMinMax.x, windowMinMax.y, ease(moveProgress, 0.2)))  # Example: Center of the viewport
	var screen_position = get_screen_position_from_percentage(viewport, percent)
	infoLabel.position = screen_position


func _on_artifact_display_artifact_info(artifact: Dictionary, rarity: String, isNew: bool, ) -> void:
	isArtifactNew = isNew
	if isNew:
		var sound = newSound.instantiate()
		add_child(sound)
	else:
		var sound = stackSound.instantiate()
		add_child(sound)
	currentLifetime = lifetime
	# print("Displaying artifact info:")
	var colorHex: String
	if (rarity == "common"):
		colorHex = "#15f254"
	elif (rarity == "rare"):
		colorHex = "#158bf2"
	elif (rarity == "legendary"):
		colorHex = "#fcba05"
	else:
		colorHex = "#ffffff"
		
	artifactStats = "[b][u][color=" + colorHex + "]" + artifact.name + "[/color][/u][/b]"
	artifactStats += "[color=#ffffff] (ID:" + artifact.id + ")"
	artifactStats += "[color=#f21533]  " + str(artifact.extra_hp) + " Vg  [color=#f2ee15]" + str(artifact.sell_value) + " De\n"
	artifactStats += "[color=#ffffff][i]" + artifact.description
	

func color_to_hex(color: Color) -> String:
	# Convert Color to RGB
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)

	# Format as a hexadecimal string
	return String("%02X%02X%02X" % [r, g, b])
	
func get_screen_position_from_percentage(viewport: Viewport, percent: Vector2) -> Vector2:
	var viewport_size = viewport.size
	return Vector2(viewport_size.x * percent.x, viewport_size.y * percent.y)
