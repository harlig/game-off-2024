class_name CombatDeck extends Node

var discard_pile: Array[Card] = []
var draw_pile: Array[Card] = []

func _ready() -> void:
	print("Combat deck is ready!")
	# kinda gross but we need to get the deck from the Run, not from the parent Combat
	draw_pile = (get_parent().get_parent().get_node("Deck") as Deck).cards
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
