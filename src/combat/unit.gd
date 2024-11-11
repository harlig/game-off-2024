class_name Unit extends Node3D

enum Direction {LEFT, RIGHT}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var unit_attackable: Attackable = $Attackable

const ATTACK_COOLDOWN := 1.0
# give a unit time to not instantly die
const INVULNERABLE_TIME := ATTACK_COOLDOWN * 2

@export var direction: Direction = Direction.RIGHT

const WALK_ANIMATION := "walk"
var attack_animation := "attack"

var speed := 1.5
var damage := 5:
	set(value):
		damage = value
		$Label3D.text = str(damage)
var unit_name: String = "Unit"
var unit_type: int = UnitList.CardType.MELEE
var currently_attacking: Array[Attackable] = []
var units_in_attack_range: Array[Attackable] = []

var furthest_x_position_allowed: float = 0

var is_attacking := false
var time_since_last_attack := 0.0
var invulnerability_timer := Timer.new()
var is_invulnerable := true

var can_light_torches := false
var is_lighting_torch := false

enum BuffType {
	SPEED,
	DAMAGE,
	HEALTH
}

class Buff:
	var type: BuffType
	var value: float

	func _init(init_type: BuffType, init_value: float) -> void:
		self.type = init_type
		self.value = init_value

	func description() -> String:
		var type_str := ""
		match type:
			BuffType.SPEED:
				type_str = "speed"
			BuffType.DAMAGE:
				type_str = "damage"
			BuffType.HEALTH:
				type_str = "health"
		return "While alive, gives other units +" + str(value) + " " + type_str

var buffs_i_apply: Array[Buff] = []

func _ready() -> void:
	add_child(invulnerability_timer)
	invulnerability_timer.one_shot = true
	invulnerability_timer.connect("timeout", stop_invulnerability, ConnectFlags.CONNECT_ONE_SHOT);
	invulnerability_timer.start(INVULNERABLE_TIME)

func stop_invulnerability() -> void:
	is_invulnerable = false
	invulnerability_timer.queue_free()

func _process(delta: float) -> void:
	# can't do any other actions while lighting a torch
	if is_lighting_torch:
		return

	if !units_in_attack_range.is_empty():
		if time_since_last_attack >= ATTACK_COOLDOWN:
			animation_player.seek(0, true)
			animation_player.play(attack_animation)
			is_invulnerable = false
			animation_player.animation_finished.connect(do_attacks, ConnectFlags.CONNECT_ONE_SHOT)
			time_since_last_attack = 0.0

	if is_attacking:
		time_since_last_attack += delta
		# return early here to not move the unit
		return

	if direction == Direction.RIGHT:
		if !can_light_torches and position.x >= furthest_x_position_allowed:
			return
		position.x += speed * delta
	else:
		if !can_light_torches and position.x <= furthest_x_position_allowed:
			return
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
	if attackable.team == unit_attackable.team:
		return

	units_in_attack_range.append(attackable)
	if unit_type != UnitList.CardType.RANGED || currently_attacking.size() <= 0:
		currently_attacking.append(attackable)
	is_attacking = true


func _on_target_area_area_exited(area: Area3D) -> void:
	if area is not Attackable:
		return
	if (area as Attackable).team == unit_attackable.team:
		return

	currently_attacking.erase(area)
	units_in_attack_range.erase(area)

	if currently_attacking.size() == 0 and is_attacking:
		is_attacking = false
		if not animation_player.animation_finished.is_connected(_on_attack_finished):
			animation_player.animation_finished.connect(_on_attack_finished)

func _on_attack_finished(_anim_name: String) -> void:
	animation_player.seek(0, true)
	animation_player.play(WALK_ANIMATION)
	animation_player.animation_finished.disconnect(_on_attack_finished)

func set_stats(from_creature: UnitList.Creature, flip_image: bool = false) -> void:
	# need to set both max and current hp
	unit_attackable.max_hp = from_creature.health
	unit_attackable.hp = from_creature.health

	$MeshInstance3D.material_override.set_shader_parameter("albedo", ResourceLoader.load(from_creature.card_image_path))
	$MeshInstance3D.material_override.set_shader_parameter("flip_h", flip_image)
	if flip_image:
		attack_animation = "attack_reversed"

	damage = from_creature.damage
	unit_name = from_creature.name
	unit_type = from_creature.type
	buffs_i_apply = from_creature.buffs_i_apply
	can_light_torches = from_creature.can_light_torches

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

func highlight_unit() -> void:
	$MeshInstance3D.material_override.set_shader_parameter("highlight", true)

func unhighlight_unit() -> void:
	$MeshInstance3D.material_override.set_shader_parameter("highlight", false)


func make_selectable(selectable: bool) -> void:
	unit_attackable.input_ray_pickable = selectable

func apply_buff(incoming_buff: Buff) -> void:
	print("Applying buff: " + str(incoming_buff.type) + " " + str(incoming_buff.value))
	match incoming_buff.type:
		BuffType.SPEED:
			speed += incoming_buff.value
		BuffType.DAMAGE:
			damage += int(incoming_buff.value)
		BuffType.HEALTH:
			unit_attackable.max_hp += int(incoming_buff.value)
			unit_attackable.hp += int(incoming_buff.value)

func remove_buff(buff_to_remove: Buff) -> void:
	match buff_to_remove.type:
		BuffType.SPEED:
			speed -= buff_to_remove.value
		BuffType.DAMAGE:
			damage -= int(buff_to_remove.value)
		BuffType.HEALTH:
			unit_attackable.max_hp -= int(buff_to_remove.value)
			unit_attackable.hp -= int(buff_to_remove.value)

func try_light_torch(torch: Torch) -> void:
	if !can_light_torches or torch.is_lit:
		return

	is_lighting_torch = true
	animation_player.play("light_torch")
	await get_tree().create_timer(2.0).timeout

	if not torch.is_lit:
		torch.light_torch()

	is_lighting_torch = false
	animation_player.play(WALK_ANIMATION)
