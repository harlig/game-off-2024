class_name Deck extends Control

const INITIAL_DECK_SIZE: int = 10

@onready var card_scene := preload("res://src/card.tscn")
const hand_unit_texture_path := "res://textures/units/hand_crawler.png"
const cricket_unit_texture_path := "res://textures/units/cricket.png"
var cards: Array[Card] = []


var is_visualizing_deck: bool = false
var creature_cards: Array[Dictionary] = [
	{"name": "Shriekling", "type": "Air", "health": 1, "damage": 2, "mana": 2, "strength_factor": 4, "card_image_path": "res://textures/units/cricket.png"}, # 0
	{"name": "Murkmouth", "type": "Melee", "health": 3, "damage": 3, "mana": 3, "strength_factor": 6, "card_image_path": "res://textures/units/hand_crawler.png"}, # 1
	{"name": "Wraithvine", "type": "Ranged", "health": 2, "damage": 4, "mana": 3, "strength_factor": 7, "card_image_path": "res://logo.png"}, # 2
	{"name": "Gloom", "type": "Air", "health": 1, "damage": 2, "mana": 1, "strength_factor": 1, "card_image_path": "res://logo.png"}, # 3
	{"name": "Hollowstalkers", "type": "Melee", "health": 4, "damage": 3, "mana": 4, "strength_factor": 8, "card_image_path": "res://textures/units/cricket.png"}, # 4
	{"name": "Sablemoth", "type": "Air", "health": 2, "damage": 1, "mana": 1, "strength_factor": 2, "card_image_path": "res://logo.png"}, # 5
	{"name": "Creep", "type": "Melee", "health": 1, "damage": 1, "mana": 1, "strength_factor": 1, "card_image_path": "res://textures/units/cricket.png"}, # 6
	{"name": "Netherlimbs", "type": "Melee", "health": 5, "damage": 5, "mana": 5, "strength_factor": 9, "card_image_path": "res://logo.png"}, # 7
	{"name": "Phantom Husk", "type": "Ranged", "health": 2, "damage": 3, "mana": 2, "strength_factor": 6, "card_image_path": "res://textures/units/cricket.png"}, # 8
	{"name": "Spindler", "type": "Ranged", "health": 1, "damage": 2, "mana": 2, "strength_factor": 4, "card_image_path": "res://textures/units/hand_crawler.png"}, # 9
	{"name": "Nightclaw", "type": "Melee", "health": 3, "damage": 4, "mana": 4, "strength_factor": 7, "card_image_path": "res://textures/units/cricket.png"}, # 10
	{"name": "Rotling", "type": "Melee", "health": 2, "damage": 2, "mana": 2, "strength_factor": 5, "card_image_path": "res://logo.png"}, # 11
	{"name": "Dreadroot", "type": "Ranged", "health": 3, "damage": 3, "mana": 3, "strength_factor": 6, "card_image_path": "res://textures/units/cricket.png"}, # 12
	{"name": "Haunt", "type": "Air", "health": 1, "damage": 2, "mana": 2, "strength_factor": 4, "card_image_path": "res://logo.png"}, # 13
	{"name": "Cryptkin", "type": "Melee", "health": 1, "damage": 2, "mana": 1, "strength_factor": 1, "card_image_path": "res://textures/units/cricket.png"}, # 14
	{"name": "Soul Devourer", "type": "Melee", "health": 8, "damage": 9, "mana": 8, "strength_factor": 10, "card_image_path": "res://textures/units/hand_crawler.png"}, # 15
	{"name": "Void Tyrant", "type": "Air", "health": 6, "damage": 7, "mana": 7, "strength_factor": 9, "card_image_path": "res://logo.png"}, # 16
	{"name": "Shadow Colossus", "type": "Ranged", "health": 7, "damage": 6, "mana": 6, "strength_factor": 9, "card_image_path": "res://logo.png"}, # 17
	{"name": "Ebon Phantom", "type": "Air", "health": 5, "damage": 8, "mana": 8, "strength_factor": 9, "card_image_path": "res://textures/units/hand_crawler.png"}, # 18
	{"name": "Abyssal Fiend", "type": "Melee", "health": 10, "damage": 10, "mana": 10, "strength_factor": 10, "card_image_path": "res://textures/units/hand_crawler.png"} # 19
]

func new_card_from_dict(data: Dictionary) -> Card:
	var newCard := create_card(
			data["health"], # max_health
			data["health"], # health
			data["mana"], # mana
			data["damage"], # damage
			data["name"], # card_name
			data["card_image_path"]
	)
	return newCard


func _ready() -> void:
	var num_basic_cards := INITIAL_DECK_SIZE
	for ndx in range(num_basic_cards):
		if(ndx < 3):
			var basic_card := new_card_from_dict(creature_cards[9]) #spindler
			add_card(basic_card)
		elif (ndx >= 3 && ndx < 8):
			var medium_card := new_card_from_dict(creature_cards[0]) #Shriekling
			add_card(medium_card)
		else:
			var rare_card := new_card_from_dict(creature_cards[18]) #Ebon Phantom
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
