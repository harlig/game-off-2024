class_name Attackable extends Area2D

@export var team: Team
var hp := 30

enum Team {PLAYER, ENEMY}

func _ready() -> void:
	$HP.text = str(hp)

func take_damage(damage: int) -> void:
	print("Taking damage")
	hp -= damage
	$HP.text = str(hp)
	if hp <= 0:
		$HP.text = "0"
		get_parent().queue_free()
