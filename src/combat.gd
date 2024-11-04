class_name Combat extends Node2D

@export var unit: PackedScene

signal combat_over(combat_state: CombatState)
signal reward_chosen(card: Card)

enum CombatState {PLAYING, WON, LOST}

const REFRESH_TIMEOUT = 10.0

var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0

var can_refresh := false
var refresh_time_left: float = REFRESH_TIMEOUT

func _ready() -> void:
	$PlayerHand.setup_deck($PlayerCombatDeck)
	$EnemyHand.setup_deck($EnemyCombatDeck)
	$RefreshControl/Label.text = str(refresh_time_left + 1)
	set_process(true)

func _process(delta: float) -> void:
	if state != CombatState.PLAYING:
		return
	# every 5 seconds spawn an enemy's best card
	time_since_last_enemy_spawn += delta
	if time_since_last_enemy_spawn > 5:
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

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector2, team: Attackable.Team) -> Unit:
	var new_unit: Unit = unit_to_spawn.instantiate()
	new_unit.position = unit_position
	new_unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	new_unit.get_node("TargetArea").scale.x = 1 if team == Attackable.Team.PLAYER else -1
	new_unit.get_node("Attackable").team = team
	add_child(new_unit)
	return new_unit

func _on_player_hand_card_played(played_card: Card) -> void:
	var unit_position: Vector2 = $PlayerBase.position + Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5
	var created_unit: Unit = spawn_unit(unit, unit_position, Attackable.Team.PLAYER)
	created_unit.set_stats(played_card.data)

func _on_enemy_hand_card_played(played_card: Card) -> void:
	var unit_position: Vector2 = $EnemyBase.position - Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5
	var created_unit: Unit = spawn_unit(unit, unit_position, Attackable.Team.ENEMY)
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
	for card: Card in best_enemy_cards:
		var card_offered := card.duplicate()
		card_offered.data = card.data
		card_offered.connect("card_clicked", _on_reward_clicked)
		$Reward.add_child(card_offered)
	$PlayerHand.queue_free()
	$EnemyHand.queue_free()

var last_clicked_reward_card: Card = null

func _on_reward_clicked(times_clicked: int, reward_card: Card) -> void:
	if last_clicked_reward_card and last_clicked_reward_card != reward_card:
		last_clicked_reward_card.reset_selected()

	last_clicked_reward_card = reward_card

	if times_clicked == 2:
		reward_card.reset_selected()
		reward_chosen.emit(reward_card)
		combat_over.emit(state)


func _on_refresh_button_pressed() -> void:
	if not can_refresh:
		return

	can_refresh = false
	$RefreshControl/Button.disabled = true
	$PlayerHand.refresh_hand()
