class_name Combat extends Node3D

const combat_scene := preload("res://src/combat/combat.tscn")
const unit_scene: PackedScene = preload("res://src/combat/unit.tscn")
const torch_scene: PackedScene = preload("res://src/torch.tscn")

@onready var reward := $Reward
@onready var spawn_mesh: MeshInstance3D = $SpawnMesh
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

var relics: Array[Relic] = []

var player_combat_deck: CombatDeck
var enemy_combat_deck: CombatDeck

var torches_player_has_lit: Array[Torch] = []

####################################################
####################################################
# This is how you should instantiate a combat scene
####################################################
####################################################
static func create_combat(combat_difficulty: int, relics_for_combat: Array[Relic]) -> Combat:
	var combat_instance: Combat = combat_scene.instantiate()
	combat_instance.difficulty = combat_difficulty
	combat_instance.relics = relics_for_combat
	return combat_instance
####################################################
####################################################
####################################################
####################################################


func _ready() -> void:
	var player_deck := get_parent().get_node("DeckControl").get_node("Deck")
	var enemy_cards := randomize_new_enemy_deck(difficulty * 200, difficulty * 50)
	player_combat_deck = CombatDeck.create_combat_deck(player_deck.cards, relics)
	enemy_combat_deck = CombatDeck.create_combat_deck(enemy_cards)
	add_child(player_combat_deck)
	add_child(enemy_combat_deck)

	# TODO: Oof the second arg, let's fix this at some point
	$Hand.initialize(player_combat_deck, relics.filter(func(relic: Relic) -> bool: return relic.relic_name == 'Torchlighter Relic').size() > 0)
	$Opponent/Hand.initialize(enemy_combat_deck)

	set_process(true)
	$Camera3D.make_current()

	# spawn torch at player base, and enemy base
	var player_base_torch := torch_scene.instantiate()
	player_base_torch.is_lit = true
	player_base_torch.position = player_base_torch_location.position
	player_base_torch.connect("torch_state_changed", _on_player_base_torch_state_changed)
	(player_base_torch.get_node("MeshInstance3D").get_node("Area3D") as Area3D).connect("area_entered", _on_area_entered_torch.bind(player_base_torch))
	add_child(player_base_torch)
	all_torches.append(player_base_torch)
	torches_player_has_lit.append(player_base_torch)

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

	if attackable.get_parent() is Unit:
		var unit := attackable.get_parent() as Unit
		if !unit.can_change_torches:
			return
		if attackable.team == Attackable.Team.PLAYER:
			unit.try_light_torch(torch)
		else:
			unit.try_extinguish_torch(torch)


# Attempt to play card and return whether it was played
func try_play_card(card: Card) -> bool:
	$SpawnLocMesh.hide()

	if not $Hand.can_play(card):
		return false

	# need to set this before we potentially await something in the secret code since the validity of the play location could change when player moves mouse, but we should still respect the validity pre-timeout
	var play_location_valid_before_timeout := play_location_valid

	if card.is_secret:
		$HandDisplay.reveal_secret(card)
		get_tree().paused = true
		await $HandDisplay.secret_acknowledged
		get_tree().paused = false

	var played := false
	match card.type:
		Card.CardType.UNIT when play_location_valid_before_timeout:
			spawn_unit(unit_scene, card, play_location, Attackable.Team.PLAYER)
			$Hand.play_card(card)
			played = true

		Card.CardType.SPELL:
			if card.is_none_spell():
				play_spell(card.spell)
				$Hand.play_card(card)
				played = true

			elif card.is_unit_spell():
				play_spell(card.spell)
				$Hand.play_card(card)
				played = true

			elif card.is_area_spell() and play_location_valid_before_timeout:
				#TODO
				pass ;

	return played


func spawn_unit(unit_to_spawn: PackedScene, card_played: Card, unit_position: Vector3, team: Attackable.Team) -> void:
	var unit: Unit = unit_to_spawn.instantiate()
	# gotta add child early so ready is called
	add_child(unit)
	var y := 0
	match card_played.creature.type:
		UnitList.CardType.AIR:
			y = 5
		_:
			y = 0
	unit.position = Vector3(unit_position.x, y, unit_position.z)
	unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
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

		# all enemies can extinguish torches
		unit.can_change_torches = true

		unit.get_node("TargetArea").scale.x *= -1
		unit.get_node("TargetArea").position.x *= -1
		unit.get_node("Attackable").scale.x *= -1
		unit.get_node("Label3D").position.x *= -1

	unit.unit_attackable.connect("mouse_entered", _on_unit_mouse_entered.bind(unit))
	unit.unit_attackable.connect("mouse_exited", _on_unit_mouse_exited.bind(unit))
	unit.unit_attackable.connect("died", _on_unit_died.bind(unit))

	$HandDisplay.unit_spell_selected.connect(unit.make_selectable.bind(true))
	$HandDisplay.card_deselected.connect(unit.make_selectable.bind(false))

	if $HandDisplay.current_selected and $HandDisplay.current_selected.is_unit_spell():
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
	match spell.type:
		SpellList.SpellType.DAMAGE:
			if currently_hovered_unit:
				currently_hovered_unit.unit_attackable.take_damage(round(spell.value))
		SpellList.SpellType.HEAL:
			if currently_hovered_unit:
				currently_hovered_unit.unit_attackable.heal(round(spell.value))
		SpellList.SpellType.CUR_MANA:
			$Hand.cur_mana += spell.value
		SpellList.SpellType.MAX_MANA:
			$Hand.max_mana += spell.value
		SpellList.SpellType.MANA_REGEN:
			$Hand.mana_time /= spell.value
		SpellList.SpellType.DRAW_CARDS:
			$Hand.draw_cards(spell.value)
		SpellList.SpellType.DRAW_CARDS_REGEN:
			$Hand.draw_time /= spell.value

