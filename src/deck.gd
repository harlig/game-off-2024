class_name Deck extends Control

const INITIAL_BASE_UNITS_COUNT: int = 6
const INITIAL_TORCHLIGHTER_COUNT: int = 2
const INITIAL_HEALER_COUNT: int = 1
const MAX_INITIAL_SCORE: int = 200
const MAX_INITIAL_PER_UNIT_SCORE: int = 20
const MAX_MANA_COST: int = 8

var cards: Array[Card] = []

var is_visualizing_deck: bool = false
var cards_displayed: Array[Card] = []

static func create_deck() -> Deck:
	var deck_scene := load("res://src/deck.tscn")
	var deck_instance: Deck = deck_scene.instantiate()
	return deck_instance


func _ready() -> void:
	var total_score := 0
	var num_units := INITIAL_BASE_UNITS_COUNT
	var mana_costs := [1, 2, 3]
	while total_score < MAX_INITIAL_SCORE and num_units > 0:
		var card := UnitList.get_random_card(MAX_INITIAL_PER_UNIT_SCORE, MAX_MANA_COST)
		if total_score + card.get_score() <= MAX_INITIAL_SCORE and card.mana <= MAX_MANA_COST:
			if card.mana in mana_costs:
				mana_costs.erase(card.mana)
			add_card(card)
			total_score += card.get_score()
			num_units -= 1

	while mana_costs.size() > 0:
		var card := UnitList.get_random_card(MAX_INITIAL_PER_UNIT_SCORE, MAX_MANA_COST)
		if card.mana in mana_costs:
			add_card(card)
			mana_costs.erase(card.mana)

	# TODO: sort the cards by mana cost

	for ndx in range(INITIAL_HEALER_COUNT):
		add_card(UnitList.new_card_by_name("Healer"))
	for ndx in range(INITIAL_TORCHLIGHTER_COUNT):
		add_card(UnitList.new_card_by_name("Torchlighter"))

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
