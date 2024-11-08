class_name Hand extends Control

const HAND_SIZE := 5

@export var display_hand := false;

var cards_in_hand: Array[Card] = []
var combat_deck: CombatDeck
var max_mana := 8
var cur_mana := 8

func replenish_mana() -> void:
	cur_mana = max_mana

	if display_hand:
		$HBoxContainer/TextureRect2/Label2.text = str(cur_mana) + "/" + str(max_mana);

func use_mana(amount: int) -> void:
	cur_mana -= amount

	if display_hand:
		$HBoxContainer/TextureRect2/Label2.text = str(cur_mana) + "/" + str(max_mana);

func setup_deck(deck: CombatDeck) -> void:
	combat_deck = deck
	refresh_hand()

func refresh_hand() -> void:
	_discard_hand()
	_deal_full_hand()
	replenish_mana()

func _deal_full_hand() -> void:
	for ndx in range(HAND_SIZE):
		_deal_card(combat_deck.draw())

func _deal_card(card: Card) -> void:
	if card == null:
		print("No card to deal")
		return

	cards_in_hand.append(card)

	if display_hand:
		card.card_clicked.connect(get_parent()._on_card_clicked)
		$CardsArea.add_child(card)
		_sort_hand()

func _sort_hand() -> void:
	# Sort the cards in hand
	cards_in_hand.sort_custom(_compare_cards)

	# Sort the order of nodes in the CardsArea
	for card in cards_in_hand:
		var index := cards_in_hand.find(card)
		$CardsArea.move_child(card, index)

func _compare_cards(a: Card, b: Card) -> int:
	if a.creature.mana != b.creature.mana:
		return a.creature.mana < b.creature.mana
	return a.creature.get_score() < b.creature.get_score()

func _discard_hand() -> void:
	for card in cards_in_hand:
		discard(card)
	cards_in_hand.clear()

func play_card(card: Card) -> void:
	use_mana(card.creature.mana)
	discard(card)
	cards_in_hand.erase(card)

func discard(card: Card) -> void:
	combat_deck.discard(card)

	if display_hand:
		$CardsArea.remove_child(card)

func play_best_card() -> void:
	if cards_in_hand.size() == 0:
		refresh_hand()

	replenish_mana()
	var best_card: Card = null
	var best_card_value: float = -1
	for card in cards_in_hand:
		var card_value: float = card.creature.get_score()
		if card_value > best_card_value:
			best_card = card
			best_card_value = card_value
	if best_card and cur_mana >= best_card.creature.mana:
		print(best_card.creature.name)
		play_card(best_card)

	else:
		print("No more cards to play")
