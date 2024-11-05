class_name Reward extends Control

@onready var text: Label = $Text

signal reward_chosen(card: Card)

func add_card_offerings(cards: Array[Card]) -> void:
	for enemy_card: Card in cards:
		var card_offered := enemy_card.duplicate()
		card_offered.data = enemy_card.data
		card_offered.connect("card_clicked", _on_reward_clicked)
		$Offers.add_child(card_offered)

var last_clicked_reward_card: Card = null

func _on_reward_clicked(times_clicked: int, reward_card: Card) -> void:
	# print("Reward clicked " + str(times_clicked) + " times; " + reward_card.data.name)
	if last_clicked_reward_card and last_clicked_reward_card != reward_card:
		last_clicked_reward_card.reset_selected()

	last_clicked_reward_card = reward_card

	if times_clicked == 2:
		reward_card.reset_selected()
		reward_chosen.emit(reward_card)
