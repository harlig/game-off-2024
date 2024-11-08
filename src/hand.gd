class_name Hand extends Control

const HAND_SIZE := 5

@export var display_hand := false;

var last_clicked_card: Node = null
var cards_in_hand: Array[Card] = []
var combat_deck: CombatDeck
var max_mana := 8
var cur_mana := 8

signal card_played

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
		card.card_clicked.connect(_on_card_clicked)
		$CardsArea.add_child(card)
		_sort_hand()

func _sort_hand() -> void:
	# TODO: do we also need to sort the order of nodes in the CardsArea? I think yes
	cards_in_hand.sort_custom(_compare_cards)

func _compare_cards(a: Card, b: Card) -> int:
	if a.creature.mana != b.creature.mana:
		return b.creature.mana < a.creature.mana
	return b.creature.get_score() < a.creature.get_score()

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
		# check if we have enough mana
		if cur_mana < card_instance.creature.mana:
			# TODO: something more disruptive
			print("Not enough mana")
			return

		play_card(last_clicked_card)


func play_card(card: Card) -> void:
	use_mana(card.creature.mana)
	card_played.emit(card)
	discard(card)
	cards_in_hand.erase(card)
	last_clicked_card = null

func discard(card: Card) -> void:
	if display_hand:
		card.disconnect("card_clicked", _on_card_clicked)
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
	if best_card:
		print(best_card.creature.name)
		_on_card_clicked(2, best_card)
	else:
		print("No more cards to play")
