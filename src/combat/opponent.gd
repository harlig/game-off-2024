class_name Opponent extends Node

@onready var hand := $Hand

var difficulty: int:
	set(value):
		difficulty = value
		hand.max_mana += difficulty - 1

var spawn_interval := 5.0
var should_spawn := true
var play_timer := 0.0 # running timer
var playing_cards := false
var current_units: Array[Unit] = []

signal spawn(card: Card)

func _ready() -> void:
	adjust_spawn_interval()
	hand.max_mana += difficulty - 1

func adjust_spawn_interval() -> void:
	match difficulty:
		1:
			spawn_interval = 17.0
		2:
			spawn_interval = 14.0
		3:
			spawn_interval = 10.0
		4:
			spawn_interval = 7.0
		5:
			spawn_interval = 5.0

func _process(delta: float) -> void:
	if not should_spawn:
		return

	if playing_cards:
		return

	play_timer -= delta
	if play_timer > 0:
		return

	if hand.cur_mana > 0:
		try_play_cards()

	adjust_spawn_interval()

func try_play_cards() -> void:
	var max_units_to_play_at_once := difficulty + 1
	playing_cards = true

	var cards: Array[Card] = hand.cards
	cards.sort_custom(Card.compare_by_mana)
	var cards_played := 0

	for card: Card in cards:
		if cards_played >= max_units_to_play_at_once:
			break

		# don't spawn this card if it's a healer and all our units on the board are healer
		if card.creature != null and card.creature.type == UnitList.CardType.HEALER and current_units.all(func(unit: Unit) -> bool: return unit.unit_type == UnitList.CardType.HEALER):
			continue

		if hand.can_play(card):
			hand.play_card(card)
			spawn.emit(card)
			# wait between each card played this turn to mimic human behavior
			await get_tree().create_timer(randf_range(1.5, 3.5), false).timeout
			cards_played += 1
		else:
			# randomly decide whether to wait for the next play
			if randi() % 2 == 0:
				break

	# set timer for next play
	play_timer = randf_range(spawn_interval * 0.8, spawn_interval * 1.2)
	playing_cards = false


func play_one_card() -> void:
	var card: Card = hand.cards[0]
	hand.play_card(card)
	spawn.emit(card)


func set_units(units: Array[Unit]) -> void:
	current_units = units
