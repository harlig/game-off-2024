class_name Deck extends Control

const INITIAL_DECK_SIZE: int = 4

const hand_unit_texture_path := "res://textures/units/hand_crawler.png"
const cricket_unit_texture_path := "res://textures/units/cricket.png"

var cards: Array[Card] = []


var is_visualizing_deck: bool = false


func _ready() -> void:
	var num_units := INITIAL_DECK_SIZE
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

	add_card(UnitList.new_card_by_name("Damage Buffer")) # Add a buff card
	add_card(UnitList.new_card_by_name("Health Buffer")) # Add a buff card
	add_card(UnitList.new_card_by_name("Speed Buffer")) # Add a buff card

	add_card(UnitList.new_card_by_name("Torchlighter")) # Add a torchlighter card
	add_card(UnitList.new_card_by_name("Torchlighter")) # Add a torchlighter card
	add_card(UnitList.new_card_by_name("Torchlighter")) # Add a torchlighter card
	add_card(UnitList.new_card_by_name("Torchlighter")) # Add a torchlighter card

	add_card(UnitList.new_card_by_name("Healer")) # Add a healer card
	add_card(UnitList.new_card_by_name("Healer")) # Add a healer card
	add_card(UnitList.new_card_by_name("Healer")) # Add a healer card

	for ndx in range(0, SpellList.spell_cards.size()):
		var spell_card := SpellList.new_card_by_id(ndx % SpellList.spell_cards.size())
		add_card(spell_card)


func add_card(card: Card) -> void:
	var duped_card: Card = Card.duplicate_card(card)
	cards.append(duped_card)


var cards_displayed: Array[Card] = []
func toggle_visualize_deck(card_types_to_display: Array[Card.CardType]=[]) -> bool:
	is_visualizing_deck = !is_visualizing_deck
	print("Toggling visualizing deck with types to display ", card_types_to_display)
	if is_visualizing_deck:
		for card in cards:
			# yikes this is garbage but whatever, would love to set the default to all enum values but too hard rn
			if card_types_to_display.size() == 0 or card.type in card_types_to_display:
				cards_displayed.append(card)
				add_child(card)

	else:
		for card in cards_displayed:
			card.reset_selected()
			remove_child(card)
		cards_displayed.clear()
	return is_visualizing_deck
