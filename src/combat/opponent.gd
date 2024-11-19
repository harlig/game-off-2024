class_name Opponent extends Node;

@onready var hand := $Hand;

var spawn_interval := 5.0:
	set(value):
		# enemies can't spawn more than once per two seconds
		spawn_interval = max(value, 2.0)
# spawn first unit after 1s
var spawn_time_remaining := 3.0
var should_spawn := true

signal spawn(card: Card)

func _process(delta: float) -> void:
	if not should_spawn:
		return
	spawn_time_remaining -= delta

	if should_spawn and spawn_time_remaining <= 0.0:
		try_play_card()


func try_play_card() -> void:
	for card: Card in hand.cards:
		if hand.can_play(card):
			hand.play_card(card)
			spawn_time_remaining = spawn_interval;
			spawn.emit(card);
			return
