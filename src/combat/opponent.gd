class_name Opponent extends Node;

const SPAWN_INTERVAL := 4.0

@onready var hand := $Hand;

var spawn_time_remaining := SPAWN_INTERVAL

signal spawn(card: Card)

func _process(delta: float) -> void:
	spawn_time_remaining -= delta

	if spawn_time_remaining <= 0.0:
		try_play_card()


func try_play_card() -> void:
	for card: Card in hand.cards:
		if hand.can_play(card):
			hand.play_card(card)
			spawn_time_remaining = SPAWN_INTERVAL;
			spawn.emit(card);
			return
