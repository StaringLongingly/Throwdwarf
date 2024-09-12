extends CanvasLayer

@export var newSound: PackedScene
@export var stackSound: PackedScene
@export var windowMinMax: Vector2
@export var infoLabel: RichTextLabel
@export var lifetime: float
@export var moveSpeed: float
@export var hueSpeed: float
var previousArtifactDisplayed: Dictionary = {}
var artifactsDisplayed: int = 0
var hue: float = 0.0
var currentLifetime: float = 0.0
var moveProgress: float = 0.0
var artifactStats: String = ""
var isArtifactNew: bool = false

func _process(delta: float) -> void:
	hue += hueSpeed * delta
	if hue >= 1.0:
		hue -= 1.0
	var hsv_color = Color.from_hsv(hue, 1.0, 1.0)
	if artifactsDisplayed == 1:
		infoLabel.text = "[color=#" + color_to_hex(hsv_color) + "]STARTER! " + artifactStats
	elif isArtifactNew:
		infoLabel.text = "[color=#" + color_to_hex(hsv_color) + "]NEW! " + artifactStats
	else:
		infoLabel.text = "[color=#" + color_to_hex(hsv_color) + "]STACK! " + artifactStats

	if moveProgress <= 1.0 and currentLifetime >= 0.0:
		# Window is sliding up
		moveProgress += moveSpeed * delta
		if artifactsDisplayed == 1:
			moveProgress = 1.0
	elif moveProgress >= 1.0 and currentLifetime >= 0.0:
		# Window is staying
		currentLifetime -= delta
	elif moveProgress >= 0.0 and currentLifetime <= 0.0:
		# Window is sliding down
		moveProgress -= moveSpeed * delta
	var viewport = get_viewport()
	var percent_y = lerp(windowMinMax.x, windowMinMax.y, ease(moveProgress, 0.2))
	var percent = Vector2(0.02, percent_y)
	var screen_position = get_screen_position_from_percentage(viewport, percent)
	infoLabel.position = screen_position

func _on_artifact_display_artifact_info(artifact: Dictionary, rarity: String, isNew: bool, id: String) -> void:
	if artifact != previousArtifactDisplayed:
		artifactsDisplayed += 1
	isArtifactNew = isNew
	var sound = newSound.instantiate() if isNew else stackSound.instantiate()
	add_child(sound)
	currentLifetime = lifetime
	artifactStats = "[b][u]" + get_color_string(rarity) + artifact["name"] + "[/color][/u][/b]"
	artifactStats += "[color=#ffffff] (ID:" + id + ")"
	artifactStats += " [color=#f2ee15]" + str(artifact["sell_value"]) + " Drill Energy\n"
	artifactStats += "[color=#ffffff][i]" + artifact["description"]

	previousArtifactDisplayed = artifact

func color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "%02X%02X%02X" % [r, g, b]

func get_screen_position_from_percentage(viewport: Viewport, percent: Vector2) -> Vector2:
	var viewport_size = viewport.size
	return Vector2(viewport_size.x * percent.x, viewport_size.y * percent.y)

func get_color_string(rarity: String) -> String:
	var result = "[color="
	match rarity:
		"common":
			result += "#15f254"
		"rare":
			result += "#158bf2"
		"legendary":
			result += "#fcba05"
		_:
			result += "#ffffff"
	result += "]"
	return result

func get_color(rarity: String) -> Color:
	var color_code = ""
	match rarity:
		"common":
			color_code = "#15f254"
		"rare":
			color_code = "#158bf2"
		"legendary":
			color_code = "#fcba05"
		_:
			color_code = "#ffffff"
	return Color(color_code)
