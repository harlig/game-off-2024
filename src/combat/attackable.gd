class_name Attackable extends Area3D

@export var team: Team
var hp := 75:
	set(new_hp):
		if new_hp > max_hp:
			new_hp = max_hp
		else:
			hp = new_hp

var max_hp := hp:
	set(new_max_hp):
		hp = new_max_hp

enum Team {PLAYER, ENEMY}

signal died()

func take_damage(damage: int) -> void:
	if get_parent() is Unit and (get_parent() as Unit).is_invulnerable:
		return
	hp -= damage
	if hp <= 0:
		get_parent().queue_free()
		emit_signal("died")

func heal(amount: int) -> void:
	hp += amount
