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
	for card: Card in hand.cards_in_hand:
		if hand.can_play(card):
			hand.play_card(card)
			spawn_time_remaining = SPAWN_INTERVAL;
			spawn.emit(card);
			return


# func play_best_card() -> void:
#     if hand.is_empty():
#         return ;

# 	replenish_mana()
# 	var best_card: Card = null
# 	var best_card_value: float = -1
# 	for card in cards_in_hand:
# 		var card_value: float = card.get_score()
# 		if card_value > best_card_value:
# 			best_card = card
# 			best_card_value = card_value
# 	if best_card and cur_mana >= best_card.mana:
# 		print(best_card.name)
# 		get_parent().spawn_enemy(best_card)
# 		play_card(best_card)

# 	else:
# 		print("No more cards to play")
