class_name Unit extends Node2D

enum Direction {LEFT, RIGHT}

@export var direction: Direction = Direction.RIGHT
var speed := 175
var damage := 5
var unit_name: String = "Unit"

var is_stopped := false
var currently_attacking: Array[Attackable] = []

var has_attacked := false
var time_since_last_attack := 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !currently_attacking.is_empty():
		if time_since_last_attack >= 1.0 or !has_attacked:
			for attackable in currently_attacking:
				attackable.take_damage(damage)
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

# when something runs into my target area
func _on_target_area_area_entered(area: Area2D) -> void:
	if area is not Attackable or area.get_parent() == self:
		return
	var attackable := area as Attackable
	if attackable.team == $Attackable.team:
		return

	currently_attacking.append(attackable)
	is_stopped = true


func _on_target_area_area_exited(area: Area2D) -> void:
	if area is not Attackable:
		return
	currently_attacking.erase(area)
	if currently_attacking.size() == 0:
		is_stopped = false


func set_stats(card_data: Card.Data, flip_image: bool = false) -> void:
	$Attackable.set_hp(card_data.max_health)
	$Sprite2D.texture = ResourceLoader.load(card_data.card_image_path)
	$Sprite2D.flip_h = flip_image

	damage = card_data.damage
	unit_name = card_data.card_name
