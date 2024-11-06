class_name UnitList extends Node

static var card_scene := preload("res://src/card.tscn")

static var creature_cards: Array[Dictionary] = [
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

enum card_type {RANGED, MELEE, AIR}

static var available_cards := creature_cards.size()

static func new_card_from_dict(data: Dictionary) -> Card:
	var newCard := create_card(
			data["health"], # max_health
			data["health"], # health
			data["mana"], # mana
			data["damage"], # damage
			data["name"], # card_name
			data["card_image_path"]
	)
	return newCard

static func create_card(
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

static func new_card_by_id(id: int) -> Card:
	return new_card_from_dict(creature_cards[id])

static func new_card_by_name(unit_name: String) -> Card:
	var unit_arr := creature_cards.filter(func(card: Dictionary) -> bool: return card["name"] == unit_name)
	return new_card_from_dict(unit_arr[0])


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
