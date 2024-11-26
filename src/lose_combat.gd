class_name LoseCombat extends Control

const secret_scene := preload("res://src/lose_combat.tscn")

const NUM_CARDS_TO_DRAW := 3

# we use a combat deck here bc we need to draw cards
var deck: CombatDeck

var cards: Array[Card] = []

signal card_removed(card: Card)
signal game_lost()

static func create_lose_combat(init_deck: CombatDeck) -> LoseCombat:
	var lose_combat_instance: LoseCombat = secret_scene.instantiate()
	lose_combat_instance.deck = init_deck
	return lose_combat_instance

func _on_button_pressed() -> void:
	$Label.hide()
	$Button.hide()
	$Title.text = "Remove a card"

	var cards_drawn: Array[Card] = []
	for ndx in range(NUM_CARDS_TO_DRAW):
		var card := await draw_and_tween_card(ndx)
		if card == null:
			break
		cards_drawn.append(card)

	if cards_drawn.size() == 0:
		$Title.text = "Game over"
		$Label.text = "You have no more cards for me to take. Better luck in the next run!"
		$Label.show()
		game_lost.emit()
		return

	# do this after so you can't select until all cards are drawn
	for card in cards_drawn:
		card.card_clicked.connect(_on_card_clicked)
		card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
		card.mouse_exited.connect(_on_card_mouse_exited.bind(card))

func _on_card_mouse_entered(card: Card) -> void:
	card.highlight(Color.DARK_GREEN)

func _on_card_mouse_exited(card: Card) -> void:
	card.unhighlight()


func _on_card_clicked(_times_clicked: int, combat_deck_card: Card) -> void:
	# TODO: make the card blow up or something
	card_removed.emit(deck.combat_deck_card_to_original_card[combat_deck_card])

func draw_and_tween_card(ndx: int) -> Card:
	# TODO: could be sick if we pick like one of the best 4 to draw
	var card := deck.draw_best()
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
