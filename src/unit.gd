class_name Unit extends Area2D

enum Direction {LEFT, RIGHT}

@export var direction: Direction = Direction.RIGHT
var speed := 100

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if direction == Direction.RIGHT:
		position.x += speed * delta
	else:
		position.x -= speed * delta
