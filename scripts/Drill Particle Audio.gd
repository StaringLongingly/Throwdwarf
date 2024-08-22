extends AudioStreamPlayer2D 

@export var numberRange: Vector2

func _ready():
	# The path to the folder containing the .ogg files
	var number: int = lerpf(numberRange.x, numberRange.y, randf()) as int
	var path = "res://sfx/Leaves/00 - Downloads - LeavesTest001 0" + str(number) + ".ogg"
	var audioStream: AudioStream = ResourceLoader.load(path) as AudioStream
	stream = audioStream
	max_distance = 100000.0  # Set max distance to 100000 units
	play()  # Autoplay the sound
