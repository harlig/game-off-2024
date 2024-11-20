class_name Opponent extends Node

@onready var hand := $Hand

var spawn_interval := 5.0
var should_spawn := true

signal spawn(card: Card)

func _process(delta: float) -> void:
	if not should_spawn:
		return

	if hand.cur_mana > 0:
		try_play_cards()

	await get_tree().create_timer(spawn_interval).timeout

func try_play_cards() -> void:
	while hand.cur_mana > 0 and not hand.cards.is_empty():
		var card_played := false
		for card: Card in hand.cards:
			if hand.can_play(card):
				hand.play_card(card)
				spawn.emit(card)
				card_played = true
				await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
				break
		if not card_played:
			break
