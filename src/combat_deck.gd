# This represents the deck of cards that the player draws from/discards to during combat
# This exists as a separate node so that the deck can be passed to the Hand nodes, and in case there are any temporary changes to the deck during combat that don't persist between combats
class_name CombatDeck extends Node

var all_cards: Array[Card] = []
var discard_pile: Array[Card] = []
var draw_pile: Array[Card] = []

func prepare_combat_deck(cards: Array[Card]) -> void:
	for card: Card in cards:
		var new_card := card.duplicate()
		# well idk why duplicating the card doesn't duplicate the data, but it doesn't work without this
		new_card.data = card.data
		all_cards.append(new_card)
		draw_pile.append(new_card)
	draw_pile.shuffle()

func draw() -> Card:
	if draw_pile.size() == 0:
		shuffle_discard_into_draw()
	return draw_pile.pop_back()

func shuffle_discard_into_draw() -> void:
	draw_pile = discard_pile
	discard_pile = []
	draw_pile.shuffle()

func discard(card: Card) -> void:
	discard_pile.append(card)

func get_best_cards(num_cards: int) -> Array[Card]:
	var best_cards: Array[Card] = []
	for card in all_cards:
		if best_cards.size() < num_cards:
			best_cards.append(card)
			continue

		# TODO: maybe this should be an array so we can get different worst cards if they have the same score
		var worst_best_card: Card = null
		var worst_best_card_ndx := -1
		for ndx in range(best_cards.size()):
			if worst_best_card == null or worst_best_card.data.get_card_score() > best_cards[ndx].data.get_card_score():
				worst_best_card = best_cards[ndx]
				worst_best_card_ndx = ndx

		if card.data.get_card_score() > worst_best_card.data.get_card_score():
			best_cards[worst_best_card_ndx] = card

	return best_cards
