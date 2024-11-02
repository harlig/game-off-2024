extends Node2D

@export var unit: PackedScene

func _ready() -> void:
	spawn_player_unit()
	# spawn_enemy_unit()

	$PlayerBase/HP.text = "100"
	$EnemyBase/HP.text = "100"

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector2, direction: Unit.Direction) -> void:
	var new_unit = unit_to_spawn.instantiate()
	new_unit.position = unit_position
	new_unit.direction = direction
	add_child(new_unit)
	print("Spawned")

func spawn_player_unit() -> void:
	var unit_position = $PlayerBase.position + Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	spawn_unit(unit, unit_position, Unit.Direction.RIGHT)

func spawn_enemy_unit() -> void:
	var unit_position = $EnemyBase.position - Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	spawn_unit(unit, unit_position, Unit.Direction.LEFT)
