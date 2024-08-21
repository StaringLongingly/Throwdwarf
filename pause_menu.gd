extends RichTextLabel
var isPaused: bool = true
var textCache

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textCache = text
	text = ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		isPaused = !isPaused
	
	get_tree().paused = isPaused
	if isPaused:
		text = textCache
		if Input.is_action_just_pressed("Legendary Inventory"): 
			get_tree().reload_current_scene()
			
	else:
		text = ""
