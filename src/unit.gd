class_name Unit extends Node3D

enum Direction {LEFT, RIGHT}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var attack_animation := "attack"
const WALK_ANIMATION := "walk"

@export var direction: Direction = Direction.RIGHT
var speed := 10
var damage := 5
var unit_name: String = "Unit"
var unit_type: int = UnitList.CardType.MELEE
var is_stopped := false
var currently_attacking: Array[Attackable] = []
var units_in_attack_range: Array[Attackable] = []

var is_attacking := false
var time_since_last_attack := 0.0

const ATTACK_COOLDOWN := 2.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !units_in_attack_range.is_empty():
		if time_since_last_attack >= 1.0:
			animation_player.seek(0, true)
			animation_player.play(attack_animation)
			animation_player.animation_finished.connect(do_attacks, ConnectFlags.CONNECT_ONE_SHOT)
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
	if unit_type == UnitList.CardType.RANGED:
		var closest_attackable: Attackable = null
		for attackable in units_in_attack_range:
			if closest_attackable == null || attackable.global_transform.origin.distance_to(global_transform.origin) < closest_attackable.global_transform.origin.distance_to(global_transform.origin):
				closest_attackable = attackable
		if closest_attackable != null:
			closest_attackable.take_damage(damage)
	else:
		for attackable in currently_attacking:
			attackable.take_damage(damage)
	animation_player.play(WALK_ANIMATION)

# when something runs into my target area
func _on_target_area_area_entered(area: Area3D) -> void:
	if area is not Attackable or area.get_parent() == self:
		return
	var attackable := area as Attackable
	if attackable.team == $Attackable.team:
		return

	units_in_attack_range.append(attackable)
	if unit_type != UnitList.CardType.RANGED || currently_attacking.size() <= 0:
		currently_attacking.append(attackable)
	is_attacking = true
	is_stopped = true


func _on_target_area_area_exited(area: Area3D) -> void:
	if area is not Attackable:
		return
	if (area as Attackable).team == $Attackable.team:
		return

	currently_attacking.erase(area)
	units_in_attack_range.erase(area)

	if currently_attacking.size() == 0 and is_attacking:
		is_stopped = false
		is_attacking = false
		animation_player.animation_finished.connect(_on_attack_finished, ConnectFlags.CONNECT_ONE_SHOT)

func _on_attack_finished(_anim_name: String) -> void:
	animation_player.seek(0, true)
	animation_player.play(WALK_ANIMATION)


func set_stats(from_creature: UnitList.Creature, flip_image: bool = false) -> void:
	$Attackable.hp = from_creature.health
	$MeshInstance3D.material_override.set_shader_parameter("albedo", ResourceLoader.load(from_creature.card_image_path))
	$MeshInstance3D.material_override.set_shader_parameter("flip_h", flip_image)
	if flip_image:
		attack_animation = "attack_reversed"

	damage = from_creature.damage
	unit_name = from_creature.name
	unit_type = from_creature.type

	resize_unit_target_box(from_creature)

func resize_unit_target_box(creature: UnitList.Creature) -> void:
	var collision_shape: CollisionShape3D = $TargetArea/CollisionShape3D
	if collision_shape.shape is BoxShape3D:
		var box_shape: BoxShape3D = collision_shape.shape

		var x := box_shape.size.x
		var y := box_shape.size.y
		var z := box_shape.size.z
		var new_box_shape := BoxShape3D.new()
		match creature.type:
			UnitList.CardType.AIR:
				y = 100
			UnitList.CardType.RANGED:
				x = 15
				y = 100

		new_box_shape.size = Vector3(x, y, z) # Set the new size
		collision_shape.shape = new_box_shape
