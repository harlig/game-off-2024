class_name Event extends Control


enum EventType {GET_GOLD, BUFF_CARD}

var type: EventType
var deck: Deck

signal event_resolved(gold: int)

func _on_get_gold_button_pressed() -> void:
	emit_signal("event_resolved", 10)

func _ready() -> void:
	$GetGold.hide()
	$BuffCard.hide()

	match type:
		EventType.GET_GOLD:
			$Label.text = "Random event time!"
			$GetGold.show()
		EventType.BUFF_CARD:
			show_buff_card()
		_:
			push_error("Unknown event type", type)


func show_buff_card() -> void:
	$Label.text = "Buff a card!"
	$BuffCard.show()
	$BuffCard/Label.hide()
	$BuffCard/Button.text = "Open deck"
	$BuffCard/Button.connect("pressed", _on_buff_card_button_pressed)

func _on_buff_card_button_pressed() -> void:
	deck.toggle_visualize_deck([Card.CardType.UNIT])
	$BuffCard/Button.hide()

	for card in deck.cards:
		card.connect("card_clicked", _on_card_clicked)

func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	print("Buffing card ", card)
	if card.type != Card.CardType.UNIT:
		push_warning("Can only buff unit cards")
	else:
		card.creature.health += 10
		card.update_display()

	for deck_card in deck.cards:
		deck_card.disconnect("card_clicked", _on_card_clicked)
	deck.toggle_visualize_deck()

	emit_signal("event_resolved", 0)
