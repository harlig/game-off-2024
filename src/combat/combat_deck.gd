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

func draw(play_audio: bool = true) -> Card:
	if draw_pile.size() == 0:
		shuffle_discard_into_draw(play_audio)

	if audio != null and draw_pile.size() > 0 and play_audio:
		audio.play_card_draw()

	return draw_pile.pop_back()

func draw_best() -> Card:
	var best_card: Card = null
	for card in draw_pile:
		if card.type == Card.CardType.UNIT and card.creature.can_change_torches:
			continue
		if best_card == null or card.get_score() > best_card.get_score():
			best_card = card
	draw_pile.erase(best_card)
	if audio != null and best_card != null:
		audio.play_card_draw()
	return best_card

func try_draw_torchlighter(play_audio: bool = true) -> Card:
	for card in draw_pile:
		if card.type == Card.CardType.UNIT and card.creature.can_change_torches:
			draw_pile.erase(card)
			if audio != null and play_audio:
				audio.play_card_draw()
			return card
	return null

func shuffle_discard_into_draw(play_audio: bool = true) -> void:
	if discard_pile.size() == 0:
		return

	draw_pile = discard_pile
	discard_pile = []
	draw_pile.shuffle()
	if audio != null and play_audio:
		audio.play_shuffle()

func discard(card: Card) -> void:
	discard_pile.append(card)
	card.unhighlight()

func get_best_cards(num_cards: int) -> Array[Card]:
	var best_cards: Array[Card] = []
	var seen_creatures: Dictionary[String, bool] = {}
	var seen_spells: Dictionary[String, bool] = {}

	for card in all_cards:
		if best_cards.size() < num_cards:
			if card.type == Card.CardType.UNIT and not seen_creatures.has(card.creature.name):
				best_cards.append(card)
				seen_creatures[card.creature.name] = true
			elif card.type == Card.CardType.SPELL and not seen_spells.has(card.spell.name):
				best_cards.append(card)
				seen_spells[card.spell.name] = true
			continue

		var worst_best_card: Card = null
		var worst_best_card_ndx := -1
		for ndx in range(best_cards.size()):
			if worst_best_card == null or worst_best_card.get_score() > best_cards[ndx].get_score():
				worst_best_card = best_cards[ndx]
				worst_best_card_ndx = ndx

		if card.get_score() > worst_best_card.get_score():
			if card.type == Card.CardType.UNIT and not seen_creatures.has(card.creature.name):
				seen_creatures.erase(best_cards[worst_best_card_ndx].creature.name)
				best_cards[worst_best_card_ndx] = card
				seen_creatures[card.creature.name] = true
			elif card.type == Card.CardType.SPELL and not seen_spells.has(card.spell.name):
				seen_spells.erase(best_cards[worst_best_card_ndx].spell.name)
				best_cards[worst_best_card_ndx] = card
				seen_spells[card.spell.name] = true

	return best_cards

func original_cards_in_discard_pile() -> Array[Card]:
	var original_cards: Array[Card] = []
	for card in discard_pile:
		original_cards.append(combat_deck_card_to_original_card[card])
	return original_cards
