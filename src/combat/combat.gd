class_name Combat extends Node3D

@onready var unit_scene: PackedScene = preload("res://src/combat/unit.tscn")
@onready var reward := $Reward

signal reward_presented()
signal reward_chosen(reward: Reward.RewardData)
signal combat_over(combat_state: CombatState)

signal targetable_card_selected()
signal targetable_card_deselected()

enum CombatState {PLAYING, WON, LOST}

const ENEMY_SPAWN_TIMER := 400.0
const OFFSET_FROM_BASE_DISTANCE := 3

var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0
var difficulty := 1

var drag_card: Card = null
var drag_start_position: Vector2
var drag_spawn_position: Vector3
var drag_over_spawn_area := false

var currently_hovered_unit: Unit = null

func randomize_new_enemy_deck(strength_limit: int, single_card_strength_limit: int) -> Array[Card]:
	var new_deck: Array[Card] = []
	var total_strength := 0
	var strengh_limited_creatures: Array[UnitList.Creature] = UnitList.creature_cards.filter(func(card: UnitList.Creature) -> bool: return card.strength_factor <= single_card_strength_limit)
	while total_strength < strength_limit:
		var dict := strengh_limited_creatures[randi_range(0, strengh_limited_creatures.size() - 1)]
		total_strength += dict["strength_factor"]
		new_deck.append(UnitList.create_card(dict))
	return new_deck


func _ready() -> void:
	var player_deck := get_parent().get_node("DeckControl").get_node("Deck")
	var enemy_cards := randomize_new_enemy_deck(difficulty * 10, difficulty)
	$PlayerCombatDeck.prepare_combat_deck(player_deck.cards)
	$EnemyCombatDeck.prepare_combat_deck(enemy_cards)
	$PlayerHand.setup_deck($PlayerCombatDeck)
	$EnemyHand.setup_deck($EnemyCombatDeck)
	set_process(true)
	$Camera3D.make_current()

func _process(delta: float) -> void:
	if state != CombatState.PLAYING:
		return
	time_since_last_enemy_spawn += delta
	if time_since_last_enemy_spawn > ENEMY_SPAWN_TIMER:
		$EnemyHand.play_best_card()
		$EnemyHand.replenish_mana()
		time_since_last_enemy_spawn = 0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
		try_play_card()

	if event is InputEventMouseMotion and drag_card:
		draw_drag_line(event)

func try_play_card() -> void:
	if not drag_card:
		return

	match drag_card.type:
		Card.CardType.UNIT:
			if drag_over_spawn_area:
				spawn_unit(unit_scene, drag_card, drag_spawn_position, Attackable.Team.PLAYER)
				$PlayerHand.play_card(drag_card)
		Card.CardType.SPELL:
			# TODO: further logic for if a spell affects a unit
			if currently_hovered_unit:
				play_spell(drag_card.spell)
				$PlayerHand.play_card(drag_card)
			targetable_card_deselected.emit()

	drag_card = null;
	drag_over_spawn_area = false;
	$DragLine.clear_points();

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
	unit.unit_attackable.connect("mouse_entered", _on_unit_mouse_entered.bind(unit))
	unit.unit_attackable.connect("mouse_exited", _on_unit_mouse_exited.bind(unit))
	connect("targetable_card_selected", unit.make_selectable.bind(true))
	connect("targetable_card_deselected", unit.make_selectable.bind(false))

func spawn_enemy(card: Card) -> void:
	var unit_x: float = $EnemyBase.position.x - OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $EnemyBase.position.z
	spawn_unit(unit_scene, card, Vector3(unit_x, 0, unit_z), Attackable.Team.ENEMY)

func play_spell(spell: SpellList.Spell) -> void:
	print("Spell played")
	match spell.type:
		SpellList.SpellType.DAMAGE:
			if currently_hovered_unit:
				currently_hovered_unit.unit_attackable.take_damage(5)
		SpellList.SpellType.HEAL:
			if currently_hovered_unit:
				currently_hovered_unit.unit_attackable.heal(5)

func _on_player_base_died() -> void:
	state = CombatState.LOST
	combat_over.emit(state)

func _on_enemy_base_died() -> void:
	state = CombatState.WON
	provide_rewards()

func provide_rewards() -> void:
	reward_presented.emit()
	var best_enemy_cards: Array[Card] = $EnemyCombatDeck.get_best_cards(3)
	reward.add_card_offerings(best_enemy_cards)
	reward.show()
	$PlayerHand.queue_free()
	$EnemyHand.queue_free()

func _on_reward_reward_chosen(reward_data: Reward.RewardData) -> void:
	reward_chosen.emit(reward_data)
	combat_over.emit(state)

func _on_player_hand_card_clicked(card: Card) -> void:
	drag_card = card
	if card.type == Card.CardType.SPELL:
		targetable_card_selected.emit()
	drag_start_position = card.global_position + card.size / 2.0

func _on_spawn_area_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseMotion and drag_card:
		drag_spawn_position = Vector3(event_position.x, 0, event_position.z);

func _on_spawn_area_mouse_entered() -> void:
	if !drag_card:
		return

	drag_over_spawn_area = true;

func _on_spawn_area_mouse_exited() -> void:
	drag_over_spawn_area = false;

func _on_unit_mouse_entered(unit: Unit) -> void:
	if currently_hovered_unit != null:
		currently_hovered_unit.unhighlight_unit()

	if drag_card != null and drag_card.type == Card.CardType.SPELL:
		currently_hovered_unit = unit
		unit.highlight_unit()

func _on_unit_mouse_exited(unit: Unit) -> void:
	if currently_hovered_unit == unit:
		currently_hovered_unit = null
		unit.unhighlight_unit()


func draw_drag_line(event: InputEvent) -> void:
	$DragLine.clear_points();

	var current_position := drag_start_position;
	var direction := drag_start_position.direction_to(event.position)
	var total_distance := drag_start_position.distance_to(event.position)

	while current_position.distance_to(event.position) > 0.5:
		if current_position.distance_to(event.position) < 10:
			current_position = event.position
		else:
			current_position += direction * 10;

		var normal := Vector2(direction.y, -direction.x);
		if event.position.x < drag_start_position.x:
			normal *= -1;

		var progress: float = current_position.distance_to(drag_start_position) / total_distance;
		var quadriatic: float = -4 * progress * (progress - 1);

		$DragLine.add_point(current_position + normal * quadriatic * 100);
		# $DragLine.add_point(current_position);
