class_name Event extends Control


enum EventType {GET_GOLD, BUFF_CARD}

enum BuffType {
	DAMAGE,
	HEALTH,
	MANA,
	MAKE_TORCHLIGHTER
}

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
			offer_buff_card()
		_:
			push_error("Unknown event type", type)


func offer_buff_card() -> void:
	var buff_type: BuffType = BuffType.values()[randi() % BuffType.size()]
	var value := 10
	match buff_type:
		BuffType.DAMAGE:
			$Label.text = "Increase a creature card's damage dealt by " + str(value)
		BuffType.HEALTH:
			$Label.text = "Increase a creature card's health by " + str(value)
		BuffType.MANA:
			value = 1
			$Label.text = "Decrease a creature card's mana cost by " + str(value)
		BuffType.MAKE_TORCHLIGHTER:
			$Label.text = "Choose a unit to now be able to light torches"
		_:
			push_error("Unknown buff type", buff_type)
	$BuffCard.show()
	$BuffCard/Label.hide()
	$BuffCard/Button.text = "Open deck"
	$BuffCard/Button.connect("pressed", _on_buff_card_button_pressed.bind(buff_type, value))

func _on_buff_card_button_pressed(buff_type: BuffType, value: int) -> void:
	# deck.toggle_visualize_deck([Card.CardType.UNIT])
	$BuffCard/Button.hide()

	for card in deck.cards:
		# TODO: if a card has 0 mana, we shouldn't be able to buff it for a mana buff type
		card.connect("card_clicked", _on_card_clicked.bind(buff_type, value))

func _on_card_clicked(_times_clicked: int, card: Card, buff_type: BuffType, value: int) -> void:
	print("Buffing card ", card, " with buff type ", buff_type, " and value ", value)
	if card.type == Card.CardType.UNIT:
		match buff_type:
			BuffType.DAMAGE:
				card.creature.damage += value
			BuffType.HEALTH:
				card.creature.health += value
			BuffType.MANA:
				card.mana -= value
			BuffType.MAKE_TORCHLIGHTER:
				card.creature.can_change_torches = true

		card.update_display()
	else:
		push_warning("Can only buff unit cards")

	for deck_card in deck.cards:
		deck_card.disconnect("card_clicked", _on_card_clicked)
	# deck.toggle_visualize_deck()

	emit_signal("event_resolved", 0)
