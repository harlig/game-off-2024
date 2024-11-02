extends Node2D

@export var unit: PackedScene

func _ready() -> void:
	spawn_enemy_unit()
	pass

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector2, team: Attackable.Team) -> Unit:
	var new_unit: Unit = unit_to_spawn.instantiate()
	new_unit.position = unit_position
	new_unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	new_unit.get_node("TargetArea").scale.x = 1 if team == Attackable.Team.PLAYER else -1
	new_unit.get_node("Attackable").team = team
	add_child(new_unit)
	return new_unit

func spawn_enemy_unit() -> void:
	var unit_position: Vector2 = $EnemyBase.position - Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	spawn_unit(unit, unit_position, Attackable.Team.ENEMY)

func _on_hand_card_played(played_card: Card) -> void:
	var unit_position: Vector2 = $PlayerBase.position + Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	var created_unit: Unit = spawn_unit(unit, unit_position, Attackable.Team.PLAYER)
	created_unit.set_stats(played_card.max_health, played_card.damage, played_card.card_name, played_card.card_image_path)
