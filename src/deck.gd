class_name Deck extends Control

const INITIAL_DECK_SIZE: int = 10

@onready var card_scene := preload("res://src/card.tscn")
var cards: Array[Card] = []

var is_visualizing_deck: bool = false

func _ready() -> void:
	var num_basic_cards := INITIAL_DECK_SIZE - 2
	for ndx in range(num_basic_cards):
		# add basic cards to deck
		var basic_card := create_card(
			5, # max_health
			5, # health
			2, # mana
			3, # damage
			"Creature " + str(ndx + 1), # card_name
			"res://logo.png" # card_image_path
		)
		add_card(basic_card)
	for ndx in range(INITIAL_DECK_SIZE - num_basic_cards):
		var rare_card := create_card(
				20, # max_health
				20, # health
				8, # mana
				25, # damage
				"Demogorgon", # card_name
				"res://logo.png" # card_image_path
			)
		add_card(rare_card)

func add_card(card: Card) -> void:
	cards.append(card)

func create_card(
	new_max_health: int,
	new_health: int,
	new_mana: int,
	new_damage: int,
	new_card_name: String,
	new_card_image_path: String
) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_stats(
		new_max_health,
		new_health,
		new_mana,
		new_damage,
		new_card_name,
		new_card_image_path
	)
	return card_instance

func toggle_visualize_deck() -> void:
	is_visualizing_deck = !is_visualizing_deck
	if is_visualizing_deck:
		for card in cards:
			add_child(card)
	else:
		for card in cards:
			remove_child(card)
