class_name LoseCombat extends Control

const secret_scene := preload("res://src/lose_combat.tscn")

const NUM_CARDS_TO_DRAW := 3

# we use a combat deck here bc we need to draw cards
var deck: CombatDeck

var cards: Array[Card] = []

signal card_removed(card: Card)

static func create_lose_combat(init_deck: CombatDeck) -> LoseCombat:
	var lose_combat_instance: LoseCombat = secret_scene.instantiate()
	lose_combat_instance.deck = init_deck
	return lose_combat_instance

func _on_button_pressed() -> void:
	$Label.hide()
	$Title.text = "Select a card to remove"

	var cards_drawn: Array[Card] = []
	for ndx in range(NUM_CARDS_TO_DRAW):
		var card := await draw_and_tween_card(ndx)
		if card == null:
			break
		cards_drawn.append(card)
		# TODO: wire up card to card click and hover
		card.card_clicked.connect(_on_card_clicked)


func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	print("Clicked a card observed from lost combat")
	card_removed.emit(card)

func draw_and_tween_card(ndx: int) -> Card:
	# TODO: this should draw your BEST card at the time
	var card := deck.draw(false)
	cards.append(card)
	if card != null:
		card.position = $DrawCardLocation.global_position
		add_child(card)

		# 0th card gets 0th slot in card area, 1st gets 2nd, 2nd gets 4th
		var desired_blank_card_slot_ndx := 2 * ndx
		var blank_card_slot: Control = $BlankCardArea.get_child(desired_blank_card_slot_ndx)
		var blank_card_position := blank_card_slot.global_position
		var tween := get_tree().create_tween()
		tween.tween_property(card, "position", blank_card_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	return card
