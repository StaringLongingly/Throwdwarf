extends RichTextLabel
var isPaused: bool = true
var textCache
@export var rectangle: ColorRect
@export var animationTime: float
var cachedBlack
var cachedLod
var LodProgress: float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cachedLod = rectangle.material.get_shader_parameter("lod")
	cachedBlack = rectangle.material.get_shader_parameter("black")
	textCache = text
	text = ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		isPaused = !isPaused
	
	get_tree().paused = isPaused
	if isPaused:
		animateShader(delta, true)
		text = textCache
		if Input.is_action_just_pressed("Legendary Inventory"): 
			get_tree().reload_current_scene()
			
	else:
		animateShader(delta, false)
		text = ""

func animateShader(delta: float, isIncreasing: bool):
	if isIncreasing:
		if LodProgress < 1:
			LodProgress += delta / animationTime
	else:
		if LodProgress > 0:
			LodProgress -= delta / animationTime
	clampf(LodProgress, 0, 1)
	rectangle.material.set_shader_parameter("lod", cachedLod * ease(LodProgress, 0.6))
	rectangle.material.set_shader_parameter("black", lerpf(1, cachedBlack, ease(LodProgress, 0.6)))
