extends Node

@export var wallBlockNode: Node2D 
@export var wallHeight: int
@export var wallWidth: int
@export var starterWall: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(0, wallWidth):
		for j in range(0, wallHeight as float / 2 + 1):
			var newBlock = wallBlockNode.duplicate()
			add_child(newBlock)
			newBlock.position = Vector2(starterWall.x - i * 1000, j * 1000)
			if j != 0:
				var newBlock2 = wallBlockNode.duplicate()
				add_child(newBlock2)
				newBlock2.position = Vector2(starterWall.x - i * 1000, - j * 1000)
				
