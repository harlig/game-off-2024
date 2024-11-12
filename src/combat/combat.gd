class_name Combat extends Node3D

@onready var unit_scene: PackedScene = preload("res://src/combat/unit.tscn")
@onready var torch_scene: PackedScene = preload("res://src/torch.tscn")

@onready var reward := $Reward
@onready var spawn_mesh: MeshInstance3D = $SpawnMesh
@onready var original_spawn_mesh_color: Color = spawn_mesh.material_override.get_shader_parameter("color")
@onready var player_base_torch_location: Node3D = $PlayerBaseTorchLocation
@onready var enemy_base_torch_position: Node3D = $EnemyBaseTorchLocation

signal reward_presented()
signal reward_chosen(reward: Reward.RewardData)
signal combat_over(combat_state: CombatState)

enum CombatState {PLAYING, WON, LOST}

const OFFSET_FROM_BASE_DISTANCE := 3
const NUM_TORCHES := 3
const BATTLFIELD_START_X := -23
const BATTLFIELD_Z = 6;

var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0
var difficulty := 1

var play_location_valid := false
var play_location: Vector3

var currently_hovered_unit: Unit = null

var current_ally_units: Array[Unit] = []
var current_enemy_units: Array[Unit] = []

var all_torches: Array[Torch] = []
var furthest_torch_lit := 0

func _ready() -> void:
	var player_deck := get_parent().get_node("DeckControl").get_node("Deck")
	var enemy_cards := randomize_new_enemy_deck(difficulty * 10, difficulty)
	$PlayerCombatDeck.prepare_combat_deck(player_deck.cards)
	$EnemyCombatDeck.prepare_combat_deck(enemy_cards)
	$Hand.initialize($PlayerCombatDeck)
	$Opponent/Hand.initialize($EnemyCombatDeck)

	set_process(true)
	$Camera3D.make_current()

	# spawn torch at player base, and enemy base
	var player_base_torch := torch_scene.instantiate()
	player_base_torch.position = player_base_torch_location.position
	add_child(player_base_torch)
	all_torches.append(player_base_torch)

	# set up the torches, spanning the width of the map from base to base
	var player_base_x: float = player_base_torch_location.position.x
	var enemy_base_x: float = enemy_base_torch_position.position.x
	var interval := (enemy_base_x - player_base_x) / (NUM_TORCHES + 1)

	# TODO: should spawn torches with fibonacci sequence so the furthest torch is the hardest to light
	for ndx in range(NUM_TORCHES):
		var torch := torch_scene.instantiate()
		torch.position = Vector3(player_base_x + interval * (ndx + 1), 0, (player_base_torch_location.position.z + enemy_base_torch_position.position.z) / 2.0)

		# a little hacky, but this assumes the player base torch is the first one so we add one
		torch.connect("torch_state_changed", _on_middle_area_torch_state_changed.bind(ndx + 1))

		(torch.get_node("CPUParticles3D") as CPUParticles3D).emitting = false
		(torch.get_node("OmniLight3D") as OmniLight3D).hide()
		(torch.get_node("MeshInstance3D").get_node("Area3D") as Area3D).connect("area_entered", _on_area_entered_torch.bind(torch))
		add_child(torch)
		all_torches.append(torch)

	var enemy_base_torch := torch_scene.instantiate()
	enemy_base_torch.position = enemy_base_torch_position.position
	enemy_base_torch.connect("torch_state_changed", _on_enemy_base_torch_state_changed)
	(enemy_base_torch.get_node("CPUParticles3D") as CPUParticles3D).emitting = false
	(enemy_base_torch.get_node("OmniLight3D") as OmniLight3D).hide()
	(enemy_base_torch.get_node("MeshInstance3D").get_node("Area3D") as Area3D).connect("area_entered", _on_area_entered_torch.bind(enemy_base_torch))
	add_child(enemy_base_torch)
	all_torches.append(enemy_base_torch)


func _on_area_entered_torch(area: Area3D, torch: Torch) -> void:
	if area is not Attackable:
		return
	var attackable := area as Attackable
	if attackable.team != Attackable.Team.PLAYER:
		return

	if attackable.get_parent() is Unit:
		var unit := attackable.get_parent() as Unit
		if !unit.can_light_torches:
			return
		unit.try_light_torch(torch)

