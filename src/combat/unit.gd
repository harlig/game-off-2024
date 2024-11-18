class_name Unit extends Node3D

const projectile_scene := preload("res://src/combat/projectile.tscn")
const damage_buff_texture: Texture2D = preload("res://textures/card/augment/buff_damage.jpg")
const health_buff_texture: Texture2D = preload("res://textures/card/augment/buff_health.png")
const speed_buff_texture: Texture2D = preload("res://textures/card/augment/buff_speed.png")

enum Direction {LEFT, RIGHT}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var unit_attackable: Attackable = $Attackable

const ATTACK_COOLDOWN := 1.2
# give a unit time to not instantly die
const INVULNERABLE_TIME := ATTACK_COOLDOWN * 2

@export var direction: Direction = Direction.RIGHT

const WALK_ANIMATION := "walk"
var attack_animation := "attack"
var change_torch_animation := "light_torch"

var speed := 1.5
var damage := 5:
	set(value):
		damage = value
		$Label3D.text = str(damage)
var unit_name: String = "Unit"
var unit_type: int = UnitList.CardType.MELEE
var currently_attacking: Array[Attackable] = []
var allies_in_attack_range: Array[Attackable] = []
var enemies_in_attack_range: Array[Attackable] = []

var furthest_x_position_allowed: float = 0

var is_attacking := false
var time_since_last_attack := 0.0
var invulnerability_timer := Timer.new()
var is_invulnerable := true

var can_change_torches := false
var is_changing_torch := false

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

	func texture() -> Texture2D:
		match type:
			BuffType.SPEED:
				return speed_buff_texture
			BuffType.DAMAGE:
				return damage_buff_texture
			BuffType.HEALTH:
				return health_buff_texture
		return null

var buffs_i_apply: Array[Buff] = []

func _ready() -> void:
	add_child(invulnerability_timer)
	invulnerability_timer.one_shot = true
	invulnerability_timer.connect("timeout", stop_invulnerability, ConnectFlags.CONNECT_ONE_SHOT);
	invulnerability_timer.start(INVULNERABLE_TIME)

func stop_invulnerability() -> void:
	is_invulnerable = false
	invulnerability_timer.queue_free()

var closest_ally_attackable_needing_heal_before_heal: Attackable = null

func _process(delta: float) -> void:
	# can't do any other actions while lighting a torch
	if is_changing_torch:
		return

	if !enemies_in_attack_range.is_empty() or (unit_type == UnitList.CardType.HEALER and not allies_in_attack_range.is_empty()):
		if time_since_last_attack >= ATTACK_COOLDOWN:
			is_invulnerable = false

			if unit_type == UnitList.CardType.HEALER:
				perform_heal()
			elif unit_type == UnitList.CardType.RANGED:
				perform_ranged_attack()
			else:
				play_attack_animation_and_reset()

	if is_attacking:
		time_since_last_attack += delta
		# return early here to not move the unit
		if unit_type != UnitList.CardType.HEALER or not enemies_in_attack_range.is_empty():
			return

	if direction == Direction.RIGHT:
		if not can_change_torches and position.x >= furthest_x_position_allowed:
			return
		position.x += speed * delta
	else:
		if not can_change_torches and position.x <= furthest_x_position_allowed:
			return
		position.x -= speed * delta

func perform_heal() -> void:
	var lowest_hp_ally: Attackable = null
	for attackable in allies_in_attack_range:
		if attackable.hp < attackable.max_hp:
			if lowest_hp_ally == null or (attackable.max_hp - attackable.hp) > (lowest_hp_ally.max_hp - lowest_hp_ally.hp):
				lowest_hp_ally = attackable
	if lowest_hp_ally != null:
		lowest_hp_ally.heal(damage)
		lowest_hp_ally.get_node("HealParticles").emitting = true
		play_attack_animation_and_reset()


func perform_ranged_attack() -> void:
	var closest_attackable: Attackable = null
	for attackable in enemies_in_attack_range:
		if closest_attackable == null or attackable.position.distance_to(position) < closest_attackable.position.distance_to(position):
			closest_attackable = attackable
	if closest_attackable != null:
		fire_projectile(closest_attackable)
		play_attack_animation_and_reset()

