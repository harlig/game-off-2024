class_name Opponent extends Node

@onready var hand := $Hand

var spawn_interval := 5.0
var should_spawn := true
var play_delay := 1.0 # Delay between plays
var play_timer := 0.0 # Running timer
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
	# TODO: try to play highest mana card first. if I can't play a high mana card, randomly decide if I want to return and wait for next play so I can try a high mana card again
	for card: Card in hand.cards:
		if hand.can_play(card):
			hand.play_card(card)
			spawn.emit(card)
			# wait between each card played this turn to mimic human behavior
			await get_tree().create_timer(randf_range(0.5, 1.5)).timeout

	# set timer for next play
	play_timer = randf_range(1.5, 2.5)
	playing_cards = false
