class_name Unit extends Area2D

enum Direction {LEFT, RIGHT}

@export var direction: Direction = Direction.RIGHT
var speed := 200

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
	# need this otherwise we collide with our own target area
	if area.get_parent() == self:
		return
	is_stopped = true
