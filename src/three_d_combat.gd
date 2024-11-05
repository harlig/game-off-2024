class_name ThreeDCombat extends Node3D

@onready var unit: PackedScene = preload("res://src/three_d_unit.tscn")
@onready var card_scene := preload("res://src/card.tscn")
@onready var reward := $Reward

signal combat_over(combat_state: CombatState)
signal reward_chosen(reward: Reward.RewardData)

enum CombatState {PLAYING, WON, LOST}

const REFRESH_TIMEOUT = 10.0
const ENEMY_SPAWN_TIMER := 400.0
const OFFSET_FROM_BASE_DISTANCE := 3

var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0

var can_refresh := false
var refresh_time_left: float = REFRESH_TIMEOUT
var difficulty := 1

var creature_cards: Array[Dictionary] = [
	{"name": "Shriekling", "type": "Air", "health": 1, "damage": 2, "mana": 2, "strength_factor": 4, "card_image_path": "res://textures/units/cricket.png"}, # 0
	{"name": "Murkmouth", "type": "Melee", "health": 3, "damage": 3, "mana": 3, "strength_factor": 6, "card_image_path": "res://textures/units/hand_crawler.png"}, # 1
	{"name": "Wraithvine", "type": "Ranged", "health": 2, "damage": 4, "mana": 3, "strength_factor": 7, "card_image_path": "res://logo.png"}, # 2
	{"name": "Gloom", "type": "Air", "health": 1, "damage": 2, "mana": 1, "strength_factor": 1, "card_image_path": "res://logo.png"}, # 3
	{"name": "Hollowstalkers", "type": "Melee", "health": 4, "damage": 3, "mana": 4, "strength_factor": 8, "card_image_path": "res://textures/units/cricket.png"}, # 4
	{"name": "Sablemoth", "type": "Air", "health": 2, "damage": 1, "mana": 1, "strength_factor": 2, "card_image_path": "res://logo.png"}, # 5
	{"name": "Creep", "type": "Melee", "health": 1, "damage": 1, "mana": 1, "strength_factor": 1, "card_image_path": "res://textures/units/cricket.png"}, # 6
	{"name": "Netherlimbs", "type": "Melee", "health": 5, "damage": 5, "mana": 5, "strength_factor": 9, "card_image_path": "res://logo.png"}, # 7
	{"name": "Phantom Husk", "type": "Ranged", "health": 2, "damage": 3, "mana": 2, "strength_factor": 6, "card_image_path": "res://textures/units/cricket.png"}, # 8
	{"name": "Spindler", "type": "Ranged", "health": 1, "damage": 2, "mana": 2, "strength_factor": 4, "card_image_path": "res://textures/units/hand_crawler.png"}, # 9
	{"name": "Nightclaw", "type": "Melee", "health": 3, "damage": 4, "mana": 4, "strength_factor": 7, "card_image_path": "res://textures/units/cricket.png"}, # 10
	{"name": "Rotling", "type": "Melee", "health": 2, "damage": 2, "mana": 2, "strength_factor": 5, "card_image_path": "res://logo.png"}, # 11
	{"name": "Dreadroot", "type": "Ranged", "health": 3, "damage": 3, "mana": 3, "strength_factor": 6, "card_image_path": "res://textures/units/cricket.png"}, # 12
	{"name": "Haunt", "type": "Air", "health": 1, "damage": 2, "mana": 2, "strength_factor": 4, "card_image_path": "res://logo.png"}, # 13
	{"name": "Cryptkin", "type": "Melee", "health": 1, "damage": 2, "mana": 1, "strength_factor": 1, "card_image_path": "res://textures/units/cricket.png"}, # 14
	{"name": "Soul Devourer", "type": "Melee", "health": 8, "damage": 9, "mana": 8, "strength_factor": 10, "card_image_path": "res://textures/units/hand_crawler.png"}, # 15
	{"name": "Void Tyrant", "type": "Air", "health": 6, "damage": 7, "mana": 7, "strength_factor": 9, "card_image_path": "res://logo.png"}, # 16
	{"name": "Shadow Colossus", "type": "Ranged", "health": 7, "damage": 6, "mana": 6, "strength_factor": 9, "card_image_path": "res://logo.png"}, # 17
	{"name": "Ebon Phantom", "type": "Air", "health": 5, "damage": 8, "mana": 8, "strength_factor": 9, "card_image_path": "res://textures/units/hand_crawler.png"}, # 18
	{"name": "Abyssal Fiend", "type": "Melee", "health": 10, "damage": 10, "mana": 10, "strength_factor": 10, "card_image_path": "res://textures/units/hand_crawler.png"} # 19
]


func new_card_from_dict(data: Dictionary) -> Card:
	var newCard := create_card(
			data["health"], # max_health
			data["health"], # health
			data["mana"], # mana
			data["damage"], # damage
			data["name"], # card_name
			data["card_image_path"]
	)
	return newCard

