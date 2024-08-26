extends Node

@export var wallBlockNode: PackedScene
@export var wallArray: Array[Vector2]
@export var wallHeight: int
@export var wallWidth: int
@export var starterWall: Vector2
@export var minPos: Vector2
@export var maxPos: Vector2

var worker_thread: Thread = Thread.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	worker_thread.start(build_wall)

# Function that builds the wall, to be run in a separate thread.
func build_wall() -> void:
	for i in range(0, wallWidth):
		for j in range(0, int(wallHeight as float / 2) + 1):
			var newBlock: Node2D = wallBlockNode.instantiate()
			call_deferred("add_child", newBlock) # Safely add the child to the scene tree in the main thread
			var position1 = Vector2(starterWall.x - i * 1000, j * 1000)
			newBlock.position = position1 
			wallArray.append(position1)
			
			if j != 0:
				var newBlock2: Node2D = wallBlockNode.instantiate()
				call_deferred("add_child", newBlock2) # Safely add the child to the scene tree in the main thread
				var position2 = Vector2(starterWall.x - i * 1000, - j * 1000)
				newBlock2.position = position2 
				wallArray.append(position2)

func _exit_tree() -> void:
	worker_thread.wait_to_finish() # Wait for the thread to finish if the node is removed

func get_valid_enemy_position() -> Vector2:
	var foundValidPosition: bool = false 
	var latestPosition 
	while not foundValidPosition:
		latestPosition = Vector2(
			lerp(minPos.x, maxPos.x, randf()),
			lerp(minPos.y, maxPos.y, randf())
		)
		foundValidPosition = is_valid_enemy_position(latestPosition)
	return latestPosition

func is_valid_enemy_position(position: Vector2) -> bool:
	var x_down = floor(position.x / 1000) * 1000
	var x_up = ceil(position.x / 1000) * 1000
	var y_down = floor(position.y / 1000) * 1000
	var y_up = ceil(position.y / 1000) * 1000
	
	var neighborPositions: Array[Vector2] = [
		Vector2(x_down, y_down),
		Vector2(x_down, y_up),
		Vector2(x_up, y_down),
		Vector2(x_up, y_up)
	]
	var isValidPosition = true
	for neighborPosition in neighborPositions:
		if neighborPosition in wallArray:
			isValidPosition = false
	return isValidPosition


func remove_position(position: Vector2):
	wallArray.erase(position)
