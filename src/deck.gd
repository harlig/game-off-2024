class_name Deck extends Control

const INITIAL_DECK_SIZE: int = 10

@onready var card_scene := preload("res://src/card.tscn")
const hand_unit_texture_path := "res://textures/units/hand_crawler.png"
const cricket_unit_texture_path := "res://textures/units/cricket.png"
@onready var unit_list := preload("res://src//unit_list.gd")

var cards: Array[Card] = []


var is_visualizing_deck: bool = false


func _ready() -> void:
	var num_basic_cards := INITIAL_DECK_SIZE
	for ndx in range(num_basic_cards):
		if(ndx < 3):
			var basic_card := unit_list.new_card_by_id(9) #spindler
			add_card(basic_card)
		elif (ndx >= 3 && ndx < 8):
			var medium_card := unit_list.new_card_by_id(0) #Shriekling
			add_card(medium_card)
		else:
			var rare_card := unit_list.new_card_by_name("Ebon Phantom") #Ebon Phantom
			add_card(rare_card)



func add_card(card: Card) -> void:
	var duped_card: Card = card.duplicate()
	duped_card.data = card.data
	cards.append(duped_card)

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