func play_attack_animation_and_reset() -> void:
	animation_player.seek(0, true)
	animation_player.play(attack_animation)
	# are you seeing an error that says this is already connected? that probably means the attack animation used here is longer than the attack cooldown!
	animation_player.animation_finished.connect(do_attacks, ConnectFlags.CONNECT_ONE_SHOT)
	time_since_last_attack = 0.0


func do_attacks(_anim_name: String) -> void:
	if unit_type != UnitList.CardType.RANGED and unit_type != UnitList.CardType.HEALER:
		for attackable in currently_attacking:
			attackable.take_damage(damage)
	animation_player.play(WALK_ANIMATION)

# when something runs into my target area
func _on_target_area_area_entered(area: Area3D) -> void:
	if area is not Attackable or area.get_parent() == self:
		return
	var attackable := area as Attackable
	if attackable.team == unit_attackable.team:
		allies_in_attack_range.append(attackable)
		if unit_type == UnitList.CardType.HEALER:
			is_attacking = true
		return

	enemies_in_attack_range.append(attackable)
	if unit_type != UnitList.CardType.RANGED or currently_attacking.size() <= 0:
		currently_attacking.append(attackable)
	is_attacking = true


func _on_target_area_area_exited(area: Area3D) -> void:
	if area is not Attackable:
		return
	if (area as Attackable).team == unit_attackable.team:
		allies_in_attack_range.erase(area)
		if unit_type == UnitList.CardType.HEALER and allies_in_attack_range.size() == 0 and is_attacking:
			is_attacking = false

	currently_attacking.erase(area)
	enemies_in_attack_range.erase(area)

	if currently_attacking.size() == 0 and is_attacking:
		is_attacking = false
		if not animation_player.animation_finished.is_connected(_on_attack_finished):
			animation_player.animation_finished.connect(_on_attack_finished, ConnectFlags.CONNECT_ONE_SHOT)

func _on_attack_finished(_anim_name: String) -> void:
	animation_player.seek(0, true)
	animation_player.play(WALK_ANIMATION)

func set_stats(from_creature: UnitList.Creature, flip_image: bool = false) -> void:
	# need to set both max and current hp
	unit_attackable.max_hp = from_creature.health
	unit_attackable.hp = from_creature.health

	$MeshInstance3D.material_override.set_shader_parameter("albedo", ResourceLoader.load(from_creature.card_image_path))
	$MeshInstance3D.material_override.set_shader_parameter("flip_h", flip_image)
	if flip_image:
		attack_animation = "attack_reversed"
		change_torch_animation = "light_torch_reversed"
	if from_creature.type == UnitList.CardType.HEALER:
		attack_animation = "heal"

	damage = from_creature.damage
	unit_name = from_creature.name
	unit_type = from_creature.type
	buffs_i_apply = from_creature.buffs_i_apply
	can_change_torches = from_creature.can_change_torches

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
			UnitList.CardType.HEALER:
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
	if not can_change_torches or torch.is_lit:
		return

	is_changing_torch = true
	animation_player.play(change_torch_animation)
	var timer := Timer.new()
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	await timer.timeout

	if not torch.is_lit:
		torch.light_torch()

	is_changing_torch = false
	animation_player.play(WALK_ANIMATION)

func try_extinguish_torch(torch: Torch) -> void:
	if not can_change_torches or not torch.is_lit:
		return

	is_changing_torch = true
	animation_player.play(change_torch_animation)
	await get_tree().create_timer(2.0).timeout

	if torch.is_lit:
		torch.extinguish_torch()

	is_changing_torch = false
	animation_player.play(WALK_ANIMATION)

func fire_projectile(target_unit: Attackable) -> void:
	var projectile_instance: Projectile = projectile_scene.instantiate()

	# Set the projectile's initial position to the unit's position
	projectile_instance.position = position

	# Calculate the direction towards the target unit
	var projectile_direction := (target_unit.global_position - position).normalized()

	# Set the projectile's velocity or direction
	projectile_instance.velocity = projectile_direction * projectile_instance.speed
	projectile_instance.damage = damage
	projectile_instance.team = unit_attackable.team

	get_parent().add_child(projectile_instance)
