class_name Opponent extends Node

@onready var hand := $Hand

var spawn_interval := 5.0
var should_spawn := true
var play_delay := 1.0 # delay between plays
var play_timer := 0.0 # running timer
var playing_cards := false

signal spawn(card: Card)

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


func try_play_cards() -> void:
	playing_cards = true

	var cards: Array[Card] = hand.cards
	cards.sort_custom(Card.compare_by_mana)

	for card: Card in cards:
		if hand.can_play(card):
			hand.play_card(card)
			spawn.emit(card)
			# wait between each card played this turn to mimic human behavior
			await get_tree().create_timer(randf_range(1.5, 3.5)).timeout
		else:
			# randomly decide whether to wait for the next play
			if randi() % 2 == 0:
				break

	# set timer for next play
	play_timer = randf_range(4.5, 8.5)
	playing_cards = false
