class_name Attackable extends Area2D

@export var team: Team
var hp := 75:
	set(new_hp):
		hp = new_hp
		$HP.text = str(hp)

enum Team {PLAYER, ENEMY}

signal died()

func _ready() -> void:
	$HP.text = str(hp)

func take_damage(damage: int) -> void:
	hp -= damage
	$HP.text = str(hp)
	if hp <= 0:
		$HP.text = "0"
		get_parent().queue_free()
		emit_signal("died")
