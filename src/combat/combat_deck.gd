# This represents the deck of cards that the player draws from/discards to during combat
# This exists as a separate node so that the deck can be passed to the Hand nodes, and in case there are any temporary changes to the deck during combat that don't persist between combats
class_name CombatDeck extends Node

const combat_deck_scene := preload("res://src/combat/combat_deck.tscn")

var all_cards: Array[Card] = []
var discard_pile: Array[Card] = []
var draw_pile: Array[Card] = []

var audio: Audio = null

var combat_deck_card_to_original_card: Dictionary[Card, Card] = {}

static func create_combat_deck(cards: Array[Card], init_audio: Audio = null, relics: Array[Relic]=[]) -> CombatDeck:
	var combat_deck: CombatDeck = combat_deck_scene.instantiate()
	if init_audio != null:
		combat_deck.audio = init_audio

	for card: Card in cards:
		var new_card := Card.duplicate_card(card)
		for relic in relics:
			relic.apply_to_card(new_card)

		combat_deck.all_cards.append(new_card)
		combat_deck.draw_pile.append(new_card)

		combat_deck.combat_deck_card_to_original_card[new_card] = card
	combat_deck.draw_pile.shuffle()
	return combat_deck

func draw(should_shuffle_if_empty: bool = true) -> Card:
	if draw_pile.size() == 0 and should_shuffle_if_empty:
		shuffle_discard_into_draw()

	if audio != null and draw_pile.size() > 0:
		audio.play_card_draw()

	return draw_pile.pop_back()

func draw_best(should_shuffle_if_empty: bool = true) -> Card:
	if draw_pile.size() == 0 and should_shuffle_if_empty:
		shuffle_discard_into_draw()

	var best_card: Card = null
	for card in draw_pile:
		if best_card == null or card.get_score() > best_card.get_score():
			best_card = card
	draw_pile.erase(best_card)
	if audio != null and best_card != null:
		audio.play_card_draw()
	return best_card

func try_draw_torchlighter() -> Card:
	for card in draw_pile:
		if card.type == Card.CardType.UNIT and card.creature.can_change_torches:
			draw_pile.erase(card)
			return card
	return null

func shuffle_discard_into_draw() -> void:
	if discard_pile.size() == 0:
		return

	draw_pile = discard_pile
	discard_pile = []
	draw_pile.shuffle()
	if audio != null:
		audio.play_shuffle()

func discard(card: Card) -> void:
	discard_pile.append(card)
	card.unhighlight()

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
			if worst_best_card == null or worst_best_card.get_score() > best_cards[ndx].get_score():
				worst_best_card = best_cards[ndx]
				worst_best_card_ndx = ndx

		if card.get_score() > worst_best_card.get_score():
			best_cards[worst_best_card_ndx] = card

	return best_cards
