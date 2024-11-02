extends Node2D

@export var unit: PackedScene

func _ready() -> void:
	for _ndx in range(2):
		spawn_player_unit(_ndx)
	spawn_enemy_unit()

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector2, team: Attackable.Team) -> void:
	var new_unit: Unit = unit_to_spawn.instantiate()
	new_unit.position = unit_position
	new_unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	new_unit.get_node("TargetArea").scale.x = 1 if team == Attackable.Team.PLAYER else -1
	new_unit.get_node("Attackable").team = team
	add_child(new_unit)

func spawn_player_unit(offset: int = 0) -> void:
	var unit_position = $PlayerBase.position + Vector2(75 + 55 * offset, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	spawn_unit(unit, unit_position, Attackable.Team.PLAYER)

func spawn_enemy_unit() -> void:
	var unit_position = $EnemyBase.position - Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	spawn_unit(unit, unit_position, Attackable.Team.ENEMY)