func _on_hand_display_try_play_card(card: Card) -> void:
	reset_spawn_mesh()

	if not $Hand.can_play(card):
		return


	match card.type:
		Card.CardType.UNIT when play_location_valid:
			spawn_unit(unit_scene, card, play_location, Attackable.Team.PLAYER)
			$Hand.play_card(card)

		Card.CardType.SPELL:
			if card.spell.targetable_type == SpellList.TargetableType.NONE and play_location_valid:
				play_spell(card.spell)
				$Hand.play_card(card)
			elif currently_hovered_unit:
				play_spell(card.spell)
				$Hand.play_card(card)


func spawn_unit(unit_to_spawn: PackedScene, card_played: Card, unit_position: Vector3, team: Attackable.Team) -> void:
	var unit: Unit = unit_to_spawn.instantiate()
	# gotta add child early so ready is called
	add_child(unit)
	var random_z_offset := randf_range(-1, 1)
	var y := 0
	match card_played.creature.type:
		UnitList.CardType.AIR:
			y = 5
		_:
			y = 0
	unit.position = Vector3(unit_position.x, y, unit_position.z + random_z_offset)
	unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	if team == Attackable.Team.ENEMY:
		unit.get_node("TargetArea").scale.x *= -1
		unit.get_node("TargetArea").position.x *= -1
		unit.get_node("Attackable").scale.x *= -1
	unit.set_stats(card_played.creature, true if team == Attackable.Team.ENEMY else false)
	unit.unit_attackable.team = team

	if team == Attackable.Team.PLAYER:
		unit.furthest_x_position_allowed = all_torches[furthest_torch_lit + 1].position.x
		buff_units_from_unit(unit, current_ally_units)
		current_ally_units.append(unit)
	else:
		unit.furthest_x_position_allowed = all_torches[furthest_torch_lit].position.x
		buff_units_from_unit(unit, current_enemy_units)
		current_enemy_units.append(unit)

	unit.unit_attackable.connect("mouse_entered", _on_unit_mouse_entered.bind(unit))
	unit.unit_attackable.connect("mouse_exited", _on_unit_mouse_exited.bind(unit))
	unit.unit_attackable.connect("died", _on_unit_died.bind(unit))

	$HandDisplay.targetable_card_selected.connect(unit.make_selectable.bind(true))
	$HandDisplay.card_deselected.connect(unit.make_selectable.bind(false))

	if $HandDisplay.is_holding_targetable_spell():
		unit.make_selectable(true)

func _on_unit_died(unit: Unit) -> void:
	if unit.unit_attackable.team == Attackable.Team.PLAYER:
		remove_buffs_from_units_buffed_by_unit(unit, current_ally_units)
		current_ally_units.erase(unit)
	else:
		remove_buffs_from_units_buffed_by_unit(unit, current_ally_units)
		current_enemy_units.erase(unit)
		if unit == currently_hovered_unit:
			currently_hovered_unit = null

func buff_units_from_unit(buff_unit: Unit, units_to_buff: Array[Unit]) -> void:
	print("Checking if I should buff units with my buffs size of " + str(buff_unit.buffs_i_apply.size()))
	for unit in units_to_buff:
		if unit == buff_unit:
			continue
		for buff in buff_unit.buffs_i_apply:
			unit.apply_buff(buff)
		# we also need to apply the buffs from other units to the unit itself
		if unit.buffs_i_apply.size() > 0:
			for buff in unit.buffs_i_apply:
				buff_unit.apply_buff(buff)


# sorry for this naming lmfao, change it if you can think of something better
func remove_buffs_from_units_buffed_by_unit(buff_unit: Unit, units_buffed: Array[Unit]) -> void:
	if buff_unit.buffs_i_apply.size() == 0:
		return

	for unit in units_buffed:
		if unit == buff_unit:
			continue
		for buff in buff_unit.buffs_i_apply:
			unit.remove_buff(buff)

func _on_opponent_spawn(card: Card) -> void:
	var unit_x: float = enemy_base_torch_position.position.x + OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = enemy_base_torch_position.position.z
	spawn_unit(unit_scene, card, Vector3(unit_x, 0, unit_z), Attackable.Team.ENEMY)

func play_spell(spell: SpellList.Spell) -> void:
	print("Spell played")
	match spell.type:
		SpellList.SpellType.DAMAGE:
			if currently_hovered_unit:
				currently_hovered_unit.unit_attackable.take_damage(spell.value)
		SpellList.SpellType.HEAL:
			if currently_hovered_unit:
				currently_hovered_unit.unit_attackable.heal(spell.value)
		SpellList.SpellType.CUR_MANA:
			$Hand.cur_mana += spell.value
		SpellList.SpellType.MAX_MANA:
			$Hand.max_mana += spell.value
		SpellList.SpellType.DRAW_CARDS:
			$Hand.draw_cards(spell.value)