func deal_secret() -> void:
	# TODO: play audio cue here
	$Hand.add_secret(Card.random_secret_card())

func _on_middle_area_torch_state_changed(is_lit: bool, torch_changed_ndx: int) -> void:
	furthest_torch_lit = torch_changed_ndx if is_lit else torch_changed_ndx - 1
	var torch := all_torches[furthest_torch_lit]

	# make opponent spawn interval faster if torch is lit, slower if it's extinguished
	if is_lit:
		$Opponent.spawn_interval -= 0.5

		# if player hasn't already lit this torch, give them a secret
		if torch not in torches_player_has_lit:
			torches_player_has_lit.append(torch)
			deal_secret()
	else:
		$Opponent.spawn_interval += 0.25

	for unit in current_ally_units:
		unit.furthest_x_position_allowed = all_torches[furthest_torch_lit + 1].position.x

	for unit in current_enemy_units:
		unit.furthest_x_position_allowed = torch.position.x

	var furthest_torch_x := torch.position.x

	# tween to new positions in parallel
	var tween: Tween = get_tree().create_tween();
	var new_size := Vector2(abs(furthest_torch_x - BATTLFIELD_START_X), BATTLFIELD_Z)
	var new_offset := Vector3(new_size.x / 2.0, 0.0, 0.0)
	tween.parallel().tween_property(spawn_mesh.mesh, "size", new_size, 1.0).set_trans(Tween.TRANS_CUBIC);
	tween.parallel().tween_property(spawn_mesh.mesh, "center_offset", new_offset, 1.0).set_trans(Tween.TRANS_CUBIC);
	print("New spawn mesh size is " + str(new_size) + " and offset is " + str(new_offset))

func _on_player_base_torch_state_changed(torch_lit: bool) -> void:
	# this should always be false
	if torch_lit:
		push_error("Player base torch should never become lit after it's been extinguished")
		return
	finish_combat(CombatState.LOST)

func _on_enemy_base_torch_state_changed(torch_lit: bool) -> void:
	if not torch_lit:
		return
	for unit in current_ally_units:
		unit.furthest_x_position_allowed = 1000.0;
	finish_combat(CombatState.WON)

func finish_combat(new_state: CombatState) -> void:
	state = new_state

	$HandDisplay.hide()
	$Opponent.should_spawn = false

	if state == CombatState.WON:
		provide_rewards()
	else:
		show_combat_lost()

func provide_rewards() -> void:
	reward_presented.emit()
	var best_enemy_cards: Array[Card] = enemy_combat_deck.get_best_cards(3)
	reward.add_card_offerings(best_enemy_cards)
	reward.show()
	$HandDisplay.queue_free()
	$Opponent.queue_free()

func show_combat_lost() -> void:
	$Lost.show()

func _on_reward_reward_chosen(reward_data: Reward.RewardData) -> void:
	reward_chosen.emit(reward_data)
	combat_over.emit(state)

func _on_spawn_area_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# check if it's null in case the hand display is destroyed
	if get_node_or_null("HandDisplay") == null or !$HandDisplay.current_selected:
		return

	if event is not InputEventMouseMotion:
		return

	play_location = Vector3(event_position.x, 0, event_position.z);
	var type: Card.CardType = $HandDisplay.current_selected.type;

	match type:
		Card.CardType.SPELL:
			play_location_valid = true

		Card.CardType.UNIT:
			play_location_valid = event_position.x < all_torches[furthest_torch_lit].global_position.x

			if play_location_valid:
				$SpawnLocMesh.show()
				$SpawnLocMesh.global_transform.origin = Vector3(event_position.x, 0, event_position.z)


func _on_spawn_area_mouse_exited() -> void:
	play_location_valid = false;
	$SpawnLocMesh.hide()


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
	var strengh_limited_creatures: Array[UnitList.Creature] = UnitList.creature_cards.filter(func(creature: UnitList.Creature) -> bool: return creature.strength_factor <= single_card_strength_limit)
	while total_strength < strength_limit:
		var creature := strengh_limited_creatures[randi_range(0, strengh_limited_creatures.size() - 1)]
		total_strength += creature.strength_factor
		new_deck.append(Card.create_creature_card(creature))
	return new_deck


func _on_combat_lost_button_pressed() -> void:
	combat_over.emit(state)


func _on_hand_mana_updated(_cur: int, _max: int) -> void:
	if play_location_valid:
		pass ;
