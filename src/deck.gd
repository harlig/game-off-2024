class_name Deck extends Control

const INITIAL_DECK_SIZE: int = 10

@onready var card_scene := preload("res://src/card.tscn")
const hand_unit_texture_path := "res://textures/units/hand_crawler.png"
const cricket_unit_texture_path := "res://textures/units/cricket.png"

var cards: Array[Card] = []


var is_visualizing_deck: bool = false


func _ready() -> void:
	var num_basic_cards := INITIAL_DECK_SIZE
	for ndx in range(num_basic_cards):
		if (ndx < 3):
		#	var basic_card := UnitList.new_card_by_id(9) #spindler
			var basic_card := UnitList.new_card_by_name("Gloom") # Give them an airial card for testing

			add_card(basic_card)
		elif (ndx >= 3 && ndx < 8):
			var medium_card := UnitList.new_card_by_id(0) # Shriekling
			add_card(medium_card)
		else:
			var rare_card := UnitList.new_card_by_name("Ebon Phantom") # Ebon Phantom
			add_card(rare_card)


func add_card(card: Card) -> void:
	var duped_card: Card = card.duplicate()
	duped_card.creature = card.creature
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
