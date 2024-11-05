class_name Unit extends Node2D

enum Direction {LEFT, RIGHT}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var attack_animation := "attack"

@export var direction: Direction = Direction.RIGHT
var speed := 175
var damage := 5
var unit_name: String = "Unit"

var is_stopped := false
var currently_attacking: Array[Attackable] = []

var is_attacking := false
var time_since_last_attack := 0.0

const ATTACK_COOLDOWN := 2.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !currently_attacking.is_empty():
		if time_since_last_attack >= 1.0:
			animation_player.seek(0, true)
			animation_player.play(attack_animation)
			for attackable in currently_attacking:
				attackable.take_damage(damage)
			time_since_last_attack = 0.0

	if is_attacking:
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
	is_attacking = true
	is_stopped = true


func _on_target_area_area_exited(area: Area2D) -> void:
	if area is not Attackable:
		return
	if (area as Attackable).team == $Attackable.team:
		return
	currently_attacking.erase(area)
	if currently_attacking.size() == 0:
		is_stopped = false
		is_attacking = false
		animation_player.animation_finished.connect(_on_attack_finished)

func _on_attack_finished(_anim_name: String) -> void:
	animation_player.seek(0, true)
	animation_player.play("walk")
	animation_player.animation_finished.disconnect(_on_attack_finished)


func set_stats(card_data: Card.Data, flip_image: bool = false) -> void:
	$Attackable.set_hp(card_data.max_health)
	$Sprite2D.texture = ResourceLoader.load(card_data.card_image_path)
	$Sprite2D.flip_h = flip_image
	if flip_image:
		attack_animation = "attack_reversed"

	damage = card_data.damage
	unit_name = card_data.card_name
