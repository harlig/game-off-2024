class_name Combat extends Node3D

@onready var unit: PackedScene = preload("res://src/unit.tscn")
@onready var card_scene := preload("res://src/card.tscn")
@onready var reward := $Reward

signal combat_over(combat_state: CombatState)
signal reward_chosen(reward: Reward.RewardData)

enum CombatState {PLAYING, WON, LOST}

const REFRESH_TIMEOUT = 10.0
const ENEMY_SPAWN_TIMER := 4.0
const OFFSET_FROM_BASE_DISTANCE := 3


var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0

var can_refresh := false
var refresh_time_left: float = REFRESH_TIMEOUT
var difficulty := 1


func randomize_new_enemy_deck(strength_limit: int, single_card_strength_limit: int) -> Array[Card]:
	print("Strength Limit:" + str(strength_limit) + " Difficulty: " + str(single_card_strength_limit))
	var new_deck: Array[Card] = []
	var total_strength := 0
	var strengh_limited_creatures: Array[Dictionary] = UnitList.creature_cards.filter(func(card: Dictionary) -> bool: return card["strength_factor"] <= single_card_strength_limit)
	while total_strength < strength_limit:
		var dict := strengh_limited_creatures[randi_range(0, strengh_limited_creatures.size() - 1)]
		total_strength += dict["strength_factor"]
		new_deck.append(UnitList.new_card_from_dict(dict))
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

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector3, team: Attackable.Team, card_data: Card.Data) -> Unit:
	var new_unit: Unit = unit_to_spawn.instantiate()
	var random_z_offset := randf_range(-1, 1)
	var y := 0
	match card_data.card_type:
		UnitList.card_type.AIR:
			y = 5
		_:
			y = 0
	new_unit.position = Vector3(unit_position.x, y, unit_position.z + random_z_offset)
	new_unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	resize_unit_target_box(new_unit, card_data)
	if team == Attackable.Team.ENEMY:
		new_unit.get_node("TargetArea").scale.x *= -1
		new_unit.get_node("TargetArea").position.x *= -1
		new_unit.get_node("Attackable").scale.x *= -1
	new_unit.get_node("Attackable").team = team
	add_child(new_unit)
	return new_unit

func _on_player_hand_card_played(played_card: Card) -> void:
	var unit_x: float = $PlayerBase.position.x + OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $PlayerBase.position.z
	var created_unit: Unit = spawn_unit(unit, Vector3(unit_x, 0, unit_z), Attackable.Team.PLAYER, played_card.data)
	created_unit.set_stats(played_card.data)

func _on_enemy_hand_card_played(played_card: Card) -> void:
	var unit_x: float = $EnemyBase.position.x - OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $EnemyBase.position.z
	var created_unit: Unit = spawn_unit(unit, Vector3(unit_x, 0, unit_z), Attackable.Team.ENEMY, played_card.data)
	created_unit.set_stats(played_card.data, true)

func resize_unit_target_box(unit_to_change: Unit, card_data: Card.Data) -> void:
	# Get the CollisionShape3D node
	var collision_shape: CollisionShape3D = unit_to_change.get_node("TargetArea").get_node("CollisionShape3D")
	# Check if the shape is a BoxShape3D
	if collision_shape.shape is BoxShape3D:
		# Cast the shape to a BoxShape3D and modify its size
		var box_shape: BoxShape3D = collision_shape.shape 

		var x := box_shape.size.x 
		var y := box_shape.size.y 
		var z := box_shape.size.z 
		var new_box_shape := BoxShape3D.new()
		match card_data.card_type:
			UnitList.card_type.AIR:
				y = 100
			UnitList.card_type.RANGED:
				x = 15
				y = 100

		new_box_shape.size = Vector3(x, y, z)  # Set the new size
		collision_shape.shape = new_box_shape


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