func create_card(
	new_max_health: int,
	new_health: int,
	new_mana: int,
	new_damage: int,
	new_card_name: String,
	new_card_image_path: String
) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_stats(
		new_max_health,
		new_health,
		new_mana,
		new_damage,
		new_card_name,
		new_card_image_path
	)
	return card_instance


func randomize_new_enemy_deck(strength_limit: int, single_card_strength_limit: int) -> Array[Card]:
	print("Strength Limit:" + str(strength_limit) + " Difficulty: " + str(single_card_strength_limit))
	var new_deck: Array[Card] = []
	var total_strength := 0
	var strengh_limited_creatures: Array[Dictionary] = creature_cards.filter(func(card: Dictionary) -> bool: return card["strength_factor"] <= single_card_strength_limit)
	while total_strength < strength_limit:
		var dict := strengh_limited_creatures[randi_range(0, strengh_limited_creatures.size() - 1)]
		total_strength += dict["strength_factor"]
		new_deck.append(new_card_from_dict(dict))
	return new_deck


func _ready() -> void:
	print("ready")
	var player_deck := get_parent().get_node("DeckControl").get_node("Deck")
	var enemy_cards := randomize_new_enemy_deck(difficulty * 10, difficulty)
	$PlayerCombatDeck.prepare_combat_deck(player_deck.cards)
	$EnemyCombatDeck.prepare_combat_deck(enemy_cards)
	$PlayerHand.setup_deck($PlayerCombatDeck)
	$EnemyHand.setup_deck($EnemyCombatDeck)
	$RefreshControl/Label.text = str(refresh_time_left + 1)
	set_process(true)
	$Camera3D.make_current()

func testOrder() -> void:
	print("test")

func _process(delta: float) -> void:
	if state != CombatState.PLAYING:
		return
	time_since_last_enemy_spawn += delta
	if time_since_last_enemy_spawn > ENEMY_SPAWN_TIMER:
		print("Play enemy")
		$EnemyHand.play_best_card()
		$EnemyHand.replenish_mana()
		time_since_last_enemy_spawn = 0

	# update refresh timer
	refresh_time_left -= delta
	if refresh_time_left <= 0:
		on_refresh_timeout()
	else:
		$RefreshControl/Label.text = str(int(refresh_time_left + 1))

func on_refresh_timeout() -> void:
	can_refresh = true
	refresh_time_left = REFRESH_TIMEOUT
	$RefreshControl/Button.disabled = false
	$RefreshControl/Label.text = str(refresh_time_left + 1)

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector3, team: ThreeDAttackable.Team) -> ThreeDUnit:
	var new_unit: ThreeDUnit = unit_to_spawn.instantiate()
	new_unit.position = unit_position
	new_unit.direction = ThreeDUnit.Direction.RIGHT if team == ThreeDAttackable.Team.PLAYER else ThreeDUnit.Direction.LEFT
	if team == ThreeDAttackable.Team.ENEMY:
		new_unit.get_node("TargetArea").scale.x *= -1
		new_unit.get_node("Attackable").scale.x *= -1
	new_unit.get_node("Attackable").team = team
	add_child(new_unit)
	return new_unit

func _on_player_hand_card_played(played_card: Card) -> void:
	var unit_x: float = $PlayerBase.position.x + OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $PlayerBase.position.z
	var created_unit: ThreeDUnit = spawn_unit(unit, Vector3(unit_x, 0, unit_z), ThreeDAttackable.Team.ENEMY)
	print("Spawned unit at: " + str(created_unit.position))
	print("Player base position at: " + str($PlayerBase.position))
	created_unit.set_stats(played_card.data)

func _on_enemy_hand_card_played(played_card: Card) -> void:
	var unit_x: float = $EnemyBase.position.x - OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $EnemyBase.position.z
	var created_unit: ThreeDUnit = spawn_unit(unit, Vector3(unit_x, 0, unit_z), ThreeDAttackable.Team.ENEMY)
	created_unit.set_stats(played_card.data, true)


func _on_player_base_died() -> void:
	state = CombatState.LOST
	$RefreshControl.hide()
	combat_over.emit(state)


func _on_enemy_base_died() -> void:
	state = CombatState.WON
	$RefreshControl.hide()
	provide_rewards()

func provide_rewards() -> void:
	var best_enemy_cards: Array[Card] = $EnemyCombatDeck.get_best_cards(3)
	reward.add_card_offerings(best_enemy_cards)
	reward.show()
	$PlayerHand.queue_free()
	$EnemyHand.queue_free()

func _on_refresh_button_pressed() -> void:
	if not can_refresh:
		return

	can_refresh = false
	$RefreshControl/Button.disabled = true
	$PlayerHand.refresh_hand()

func _on_reward_reward_chosen(reward_data: Reward.RewardData) -> void:
	reward_chosen.emit(reward_data)
	combat_over.emit(state)
