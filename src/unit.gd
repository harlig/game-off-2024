class_name Unit extends Node2D

enum Direction {LEFT, RIGHT}

@export var direction: Direction = Direction.RIGHT
var speed := 150

var is_stopped := false
var currently_attacking: Attackable = null

var has_attacked := false
var time_since_last_attack := 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if currently_attacking != null:
		if time_since_last_attack >= 1.0 or !has_attacked:
			currently_attacking.take_damage(10)
			time_since_last_attack = 0.0
		has_attacked = true

	if has_attacked:
		time_since_last_attack += delta

	if is_stopped:
		return

	if direction == Direction.RIGHT:
		position.x += speed * delta
	else:
		position.x -= speed * delta

# when I run into something
func _on_attackable_area_entered(area: Area2D) -> void:
	print(area.get_children())
	if area.get_parent() == self:
		return
	is_stopped = true

func _on_attackable_area_exited(_area: Area2D) -> void:
	is_stopped = false


# when something runs into my target area
func _on_target_area_area_entered(area: Area2D) -> void:
	if area is not Attackable or area.get_parent() == self:
		return
	var attackable := area as Attackable
	if attackable.team == $Attackable.team:
		return

	currently_attacking = attackable


func _on_target_area_area_exited(_area: Area2D) -> void:
	currently_attacking = null
