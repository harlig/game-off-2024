class_name Deck extends Control

const INITIAL_DECK_SIZE: int = 10

const hand_unit_texture_path := "res://textures/units/hand_crawler.png"
const cricket_unit_texture_path := "res://textures/units/cricket.png"

var cards: Array[Card] = []


var is_visualizing_deck: bool = false


func _ready() -> void:
	var num_units := INITIAL_DECK_SIZE - 2
	for ndx in range(num_units):
		if (ndx < 3):
			var basic_unit_card := UnitList.new_card_by_name("Gloom") # Give them an airial card for testing
			add_card(basic_unit_card)
		elif (ndx >= 3 && ndx < 8):
			var medium_unit_card := UnitList.new_card_by_id(0) # Shriekling
			add_card(medium_unit_card)
		else:
			var rare_unit_card := UnitList.new_card_by_name("Ebon Phantom") # Ebon Phantom
			add_card(rare_unit_card)

	for ndx in range(0, SpellList.spell_cards.size()):
		var spell_card := SpellList.new_card_by_id(ndx % SpellList.spell_cards.size())
		add_card(spell_card)


func add_card(card: Card) -> void:
	var duped_card: Card = Card.duplicate_card(card)
	cards.append(duped_card)


func toggle_visualize_deck() -> bool:
	is_visualizing_deck = !is_visualizing_deck
	if is_visualizing_deck:
		for card in cards:
			add_child(card)
	else:
		for card in cards:
			card.reset_selected()
			remove_child(card)
	return is_visualizing_deck
