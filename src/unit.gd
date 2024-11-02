class_name Unit extends Area2D

enum Direction {LEFT, RIGHT}

@export var direction: Direction = Direction.RIGHT
var speed := 100

var is_stopped := false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if is_stopped:
		return

	if direction == Direction.RIGHT:
		position.x += speed * delta
	else:
		position.x -= speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area is Unit:
		is_stopped = true
