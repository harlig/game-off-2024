class_name ThreeDUnit extends Node3D

enum Direction {LEFT, RIGHT}

# @onready var animation_player: AnimationPlayer = $AnimationPlayer
# var attack_animation := "attack"

@export var direction: Direction = Direction.RIGHT
var speed := 1
var damage := 5
var unit_name: String = "Unit"

var is_stopped := false
var currently_attacking: Array[ThreeDAttackable] = []

var is_attacking := false
var time_since_last_attack := 0.0

const ATTACK_COOLDOWN := 2.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !currently_attacking.is_empty():
		if time_since_last_attack >= 1.0:
			# animation_player.seek(0, true)
			# animation_player.play(attack_animation)
			# animation_player.animation_finished.connect(do_attacks, ConnectFlags.CONNECT_ONE_SHOT)
			time_since_last_attack = 0.0

	if is_attacking:
		time_since_last_attack += delta

	if is_stopped:
		return

	if direction == Direction.RIGHT:
		position.x += speed * delta
	else:
		position.x -= speed * delta

func do_attacks(_anim_name: String) -> void:
	for attackable in currently_attacking:
		attackable.take_damage(damage)

# when something runs into my target area
func _on_target_area_area_entered(area: Area3D) -> void:
	if area is not ThreeDAttackable or area.get_parent() == self:
		return
	var attackable := area as ThreeDAttackable
	if attackable.team == $Attackable.team:
		return

	currently_attacking.append(attackable)
	is_attacking = true
	is_stopped = true


func _on_target_area_area_exited(area: Area3D) -> void:
	if area is not ThreeDAttackable:
		return
	if (area as ThreeDAttackable).team == $Attackable.team:
		return
	currently_attacking.erase(area)
	if currently_attacking.size() == 0:
		is_stopped = false
		is_attacking = false
		# animation_player.animation_finished.connect(_on_attack_finished, ConnectFlags.CONNECT_ONE_SHOT)

func _on_attack_finished(_anim_name: String) -> void:
	pass
	# animation_player.seek(0, true)
	# animation_player.play("walk")


func set_stats(card_data: Card.Data, flip_image: bool = false) -> void:
	$Attackable.hp = card_data.max_health
	# $Sprite2D.texture = ResourceLoader.load(card_data.card_image_path)
	# $Sprite2D.flip_h = flip_image
	# if flip_image:
	# 	attack_animation = "attack_reversed"

	damage = card_data.damage
	unit_name = card_data.card_name