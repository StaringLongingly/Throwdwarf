extends RichTextLabel

var isPaused: bool = true
var textCache: String
@export var rectangle: ColorRect
@export var animationTime: float = 1.0
var cachedBlack: float = 0.0
var cachedLod: float = 0.0
var LodProgress: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rectangle.color = Color(Color.BLACK, 0.9)
	textCache = text
	text = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		isPaused = !isPaused
	
	get_tree().paused = isPaused
	if isPaused:
		animate_shader(delta, true)
		text = textCache
		if Input.is_action_just_pressed("Legendary Inventory"): 
			isPaused = false
			get_node("/root/Node2D/Player").take_damage(99999999999)
	else:
		animate_shader(delta, false)
		text = ""

func animate_shader(delta: float, isIncreasing: bool) -> void:
	if isIncreasing:
		LodProgress = clamp(LodProgress + delta / animationTime, 0, 1)
	else:
		LodProgress = clamp(LodProgress - delta / animationTime, 0, 1)
	var LodProgressEased: float = clamp(ease(LodProgress, 0.6), 0, 1)
	
	rectangle.color = Color(Color.BLACK, LodProgressEased * 0.9)
		
# Function to reset shader parameters and cached variables
func reset_shader_parameters() -> void:
	if rectangle and rectangle.material:
		cachedLod = 2
		cachedBlack = 0.3
		LodProgress = 1.0
	else:
		print("Error: Rectangle or material is missing.")

# Function to handle scene restart
func restart_scene() -> void:
	get_tree().reload_current_scene()
