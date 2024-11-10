class_name Attackable extends Area3D

@export var team: Team
var hp := 75:
	set(new_hp):
		if new_hp > max_hp:
			hp = max_hp
		else:
			hp = new_hp

var max_hp := hp:
	set(new_max_hp):
		hp = new_max_hp
		max_hp = new_max_hp

enum Team {PLAYER, ENEMY}

signal died()

func take_damage(damage: int) -> void:
	if get_parent() is Unit and (get_parent() as Unit).is_invulnerable:
		return
	hp -= damage
	if hp <= 0:
		emit_signal("died")
		get_parent().queue_free()

func heal(amount: int) -> void:
	hp += amount
