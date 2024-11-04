# This represents the deck of cards that the player draws from/discards to during combat
# This exists as a separate node so that the deck can be passed to the Hand nodes, and in case there are any temporary changes to the deck during combat that don't persist between combats
class_name CombatDeck extends Node

var discard_pile: Array[Card] = []
var draw_pile: Array[Card] = []

func _ready() -> void:
	# kinda gross but we need to get the deck from the Run, not from the parent Combat
	# TODO: how do I do this for the enemy who has another deck? Maybe I need to pass the deck in?
	for card: Card in (get_parent().get_parent().get_node("DeckControl").get_node("Deck") as Deck).cards:
		var new_card := card.duplicate()
		# well idk why duplicating the card doesn't duplicate the data, but it doesn't work without this
		new_card.data = card.data
		draw_pile.append(new_card)
	draw_pile.shuffle()

func draw() -> Card:
	if draw_pile.size() == 0:
		shuffle_discard_into_draw()
	print("Drawing card from draw pile")
	return draw_pile.pop_back()

func shuffle_discard_into_draw() -> void:
	draw_pile = discard_pile
	discard_pile = []
	draw_pile.shuffle()

func discard(card: Card) -> void:
	discard_pile.append(card)
