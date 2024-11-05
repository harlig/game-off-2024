class_name ThreeDAttackable extends Area3D

@export var team: Team
var hp := 75:
	set(new_hp):
		hp = new_hp

enum Team {PLAYER, ENEMY}

signal died()

# func _ready() -> void:
# 	$HP.text = str(hp)

func take_damage(damage: int) -> void:
	hp -= damage
	if hp <= 0:
		get_parent().queue_free()
		emit_signal("died")
