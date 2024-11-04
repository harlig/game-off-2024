class_name Hand extends Control

@onready var cards_area: HBoxContainer = $CardsArea
@onready var mana_area: Control = $ManaArea
const HAND_SIZE := 5
const MAX_MANA := 10

signal card_played

var last_clicked_card: Node = null
var cards_in_hand: Array[Card] = []
var combat_deck: CombatDeck

func setup_deck(deck: CombatDeck) -> void:
	combat_deck = deck
	refresh_hand()

func refresh_hand() -> void:
	_discard_hand()
	_deal_full_hand()

func _deal_full_hand() -> void:
	for ndx in range(HAND_SIZE):
		_deal_card(combat_deck.draw())

func _deal_card(card: Card) -> void:
	if card == null:
		print("No card to deal")
		return

	card.card_clicked.connect(_on_card_clicked)
	cards_area.add_child(card)
	cards_in_hand.append(card)

func _discard_hand() -> void:
	last_clicked_card = null
	for card in cards_in_hand:
		discard(card)
	cards_in_hand.clear()

func _on_card_clicked(times_clicked: int, card_instance: Card) -> void:
	if last_clicked_card and last_clicked_card != card_instance:
		last_clicked_card.reset_selected()

	last_clicked_card = card_instance

	if times_clicked == 2:
		card_played.emit(card_instance)
		last_clicked_card = null
		discard(card_instance)
		cards_in_hand.erase(card_instance)

func discard(card: Card) -> void:
	card.disconnect("card_clicked", _on_card_clicked)
	combat_deck.discard(card)
	cards_area.remove_child(card)

func play_best_card() -> void:
	var best_card: Card = null
	var best_card_value: float = -1
	for card in cards_in_hand:
		var card_value: float = card.data.get_card_score()
		if card_value > best_card_value:
			best_card = card
			best_card_value = card_value
	if best_card:
		_on_card_clicked(2, best_card)
	else:
		print("No more cards to play")