func _on_player_base_died() -> void:
	state = CombatState.LOST
	combat_over.emit(state)

func _on_middle_area_torch_state_changed(is_lit: bool, torch_lit_ndx: int) -> void:
	if not is_lit:
		return
	furthest_torch_lit = torch_lit_ndx

	for unit in current_ally_units:
		unit.furthest_x_position_allowed = all_torches[torch_lit_ndx + 1].position.x

	for unit in current_enemy_units:
		unit.furthest_x_position_allowed = all_torches[torch_lit_ndx].position.x

	var furthest_torch_x := all_torches[furthest_torch_lit].position.x

	# tween to new positions in parallel
	var tween: Tween = get_tree().create_tween();
	var new_size := Vector2(abs(furthest_torch_x - BATTLFIELD_START_X), BATTLFIELD_Z)
	var new_offset := Vector3(new_size.x / 2.0, 0.0, 0.0)
	tween.parallel().tween_property(spawn_mesh.mesh, "size", new_size, 1.0).set_trans(Tween.TRANS_CUBIC);
	tween.parallel().tween_property(spawn_mesh.mesh, "center_offset", new_offset, 1.0).set_trans(Tween.TRANS_CUBIC);

func _on_enemy_base_torch_state_changed(torch_lit: bool) -> void:
	if not torch_lit:
		return

	for unit in current_ally_units:
		unit.furthest_x_position_allowed = 1000.0;

	state = CombatState.WON
	provide_rewards()

func provide_rewards() -> void:
	reward_presented.emit()
	var best_enemy_cards: Array[Card] = $EnemyCombatDeck.get_best_cards(3)
	reward.add_card_offerings(best_enemy_cards)
	reward.show()
	$HandDisplay.queue_free()
	$Opponent.queue_free()


func _on_reward_reward_chosen(reward_data: Reward.RewardData) -> void:
	reward_chosen.emit(reward_data)
	combat_over.emit(state)


func _on_spawn_area_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if !$HandDisplay.clicked:
		return


	if event is not InputEventMouseMotion:
		return

	play_location = Vector3(event_position.x, 0, event_position.z);
	var type: Card.CardType = $HandDisplay.current_hover.type;

	match type:
		Card.CardType.SPELL:
			play_location_valid = true

		Card.CardType.UNIT:
			play_location_valid = event_position.x < all_torches[furthest_torch_lit].global_position.x

			if play_location_valid:
				spawn_mesh.material_override.set_shader_parameter("x_scale", spawn_mesh.mesh.size.x / spawn_mesh.mesh.size.y)
				spawn_mesh.material_override.set_shader_parameter("color", Color.GREEN)
				# spawn_mesh.material_override.set_shader_parameter("is_hovered", true)
				# spawn_mesh.material_override.set_shader_parameter("hover_loc", Vector2(relative_x_position, relative_z_position))
			else:
				reset_spawn_mesh()


func _on_spawn_area_mouse_exited() -> void:
	play_location_valid = false;
	reset_spawn_mesh()


func reset_spawn_mesh() -> void:
	spawn_mesh.material_override.set_shader_parameter("is_hovered", false)
	spawn_mesh.material_override.set_shader_parameter("color", original_spawn_mesh_color)


func _on_unit_mouse_entered(unit: Unit) -> void:
	if currently_hovered_unit != null:
		currently_hovered_unit.unhighlight_unit()

	# This check shouldn't be necessary if unit input handling has been removed properly
	# if drag_card != null and drag_card.type == Card.CardType.SPELL:
	currently_hovered_unit = unit
	unit.highlight_unit()

func _on_unit_mouse_exited(unit: Unit) -> void:
	if currently_hovered_unit == unit:
		currently_hovered_unit = null
		unit.unhighlight_unit()


func randomize_new_enemy_deck(strength_limit: int, single_card_strength_limit: int) -> Array[Card]:
	var new_deck: Array[Card] = []
	var total_strength := 0
	var strengh_limited_creatures: Array[UnitList.Creature] = UnitList.creature_cards.filter(func(card: UnitList.Creature) -> bool: return card.strength_factor <= single_card_strength_limit)
	while total_strength < strength_limit:
		var dict := strengh_limited_creatures[randi_range(0, strengh_limited_creatures.size() - 1)]
		total_strength += dict["strength_factor"]
		new_deck.append(UnitList.create_card(dict))
	return new_deck
