extends Node

@export var wallBlockNode: PackedScene
@export var wallHeight: int
@export var wallWidth: int
@export var starterWall: Vector2

var worker_thread: Thread = Thread.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	worker_thread.start(build_wall)

# Function that builds the wall, to be run in a separate thread.
func build_wall() -> void:
	for i in range(0, wallWidth):
		for j in range(0, int(wallHeight / 2) + 1):
			var newBlock: Node2D = wallBlockNode.instantiate()
			call_deferred("add_child", newBlock) # Safely add the child to the scene tree in the main thread
			newBlock.position = Vector2(starterWall.x - i * 1000, j * 1000)
			
			if j != 0:
				var newBlock2: Node2D = wallBlockNode.instantiate()
				call_deferred("add_child", newBlock2) # Safely add the child to the scene tree in the main thread
				newBlock2.position = Vector2(starterWall.x - i * 1000, - j * 1000)

	worker_thread.wait_to_finish() # Ensure the thread completes before the node is removed

func _exit_tree() -> void:
	worker_thread.wait_to_finish() # Wait for the thread to finish if the node is removed
