extends Node2D

@export var unit: PackedScene

func _ready() -> void:
	spawn_unit(unit, Vector2(0, 0), Unit.Direction.RIGHT)
	pass

func _process(delta: float) -> void:
	pass

func spawn_unit(spawn_unit: PackedScene, unit_position: Vector2, direction: Unit.Direction) -> void:
	var new_unit = spawn_unit.instantiate()
	new_unit.position = unit_position
	new_unit.direction = direction
	add_child(new_unit)
