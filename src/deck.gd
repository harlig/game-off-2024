class_name Deck extends Control

const INITIAL_BASE_UNITS_COUNT: int = 6
const INITIAL_TORCHLIGHTER_COUNT: int = 2
const INITIAL_HEALER_COUNT: int = 2

const hand_unit_texture_path := "res://textures/unit/hand_crawler.png"
const cricket_unit_texture_path := "res://textures/unit/cricket.png"

var cards: Array[Card] = []

var is_visualizing_deck: bool = false
var cards_displayed: Array[Card] = []

static func create_deck() -> Deck:
	var deck_scene := load("res://src/deck.tscn")
	var deck_instance: Deck = deck_scene.instantiate()
	return deck_instance


func _ready() -> void:
	var num_units := INITIAL_BASE_UNITS_COUNT
	for ndx in range(num_units):
		if (ndx < 2):
			var basic_unit_card := UnitList.new_card_by_name("Gloom") # Give them an airial card for testing
			add_card(basic_unit_card)
		elif (ndx >= 2 && ndx < 5):
			var medium_unit_card := UnitList.new_card_by_id(ndx) # Shriekling
			add_card(medium_unit_card)
		else:
			var rare_unit_card := UnitList.new_card_by_name("Ebon Phantom") # Ebon Phantom
			add_card(rare_unit_card)

	add_card(UnitList.new_card_by_name("Damage Buffer")) # Add a buff card
	add_card(UnitList.new_card_by_name("Health Buffer")) # Add a buff card
	add_card(UnitList.new_card_by_name("Speed Buffer")) # Add a buff card

	for ndx in range(INITIAL_TORCHLIGHTER_COUNT):
		add_card(UnitList.new_card_by_name("Torchlighter")) # Add a torchlighter card
	for ndx in range(INITIAL_HEALER_COUNT):
		add_card(UnitList.new_card_by_name("Healer")) # Add a healer card

	for ndx in range(0, SpellList.spell_cards.size()):
		var spell_card := SpellList.new_card_by_id(ndx % SpellList.spell_cards.size())
		add_card(spell_card)


func add_card(card: Card) -> void:
	var duped_card: Card = Card.duplicate_card(card)
	cards.append(duped_card)

func remove_card(card: Card) -> void:
	cards.erase(card)
	if (is_visualizing_deck):
		$GridContainer.remove_child(card)
		cards_displayed.erase(card)

func toggle_visualize_deck(on_card_clicked_attachment: Callable, on_card_mouse_entered: Callable, on_card_mouse_exited: Callable) -> bool:
	is_visualizing_deck = !is_visualizing_deck
	print("Toggling visualizing deck")
	if is_visualizing_deck:
		for card in cards:
			card.card_clicked.connect(on_card_clicked_attachment)
			card.mouse_entered.connect(on_card_mouse_entered.bind(card))
			card.mouse_exited.connect(on_card_mouse_exited.bind(card))

			cards_displayed.append(card)
			$GridContainer.add_child(card)

	else:
		for card in cards_displayed:
			card.card_clicked.disconnect(on_card_clicked_attachment)
			card.mouse_entered.disconnect(on_card_mouse_entered)
			card.mouse_exited.disconnect(on_card_mouse_exited)
			card.reset_selected()
			$GridContainer.remove_child(card)
		cards_displayed.clear()
	return is_visualizing_deck
